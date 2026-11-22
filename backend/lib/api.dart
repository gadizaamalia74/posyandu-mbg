import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'db.dart';
import 'util.dart';

Router buildApi() {
  final r = Router();

  r.get('/api/health', (Request req) => jsonResponse({'ok': true}));

  // Cek koneksi database & akun admin: buka http://localhost:8080/api/health/db
  r.get('/api/health/db', (Request req) async {
    try {
      final u = await Db.one("SELECT nk, role, LEFT(password,7) AS hash_awal FROM users WHERE nk='ADMIN001'");
      return jsonResponse({'db': 'ok', 'admin001': u ?? 'TIDAK ADA (import schema.sql)'});
    } catch (e) {
      return jsonResponse({'db': 'GAGAL', 'detail': e.toString()}, 500);
    }
  });

  // =============== AUTH ===============
  // Login admin/kader (NK + password)
  r.post('/api/auth/login', (Request req) async {
    final b = await readBody(req);
    final nk = str(b, 'nk');
    final pass = (b['password'] ?? '').toString();
    if (nk.isEmpty || pass.isEmpty) return fail('NK dan password wajib diisi.');
    final u = await Db.one('SELECT * FROM users WHERE nk = :nk LIMIT 1', {'nk': nk});
    if (u == null || !verifyPassword(pass, u['password'] ?? '')) {
      return fail('NK atau password salah.', 401);
    }
    final token = newToken();
    sessions[token] = Session('staff', int.parse(u['id']!), u['role']!, u['nama']!);
    return jsonResponse({
      'token': token,
      'type': 'staff',
      'user': {'id': u['id'], 'nk': u['nk'], 'nama': u['nama'], 'email': u['email'], 'role': u['role']},
    });
  });

  // Login ibu balita (email + password)
  r.post('/api/auth/login-ibu', (Request req) async {
    final b = await readBody(req);
    final email = str(b, 'email');
    final pass = (b['password'] ?? '').toString();
    if (email.isEmpty || pass.isEmpty) return fail('Email dan password wajib diisi.');
    final u = await Db.one('SELECT * FROM ibu_balita WHERE email = :e LIMIT 1', {'e': email});
    if (u == null || !verifyPassword(pass, u['password'] ?? '')) {
      return fail('Email atau password salah.', 401);
    }
    final token = newToken();
    sessions[token] = Session('ibu', int.parse(u['id']!), 'ibu', u['nama']!);
    return jsonResponse({
      'token': token,
      'type': 'ibu',
      'user': {'id': u['id'], 'nama': u['nama'], 'email': u['email'], 'no_hp': u['no_hp'], 'role': 'ibu'},
    });
  });

  // Daftar akun ibu (wajib kode anak dari kader)
  r.post('/api/auth/register-ibu', (Request req) async {
    final b = await readBody(req);
    final nama = str(b, 'nama'), email = str(b, 'email'), hp = str(b, 'no_hp');
    final pass = (b['password'] ?? '').toString();
    final konf = (b['konfirmasi'] ?? '').toString();
    final kode = str(b, 'kode_anak');
    if (nama.isEmpty || email.isEmpty || pass.isEmpty || kode.isEmpty) {
      return fail('Semua field wajib diisi kecuali No HP.');
    }
    if (pass != konf) return fail('Konfirmasi password tidak cocok.');
    if (pass.length < 6) return fail('Password minimal 6 karakter.');
    if (await Db.one('SELECT id FROM ibu_balita WHERE email = :e', {'e': email}) != null) {
      return fail('Email sudah terdaftar.');
    }
    if (await Db.one('SELECT id FROM anak WHERE kode_anak = :k', {'k': kode}) == null) {
      return fail('Kode Anak tidak ditemukan. Pastikan kode yang diberikan kader sudah benar.');
    }
    final id = await Db.insert(
      'INSERT INTO ibu_balita (nama, email, no_hp, password) VALUES (:n,:e,:h,:p)',
      {'n': nama, 'e': email, 'h': hp, 'p': hashPassword(pass)},
    );
    await Db.exec('INSERT INTO ibu_anak (ibu_id, kode_anak) VALUES (:i,:k)', {'i': id, 'k': kode});
    return jsonResponse({'message': 'Akun berhasil dibuat! Silakan login.'}, 201);
  });

  r.post('/api/auth/logout', anyUser((req, s) async {
    final t = (req.headers['authorization'] ?? '').replaceFirst('Bearer ', '').trim();
    sessions.remove(t);
    return jsonResponse({'ok': true});
  }));

  // =============== PROFIL ===============
  r.get('/api/me', anyUser((req, s) async {
    if (s.type == 'ibu') {
      final u = await Db.one('SELECT id,nama,email,no_hp FROM ibu_balita WHERE id=:i', {'i': s.id});
      return jsonResponse({...?u, 'role': 'ibu'});
    }
    final u = await Db.one('SELECT id,nk,nama,email,role FROM users WHERE id=:i', {'i': s.id});
    return jsonResponse(u);
  }));

  r.put('/api/me', anyUser((req, s) async {
    final b = await readBody(req);
    final nama = str(b, 'nama');
    if (nama.isEmpty) return fail('Nama wajib diisi.');
    final pass = (b['password'] ?? '').toString();
    if (pass.isNotEmpty && pass.length < 6) return fail('Password minimal 6 karakter.');
    if (s.type == 'ibu') {
      await Db.exec('UPDATE ibu_balita SET nama=:n, no_hp=:h WHERE id=:i',
          {'n': nama, 'h': str(b, 'no_hp'), 'i': s.id});
      if (pass.isNotEmpty) {
        await Db.exec('UPDATE ibu_balita SET password=:p WHERE id=:i', {'p': hashPassword(pass), 'i': s.id});
      }
    } else {
      await Db.exec('UPDATE users SET nama=:n, email=:e WHERE id=:i',
          {'n': nama, 'e': str(b, 'email'), 'i': s.id});
      if (pass.isNotEmpty) {
        await Db.exec('UPDATE users SET password=:p WHERE id=:i', {'p': hashPassword(pass), 'i': s.id});
      }
    }
    return jsonResponse({'message': 'Profil diperbarui.'});
  }));

  // =============== JADWAL ===============
  r.get('/api/jadwal', anyUser((req, s) async {
    final rows = await Db.query('SELECT * FROM jadwal ORDER BY tanggal DESC');
    return jsonResponse(rows.map(_jadwal).toList());
  }));

  r.get('/api/jadwal/next', anyUser((req, s) async {
    final j = await Db.one(
        'SELECT * FROM jadwal WHERE tanggal >= CURDATE() ORDER BY tanggal ASC, jam_mulai ASC LIMIT 1');
    return jsonResponse(j == null ? null : _jadwal(j));
  }));

  r.post('/api/jadwal', admin((req, s) async {
    final b = await readBody(req);
    final tanggal = str(b, 'tanggal');
    final lokasi = str(b, 'lokasi'), kegiatan = str(b, 'kegiatan');
    final mulai = str(b, 'jam_mulai'), selesai = str(b, 'jam_selesai');
    if ([tanggal, lokasi, kegiatan, mulai, selesai].any((e) => e.isEmpty)) {
      return fail('Semua field jadwal wajib diisi.');
    }
    final d = DateTime.tryParse(tanggal);
    if (d == null) return fail('Format tanggal tidak valid (YYYY-MM-DD).');
    // Kode jadwal MMYYYY seperti PHP lama (kolom 10 karakter); bila bentrok tambah digit.
    var kode = '${d.month.toString().padLeft(2, '0')}${d.year}';
    if (await Db.one('SELECT id FROM jadwal WHERE kode_jadwal=:k', {'k': kode}) != null) {
      for (var i = 1; i <= 9; i++) {
        if (await Db.one('SELECT id FROM jadwal WHERE kode_jadwal=:k', {'k': '$kode$i'}) == null) {
          kode = '$kode$i';
          break;
        }
      }
    }
    await Db.exec(
      'INSERT INTO jadwal (kode_jadwal,tanggal,lokasi,kegiatan,jam_mulai,jam_selesai) VALUES (:k,:t,:l,:g,:m,:s)',
      {'k': kode, 't': tanggal, 'l': lokasi, 'g': kegiatan, 'm': mulai, 's': selesai},
    );
    return jsonResponse({'message': 'Jadwal berhasil ditambahkan!'}, 201);
  }));

  r.delete('/api/jadwal/<id>', admin((req, s) async {
    final id = toInt(req.params['id']);
    // Hapus konfirmasi kehadiran terkait terlebih dahulu (FK constraint)
    await Db.exec('DELETE FROM konfirmasi_kehadiran WHERE jadwal_id=:i', {'i': id});
    await Db.exec('DELETE FROM jadwal WHERE id=:i', {'i': id});
    return jsonResponse({'message': 'Jadwal berhasil dihapus.'});
  }));

  // Notifikasi: jadwal 30 hari ke depan (+ laporan belum dibaca untuk staff)
  r.get('/api/notifikasi', anyUser((req, s) async {
    final rows = await Db.query('''
      SELECT * FROM jadwal
      WHERE tanggal BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
      ORDER BY tanggal ASC''');
    var belum = 0;
    if (s.type == 'staff') {
      final c = await Db.one("SELECT COUNT(*) AS c FROM laporan_kondisi WHERE status_baca='belum'");
      belum = toInt(c?['c']);
    }
    return jsonResponse({'jadwal': rows.map(_jadwal).toList(), 'laporan_belum_dibaca': belum});
  }));

  // =============== ANAK ===============
  r.get('/api/anak', staff((req, s) async {
    final q = req.url.queryParameters['search'] ?? '';
    final rows = await Db.query('''
      SELECT * FROM anak WHERE nama_anak LIKE :q OR kode_anak LIKE :q ORDER BY nama_anak''',
        {'q': '%$q%'});
    return jsonResponse(rows.map(_anak).toList());
  }));

  // =============== PENIMBANGAN ===============
  r.get('/api/penimbangan', staff((req, s) async {
    final qp = req.url.queryParameters;
    final rows = await Db.query('''
      SELECT p.*, a.nama_anak, a.jenis_kelamin, a.nama_ibu, a.alamat
      FROM penimbangan p JOIN anak a ON p.kode_anak = a.kode_anak
      WHERE (:tgl = '' OR p.tanggal_kegiatan = :tgl)
        AND (a.nama_anak LIKE :q OR a.kode_anak LIKE :q)
      ORDER BY p.tanggal_kegiatan DESC, p.id DESC''',
        {'tgl': qp['tanggal'] ?? '', 'q': '%${qp['search'] ?? ''}%'});
    return jsonResponse(rows
        .map((x) => {
              'id': toInt(x['id']),
              'kode_anak': x['kode_anak'],
              'nama_anak': x['nama_anak'],
              'jenis_kelamin': x['jenis_kelamin'],
              'nama_ibu': x['nama_ibu'],
              'alamat': x['alamat'],
              'tanggal_kegiatan': dateOnly(x['tanggal_kegiatan']),
              'usia_bulan': toInt(x['usia_bulan']),
              'bb': toDouble(x['bb']),
              'tb': toDouble(x['tb']),
              'status_gizi': x['status_gizi'],
            })
        .toList());
  }));

  r.post('/api/penimbangan', staff((req, s) async {
    final b = await readBody(req);
    final kode = str(b, 'kode_anak'), nama = str(b, 'nama_anak');
    final tgl = str(b, 'tanggal_kegiatan');
    if (kode.isEmpty || nama.isEmpty || tgl.isEmpty) {
      return fail('Kode anak, nama anak, dan tanggal wajib diisi.');
    }
    final usia = toInt(b['usia_bulan']);
    final bb = toDouble(b['bb']), tb = toDouble(b['tb']);
    if (await Db.one('SELECT id FROM anak WHERE kode_anak=:k', {'k': kode}) == null) {
      final lahir = DateTime.now().subtract(Duration(days: (usia * 30.4375).round()));
      await Db.exec('''
        INSERT INTO anak (kode_anak,nama_anak,jenis_kelamin,tanggal_lahir,nama_ibu,alamat)
        VALUES (:k,:n,:jk,:tl,:ibu,:al)''', {
        'k': kode,
        'n': nama,
        'jk': str(b, 'jenis_kelamin', 'P'),
        'tl': dateOnly(lahir.toIso8601String()),
        'ibu': str(b, 'nama_ibu', '-'),
        'al': str(b, 'alamat', '-'),
      });
    }
    await Db.exec('''
      INSERT INTO penimbangan (kode_anak,tanggal_kegiatan,usia_bulan,bb,tb,status_gizi)
      VALUES (:k,:t,:u,:bb,:tb,:st)''',
        {'k': kode, 't': tgl, 'u': usia, 'bb': bb, 'tb': tb, 'st': statusGizi(bb)});
    return jsonResponse({'message': 'Data berhasil disimpan!'}, 201);
  }));

  r.put('/api/penimbangan/<id>', staff((req, s) async {
    final b = await readBody(req);
    final bb = toDouble(b['bb']);
    await Db.exec('''
      UPDATE penimbangan SET tanggal_kegiatan=:t, usia_bulan=:u, bb=:bb, tb=:tb, status_gizi=:st
      WHERE id=:i''', {
      't': str(b, 'tanggal_kegiatan'),
      'u': toInt(b['usia_bulan']),
      'bb': bb,
      'tb': toDouble(b['tb']),
      'st': statusGizi(bb),
      'i': toInt(req.params['id']),
    });
    await Db.exec('''
      UPDATE anak SET nama_anak=:n, jenis_kelamin=:jk, nama_ibu=:ibu, alamat=:al WHERE kode_anak=:k''', {
      'n': str(b, 'nama_anak'),
      'jk': str(b, 'jenis_kelamin', 'P'),
      'ibu': str(b, 'nama_ibu', '-'),
      'al': str(b, 'alamat', '-'),
      'k': str(b, 'kode_anak'),
    });
    return jsonResponse({'message': 'Data berhasil diubah!'});
  }));

  r.delete('/api/penimbangan/<id>', staff((req, s) async {
    await Db.exec('DELETE FROM penimbangan WHERE id=:i', {'i': toInt(req.params['id'])});
    return jsonResponse({'message': 'Data berhasil dihapus.'});
  }));

  // =============== VAKSIN ===============
  r.get('/api/vaksin', anyUser((req, s) async {
    final rows = await Db.query('SELECT id_vaksin, nama_vaksin FROM vaksin ORDER BY id_vaksin');
    return jsonResponse(rows);
  }));

  r.post('/api/vaksin', admin((req, s) async {
    final b = await readBody(req);
    final id = str(b, 'id_vaksin'), nama = str(b, 'nama_vaksin');
    if (id.isEmpty || nama.isEmpty) return fail('ID dan nama vaksin wajib diisi.');
    if (await Db.one('SELECT id FROM vaksin WHERE id_vaksin=:i', {'i': id}) != null) {
      return fail('ID vaksin sudah ada.');
    }
    await Db.exec('INSERT INTO vaksin (id_vaksin,nama_vaksin) VALUES (:i,:n)', {'i': id, 'n': nama});
    return jsonResponse({'message': 'Vaksin berhasil ditambahkan!'}, 201);
  }));

  r.put('/api/vaksin/<idLama>', admin((req, s) async {
    final b = await readBody(req);
    final id = str(b, 'id_vaksin'), nama = str(b, 'nama_vaksin');
    if (id.isEmpty || nama.isEmpty) return fail('ID dan nama vaksin wajib diisi.');
    await Db.exec('UPDATE vaksin SET id_vaksin=:i, nama_vaksin=:n WHERE id_vaksin=:l',
        {'i': id, 'n': nama, 'l': req.params['idLama']});
    return jsonResponse({'message': 'Vaksin berhasil diubah!'});
  }));

  r.delete('/api/vaksin/<id>', admin((req, s) async {
    await Db.exec('DELETE FROM vaksin WHERE id_vaksin=:i', {'i': req.params['id']});
    return jsonResponse({'message': 'Vaksin berhasil dihapus.'});
  }));

  // =============== IMUNISASI (staff) ===============
  r.get('/api/imunisasi', staff((req, s) async {
    final qp = req.url.queryParameters;
    final rows = await Db.query('''
      SELECT i.*, a.nama_anak, a.jenis_kelamin, v.nama_vaksin
      FROM imunisasi i
      JOIN anak a ON a.kode_anak = i.kode_anak
      JOIN vaksin v ON v.id_vaksin = i.id_vaksin
      WHERE (:v = '' OR i.id_vaksin = :v)
        AND (a.nama_anak LIKE :q OR a.kode_anak LIKE :q)
      ORDER BY i.tanggal_imunisasi DESC, i.id DESC''',
        {'v': qp['vaksin'] ?? '', 'q': '%${qp['search'] ?? ''}%'});
    return jsonResponse(rows
        .map((x) => {
              'id': toInt(x['id']),
              'kode_anak': x['kode_anak'],
              'nama_anak': x['nama_anak'],
              'jenis_kelamin': x['jenis_kelamin'],
              'id_vaksin': x['id_vaksin'],
              'nama_vaksin': x['nama_vaksin'],
              'tanggal_imunisasi': dateOnly(x['tanggal_imunisasi']),
              'usia_bulan': toInt(x['usia_bulan']),
              'keterangan': x['keterangan'],
            })
        .toList());
  }));

  r.post('/api/imunisasi', staff((req, s) async {
    final b = await readBody(req);
    final kode = str(b, 'kode_anak'), nama = str(b, 'nama_anak');
    final vid = str(b, 'id_vaksin'), tgl = str(b, 'tanggal_imunisasi');
    if (kode.isEmpty || vid.isEmpty || tgl.isEmpty) {
      return fail('Kode anak, vaksin, dan tanggal wajib diisi.');
    }
    final usia = toInt(b['usia_bulan']);
    if (await Db.one('SELECT id FROM anak WHERE kode_anak=:k', {'k': kode}) == null) {
      if (nama.isEmpty) return fail('Kode Anak dan Nama Anak wajib diisi untuk anak baru.');
      final lahir = DateTime.now().subtract(Duration(days: (usia * 30.4375).round()));
      await Db.exec('''
        INSERT INTO anak (kode_anak,nama_anak,jenis_kelamin,tanggal_lahir,nama_ibu,alamat)
        VALUES (:k,:n,'P',:tl,'-','-')''',
          {'k': kode, 'n': nama, 'tl': dateOnly(lahir.toIso8601String())});
    }
    if (await Db.one('SELECT id FROM imunisasi WHERE kode_anak=:k AND id_vaksin=:v', {'k': kode, 'v': vid}) !=
        null) {
      return fail('Data imunisasi anak ini sudah ada untuk vaksin tersebut.', 409);
    }
    await Db.exec('''
      INSERT INTO imunisasi (kode_anak,id_vaksin,tanggal_imunisasi,usia_bulan,keterangan)
      VALUES (:k,:v,:t,:u,:ket)''', {
      'k': kode,
      'v': vid,
      't': tgl,
      'u': usia,
      'ket': str(b, 'keterangan', 'Tepat Waktu'),
    });
    return jsonResponse({'message': 'Data berhasil disimpan!'}, 201);
  }));

  r.put('/api/imunisasi/<id>', staff((req, s) async {
    final b = await readBody(req);
    await Db.exec('''
      UPDATE imunisasi SET tanggal_imunisasi=:t, usia_bulan=:u, keterangan=:ket WHERE id=:i''', {
      't': str(b, 'tanggal_imunisasi'),
      'u': toInt(b['usia_bulan']),
      'ket': str(b, 'keterangan', 'Tepat Waktu'),
      'i': toInt(req.params['id']),
    });
    return jsonResponse({'message': 'Data berhasil diubah!'});
  }));

  r.delete('/api/imunisasi/<id>', staff((req, s) async {
    await Db.exec('DELETE FROM imunisasi WHERE id=:i', {'i': toInt(req.params['id'])});
    return jsonResponse({'message': 'Data berhasil dihapus.'});
  }));

  // =============== USER (admin) ===============
  r.get('/api/users', admin((req, s) async {
    final rows = await Db.query('SELECT id,nk,nama,email,role FROM users ORDER BY role, nama');
    return jsonResponse(rows);
  }));

  r.post('/api/users', admin((req, s) async {
    final b = await readBody(req);
    final nk = str(b, 'nk'), nama = str(b, 'nama');
    final pass = (b['password'] ?? '').toString();
    if (nk.isEmpty || nama.isEmpty || pass.isEmpty) return fail('NK, Nama, dan Password wajib diisi.');
    if (await Db.one('SELECT id FROM users WHERE nk=:n', {'n': nk}) != null) {
      return fail('NK sudah digunakan, pilih NK lain.');
    }
    final role = str(b, 'role', 'kader') == 'admin' ? 'admin' : 'kader';
    await Db.exec('INSERT INTO users (nk,nama,email,password,role) VALUES (:nk,:n,:e,:p,:r)',
        {'nk': nk, 'n': nama, 'e': str(b, 'email'), 'p': hashPassword(pass), 'r': role});
    return jsonResponse({'message': 'User berhasil ditambahkan!'}, 201);
  }));

  r.put('/api/users/<id>', admin((req, s) async {
    final b = await readBody(req);
    final id = toInt(req.params['id']);
    final nk = str(b, 'nk');
    if (await Db.one('SELECT id FROM users WHERE nk=:n AND id<>:i', {'n': nk, 'i': id}) != null) {
      return fail('NK sudah digunakan user lain.');
    }
    final role = str(b, 'role', 'kader') == 'admin' ? 'admin' : 'kader';
    await Db.exec('UPDATE users SET nk=:nk, nama=:n, email=:e, role=:r WHERE id=:i',
        {'nk': nk, 'n': str(b, 'nama'), 'e': str(b, 'email'), 'r': role, 'i': id});
    final pass = (b['password'] ?? '').toString();
    if (pass.isNotEmpty) {
      await Db.exec('UPDATE users SET password=:p WHERE id=:i', {'p': hashPassword(pass), 'i': id});
    }
    return jsonResponse({'message': 'User berhasil diubah!'});
  }));

  r.delete('/api/users/<id>', admin((req, s) async {
    final id = toInt(req.params['id']);
    if (id == s.id) return fail('Tidak bisa menghapus akun sendiri.');
    await Db.exec('DELETE FROM users WHERE id=:i', {'i': id});
    return jsonResponse({'message': 'User berhasil dihapus.'});
  }));

  // =============== STATISTIK ===============
  r.get('/api/statistik', staff((req, s) async {
    final rows = await Db.query('''
      SELECT DATE_FORMAT(tanggal_kegiatan,'%m-%Y') AS bulan_tahun,
             DATE_FORMAT(tanggal_kegiatan,'%Y-%m') AS sort_key,
             COUNT(DISTINCT kode_anak) AS jumlah
      FROM penimbangan
      WHERE tanggal_kegiatan >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
      GROUP BY bulan_tahun, sort_key ORDER BY sort_key ASC''');
    return jsonResponse(rows.map((x) => {'label': x['bulan_tahun'], 'jumlah': toInt(x['jumlah'])}).toList());
  }));

  // =============== KEHADIRAN & LAPORAN MASUK (staff) ===============
  r.get('/api/kehadiran', staff((req, s) async {
    final jid = toInt(req.url.queryParameters['jadwal']);
    final rows = await Db.query('''
      SELECT k.id, k.status, k.keterangan, a.kode_anak, a.nama_anak, i.nama AS nama_ibu, i.no_hp,
             j.tanggal, j.kegiatan
      FROM konfirmasi_kehadiran k
      JOIN anak a ON a.kode_anak = k.kode_anak
      JOIN ibu_balita i ON i.id = k.ibu_id
      JOIN jadwal j ON j.id = k.jadwal_id
      WHERE (:j = 0 OR k.jadwal_id = :j)
      ORDER BY j.tanggal DESC, k.status, a.nama_anak''', {'j': jid});
    return jsonResponse(rows.map((x) => {...x, 'tanggal': dateOnly(x['tanggal'])}).toList());
  }));

  r.get('/api/laporan', staff((req, s) async {
    final rows = await Db.query('''
      SELECT l.*, a.nama_anak, ib.nama AS nama_ibu, ib.no_hp
      FROM laporan_kondisi l
      JOIN anak a ON l.kode_anak = a.kode_anak
      JOIN ibu_balita ib ON l.ibu_id = ib.id
      ORDER BY l.created_at DESC''');
    return jsonResponse(rows.map((x) => {...x, 'tanggal_laporan': dateOnly(x['tanggal_laporan'])}).toList());
  }));

  r.post('/api/laporan/<id>/baca', staff((req, s) async {
    await Db.exec("UPDATE laporan_kondisi SET status_baca='sudah' WHERE id=:i", {'i': toInt(req.params['id'])});
    return jsonResponse({'message': 'Laporan ditandai sudah dibaca.'});
  }));

  // =============== PORTAL IBU ===============
  r.get('/api/ibu/anak', ibu((req, s) async {
    final rows = await Db.query('''
      SELECT a.* FROM anak a JOIN ibu_anak ia ON a.kode_anak = ia.kode_anak
      WHERE ia.ibu_id = :i ORDER BY a.nama_anak ASC''', {'i': s.id});
    return jsonResponse(rows.map(_anak).toList());
  }));

  r.post('/api/ibu/anak', ibu((req, s) async {
    final b = await readBody(req);
    final kode = str(b, 'kode_anak');
    if (kode.isEmpty) return fail('Kode anak wajib diisi.');
    if (await Db.one('SELECT id FROM anak WHERE kode_anak=:k', {'k': kode}) == null) {
      return fail('Kode Anak tidak ditemukan.', 404);
    }
    if (await Db.one('SELECT id FROM ibu_anak WHERE ibu_id=:i AND kode_anak=:k', {'i': s.id, 'k': kode}) !=
        null) {
      return fail('Anak sudah terhubung dengan akun Anda.');
    }
    await Db.exec('INSERT INTO ibu_anak (ibu_id,kode_anak) VALUES (:i,:k)', {'i': s.id, 'k': kode});
    return jsonResponse({'message': 'Anak berhasil ditambahkan.'}, 201);
  }));

  // Riwayat imunisasi + vaksin berikutnya untuk satu anak
  r.get('/api/ibu/imunisasi', ibu((req, s) async {
    final kode = req.url.queryParameters['anak'] ?? '';
    final anak = await Db.one('''
      SELECT a.* FROM anak a JOIN ibu_anak ia ON a.kode_anak = ia.kode_anak
      WHERE ia.ibu_id=:i AND a.kode_anak=:k''', {'i': s.id, 'k': kode});
    if (anak == null) return fail('Anak tidak ditemukan.', 404);
    final riwayat = await Db.query('''
      SELECT i.*, v.nama_vaksin FROM imunisasi i JOIN vaksin v ON i.id_vaksin = v.id_vaksin
      WHERE i.kode_anak=:k ORDER BY i.tanggal_imunisasi ASC''', {'k': kode});
    final usia = usiaBulan(anak['tanggal_lahir'] ?? '');
    final sudah = riwayat.where((x) => x['keterangan'] != 'Tidak Hadir').map((x) => x['id_vaksin']).toSet();
    final berikutnya = <Map<String, Object?>>[];
    for (final j in jadwalKemenkes) {
      if (sudah.contains(j[0])) continue;
      final min = j[2] as int;
      if (usia >= min - 1) {
        berikutnya.add({
          'id_vaksin': j[0],
          'nama_vaksin': j[1],
          'usia_min': min,
          'status': usia >= min ? 'Terlambat' : 'Belum waktunya',
        });
      }
    }
    return jsonResponse({
      'anak': _anak(anak),
      'usia_bulan': usia,
      'riwayat': riwayat
          .map((x) => {
                'id_vaksin': x['id_vaksin'],
                'nama_vaksin': x['nama_vaksin'],
                'tanggal_imunisasi': dateOnly(x['tanggal_imunisasi']),
                'usia_bulan': toInt(x['usia_bulan']),
                'keterangan': x['keterangan'],
              })
          .toList(),
      'berikutnya': berikutnya,
    });
  }));

  // Jadwal mendatang + status konfirmasi untuk satu anak
  r.get('/api/ibu/jadwal', ibu((req, s) async {
    final kode = req.url.queryParameters['anak'] ?? '';
    final jadwal = await Db.query('SELECT * FROM jadwal WHERE tanggal >= CURDATE() ORDER BY tanggal, jam_mulai');
    final konf = await Db.query(
        'SELECT jadwal_id, status FROM konfirmasi_kehadiran WHERE ibu_id=:i AND kode_anak=:k',
        {'i': s.id, 'k': kode});
    final map = {for (final k in konf) k['jadwal_id']: k['status']};
    return jsonResponse(jadwal.map((j) => {..._jadwal(j), 'status': map[j['id']]}).toList());
  }));

  r.post('/api/ibu/konfirmasi', ibu((req, s) async {
    final b = await readBody(req);
    final jid = toInt(b['jadwal_id']);
    final kode = str(b, 'kode_anak');
    final status = str(b, 'status') == 'hadir' ? 'hadir' : 'tidak_hadir';
    if (await Db.one('SELECT id FROM ibu_anak WHERE ibu_id=:i AND kode_anak=:k', {'i': s.id, 'k': kode}) ==
        null) {
      return fail('Anak tidak terhubung dengan akun Anda.', 403);
    }
    final ada = await Db.one(
        'SELECT id FROM konfirmasi_kehadiran WHERE ibu_id=:i AND jadwal_id=:j AND kode_anak=:k',
        {'i': s.id, 'j': jid, 'k': kode});
    if (ada != null) {
      await Db.exec('UPDATE konfirmasi_kehadiran SET status=:s, keterangan=:ket WHERE id=:id',
          {'s': status, 'ket': str(b, 'keterangan'), 'id': toInt(ada['id'])});
    } else {
      await Db.exec('''
        INSERT INTO konfirmasi_kehadiran (ibu_id,jadwal_id,kode_anak,status,keterangan)
        VALUES (:i,:j,:k,:s,:ket)''',
          {'i': s.id, 'j': jid, 'k': kode, 's': status, 'ket': str(b, 'keterangan')});
    }
    return jsonResponse({'message': 'Konfirmasi tersimpan.'});
  }));

  r.get('/api/ibu/laporan', ibu((req, s) async {
    final rows = await Db.query('''
      SELECT l.*, a.nama_anak FROM laporan_kondisi l JOIN anak a ON l.kode_anak = a.kode_anak
      WHERE l.ibu_id=:i ORDER BY l.created_at DESC''', {'i': s.id});
    return jsonResponse(rows.map((x) => {...x, 'tanggal_laporan': dateOnly(x['tanggal_laporan'])}).toList());
  }));

  r.post('/api/ibu/laporan', ibu((req, s) async {
    final b = await readBody(req);
    final kode = str(b, 'kode_anak'), kondisi = str(b, 'kondisi');
    if (kode.isEmpty || kondisi.isEmpty) return fail('Pilih anak dan kondisi terlebih dahulu.');
    if (await Db.one('SELECT id FROM ibu_anak WHERE ibu_id=:i AND kode_anak=:k', {'i': s.id, 'k': kode}) ==
        null) {
      return fail('Anak tidak terhubung dengan akun Anda.', 403);
    }
    await Db.exec('''
      INSERT INTO laporan_kondisi (ibu_id,kode_anak,tanggal_laporan,kondisi,deskripsi)
      VALUES (:i,:k,:t,:c,:d)''', {
      'i': s.id,
      'k': kode,
      't': str(b, 'tanggal_laporan', today()),
      'c': kondisi,
      'd': str(b, 'deskripsi'),
    });
    return jsonResponse({'message': 'Laporan kondisi berhasil dikirim!'}, 201);
  }));

  return r;
}

Map<String, Object?> _jadwal(Map<String, String?> j) => {
      'id': toInt(j['id']),
      'kode_jadwal': j['kode_jadwal'],
      'tanggal': dateOnly(j['tanggal']),
      'lokasi': j['lokasi'],
      'kegiatan': j['kegiatan'],
      'jam_mulai': hhmm(j['jam_mulai']),
      'jam_selesai': hhmm(j['jam_selesai']),
    };

Map<String, Object?> _anak(Map<String, String?> a) => {
      'kode_anak': a['kode_anak'],
      'nama_anak': a['nama_anak'],
      'jenis_kelamin': a['jenis_kelamin'],
      'tanggal_lahir': dateOnly(a['tanggal_lahir']),
      'nama_ibu': a['nama_ibu'],
      'alamat': a['alamat'],
      'usia_bulan': usiaBulan(a['tanggal_lahir'] ?? ''),
    };
