import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../shell.dart';
import '../staff/laporan_page.dart' show kondisiColor;

/// Anak yang sedang dipilih (dibagi antar halaman ibu).
class IbuState {
  static final ValueNotifier<String?> selected = ValueNotifier(null);
  static List<Map<String, dynamic>> anak = [];

  static Future<List<Map<String, dynamic>>> load() async {
    final r = (await Api.get('/api/ibu/anak')) as List;
    anak = r.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (anak.isNotEmpty && !anak.any((a) => a['kode_anak'] == selected.value)) {
      selected.value = anak.first['kode_anak'] as String;
    }
    return anak;
  }

  static Map<String, dynamic>? get current {
    for (final a in anak) {
      if (a['kode_anak'] == selected.value) return a;
    }
    return null;
  }
}

class _AnakPicker extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  const _AnakPicker(this.list);
  @override
  Widget build(BuildContext context) {
    if (list.length < 2) return const SizedBox();
    return ValueListenableBuilder<String?>(
      valueListenable: IbuState.selected,
      builder: (_, sel, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in list)
            ChoiceChip(
              label: Text('${a['nama_anak']}'),
              selected: a['kode_anak'] == sel,
              selectedColor: C.navy,
              labelStyle: TextStyle(
                  color: a['kode_anak'] == sel ? Colors.white : C.navy, fontWeight: FontWeight.w600),
              onSelected: (_) => IbuState.selected.value = a['kode_anak'] as String,
            ),
        ]),
      ),
    );
  }
}

/// Kerangka halaman ibu: memuat daftar anak lalu membangun isi per anak terpilih.
class _IbuScaffold extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext, Map<String, dynamic> anak, List<Map<String, dynamic>> all) builder;
  final bool requireAnak;
  const _IbuScaffold(this.title, this.builder) : requireAnak = true;
  @override
  State<_IbuScaffold> createState() => _IbuScaffoldState();
}

class _IbuScaffoldState extends State<_IbuScaffold> {
  late Future<List<Map<String, dynamic>>> f = IbuState.load();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      PageTitle(widget.title),
      Loader<List<Map<String, dynamic>>>(
        future: f,
        onRetry: () => setState(() => f = IbuState.load()),
        builder: (list) {
          if (list.isEmpty && widget.requireAnak) {
            return CardBox(
              child: Column(children: [
                const Text('Belum ada data anak yang terhubung dengan akun Anda.'),
                const SizedBox(height: 12),
                Btn('Tambah kode anak di Profil', onPressed: () => ShellScope.of(context).go('profil')),
              ]),
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _AnakPicker(list),
            ValueListenableBuilder<String?>(
              valueListenable: IbuState.selected,
              builder: (ctx, _, __) {
                final a = IbuState.current;
                return a == null ? const SizedBox() : widget.builder(ctx, a, list);
              },
            ),
          ]);
        },
      ),
    ]);
  }
}

// ======================= BERANDA =======================
class IbuBerandaPage extends StatelessWidget {
  const IbuBerandaPage({super.key});
  @override
  Widget build(BuildContext context) {
    return _IbuScaffold('Halo, ${Api.user['nama'] ?? ''} 👋', (ctx, a, all) => _BerandaBody(a, key: ValueKey(a['kode_anak'])));
  }
}

class _BerandaBody extends StatefulWidget {
  final Map<String, dynamic> anak;
  const _BerandaBody(this.anak, {super.key});
  @override
  State<_BerandaBody> createState() => _BerandaBodyState();
}

class _BerandaBodyState extends State<_BerandaBody> {
  late Future<List<dynamic>> f = Future.wait([
    Api.get('/api/jadwal/next'),
    Api.get('/api/ibu/imunisasi', {'anak': widget.anak['kode_anak']}),
  ]);

  @override
  Widget build(BuildContext context) {
    final a = widget.anak;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${a['nama_anak']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Usia ${usiaText(a['usia_bulan'] as int)} · ${a['jenis_kelamin'] == 'L' ? 'Laki-laki' : 'Perempuan'} · Lahir ${tglIndo(a['tanggal_lahir'])}',
            style: const TextStyle(color: C.muted, fontSize: 13.5),
          ),
        ]),
      ),
      Loader<List<dynamic>>(
        future: f,
        builder: (r) {
          final next = r[0] as Map?;
          final berikut = ((r[1] as Map)['berikutnya'] as List).take(3).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Jadwal Posyandu Berikutnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (next == null)
                  const Text('Belum ada jadwal.', style: TextStyle(color: C.muted))
                else ...[
                  Text('${tglIndo(next['tanggal'])}, ${next['jam_mulai']}–${next['jam_selesai']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${next['kegiatan']} · ${next['lokasi']}', style: const TextStyle(color: C.muted, fontSize: 13.5)),
                  const SizedBox(height: 12),
                  Btn('Konfirmasi Kehadiran', onPressed: () => ShellScope.of(context).go('jadwal')),
                ],
              ]),
            ),
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Imunisasi Berikutnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (berikut.isEmpty)
                  const Text('Tidak ada imunisasi yang jatuh tempo.', style: TextStyle(color: C.muted)),
                for (final v in berikut)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: Text('${v['nama_vaksin']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      v['status'] == 'Terlambat'
                          ? const Badge2('Terlambat', C.badBg, C.badFg)
                          : const Badge2('Segera', C.warnBg, C.warnFg),
                    ]),
                  ),
              ]),
            ),
          ]);
        },
      ),
    ]);
  }
}

// ======================= IMUNISASI =======================
class IbuImunisasiPage extends StatelessWidget {
  const IbuImunisasiPage({super.key});
  @override
  Widget build(BuildContext context) =>
      _IbuScaffold('RIWAYAT IMUNISASI', (ctx, a, all) => _ImunisasiBody(key: ValueKey(a['kode_anak']), anak: a));
}

class _ImunisasiBody extends StatefulWidget {
  final Map<String, dynamic> anak;
  const _ImunisasiBody({super.key, required this.anak});
  @override
  State<_ImunisasiBody> createState() => _ImunisasiBodyState();
}

class _ImunisasiBodyState extends State<_ImunisasiBody> {
  late Future<dynamic> f = Api.get('/api/ibu/imunisasi', {'anak': widget.anak['kode_anak']});

  Widget _row(IconData icon, Color bg, Color fg, String title, String sub, String badge) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
              Text(sub, style: const TextStyle(color: C.muted, fontSize: 12.5)),
            ]),
          ),
          Badge2(badge, bg, fg),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Loader<dynamic>(
      future: f,
      builder: (r) {
        final riwayat = r['riwayat'] as List;
        final berikut = r['berikutnya'] as List;
        return CardBox(
          child: Column(children: [
            for (final x in riwayat)
              _row(
                x['keterangan'] == 'Tidak Hadir' ? Icons.close : Icons.check,
                x['keterangan'] == 'Tidak Hadir' || x['keterangan'] == 'Terlambat' ? C.badBg : C.okBg,
                x['keterangan'] == 'Tidak Hadir' || x['keterangan'] == 'Terlambat' ? C.badFg : C.okFg,
                '${x['nama_vaksin']}',
                '${tglIndo(x['tanggal_imunisasi'])} · usia ${x['usia_bulan']} bulan',
                '${x['keterangan']}',
              ),
            for (final v in berikut)
              _row(
                v['status'] == 'Terlambat' ? Icons.warning_amber : Icons.schedule,
                v['status'] == 'Terlambat' ? C.badBg : C.warnBg,
                v['status'] == 'Terlambat' ? C.badFg : C.warnFg,
                '${v['nama_vaksin']}',
                'Usia ${v['usia_min']} bulan',
                '${v['status']}',
              ),
            if (riwayat.isEmpty && berikut.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Belum ada riwayat imunisasi.', style: TextStyle(color: C.muted)),
              ),
          ]),
        );
      },
    );
  }
}

// ======================= JADWAL =======================
class IbuJadwalPage extends StatelessWidget {
  const IbuJadwalPage({super.key});
  @override
  Widget build(BuildContext context) =>
      _IbuScaffold('Jadwal & Konfirmasi Kehadiran', (ctx, a, all) => _JadwalBody(key: ValueKey(a['kode_anak']), anak: a));
}

class _JadwalBody extends StatefulWidget {
  final Map<String, dynamic> anak;
  const _JadwalBody({super.key, required this.anak});
  @override
  State<_JadwalBody> createState() => _JadwalBodyState();
}

class _JadwalBodyState extends State<_JadwalBody> {
  late Future<List<dynamic>> f = _fetch();
  Future<List<dynamic>> _fetch() async =>
      (await Api.get('/api/ibu/jadwal', {'anak': widget.anak['kode_anak']})) as List;

  Future<void> _konfirmasi(int jid, String status) async {
    try {
      final r = await Api.post('/api/ibu/konfirmasi', {
        'jadwal_id': jid,
        'kode_anak': widget.anak['kode_anak'],
        'status': status,
      });
      if (mounted) {
        showMsg(context, r['message'] ?? 'Konfirmasi tersimpan.');
        setState(() => f = _fetch());
      }
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Loader<List<dynamic>>(
      future: f,
      onRetry: () => setState(() => f = _fetch()),
      builder: (list) {
        if (list.isEmpty) return const CardBox(child: Text('Belum ada jadwal mendatang.', style: TextStyle(color: C.muted)));
        return Column(children: [
          for (final j in list)
            CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${tglIndo(j['tanggal'])} · ${j['jam_mulai']}–${j['jam_selesai']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${j['kegiatan']}'),
                Text('${j['lokasi']}', style: const TextStyle(color: C.muted, fontSize: 13.5)),
                if (j['status'] != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('Status ${widget.anak['nama_anak']}: '),
                    j['status'] == 'hadir'
                        ? const Badge2('Hadir', C.okBg, C.okFg)
                        : const Badge2('Tidak hadir', C.badBg, C.badFg),
                  ]),
                ],
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.okBg,
                      foregroundColor: C.okFg,
                      side: j['status'] == 'hadir' ? const BorderSide(color: C.okFg, width: 2) : null,
                    ),
                    onPressed: () => _konfirmasi(j['id'] as int, 'hadir'),
                    child: const Text('Hadir', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.badBg,
                      foregroundColor: C.badFg,
                      side: j['status'] == 'tidak_hadir' ? const BorderSide(color: C.badFg, width: 2) : null,
                    ),
                    onPressed: () => _konfirmasi(j['id'] as int, 'tidak_hadir'),
                    child: const Text('Tidak Hadir', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
        ]);
      },
    );
  }
}

// ======================= LAPORAN KONDISI =======================
class IbuLaporanPage extends StatelessWidget {
  const IbuLaporanPage({super.key});
  @override
  Widget build(BuildContext context) => _IbuScaffold('LAPORAN KONDISI ANAK', (ctx, a, all) => _LaporanBody(key: ValueKey(a['kode_anak'])));
}

class _LaporanBody extends StatefulWidget {
  const _LaporanBody({super.key});
  @override
  State<_LaporanBody> createState() => _LaporanBodyState();
}

class _LaporanBodyState extends State<_LaporanBody> {
  static const kondisiList = ['Baik', 'Demam', 'Rewel', 'Alergi', 'Lainnya'];
  final tgl = TextEditingController(text: isoDate(DateTime.now()));
  final desk = TextEditingController();
  String? kondisi;
  bool sending = false;
  late Future<List<dynamic>> f = _fetch();
  Future<List<dynamic>> _fetch() async => (await Api.get('/api/ibu/laporan')) as List;

  Future<void> _kirim() async {
    final a = IbuState.current;
    if (a == null || kondisi == null) {
      showMsg(context, 'Pilih anak dan kondisi terlebih dahulu.', error: true);
      return;
    }
    setState(() => sending = true);
    try {
      final r = await Api.post('/api/ibu/laporan', {
        'kode_anak': a['kode_anak'],
        'tanggal_laporan': tgl.text,
        'kondisi': kondisi,
        'deskripsi': desk.text,
      });
      if (!mounted) return;
      showMsg(context, r['message']);
      desk.clear();
      setState(() {
        kondisi = null;
        f = _fetch();
      });
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kirim Laporan Baru untuk ${IbuState.current?['nama_anak'] ?? ''}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          DateField('Tanggal Laporan', tgl),
          const Text('Kondisi Anak', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 8, children: [
            for (final k in kondisiList)
              ChoiceChip(
                label: Text(k),
                selected: kondisi == k,
                selectedColor: C.navy,
                labelStyle: TextStyle(color: kondisi == k ? Colors.white : C.navy, fontWeight: FontWeight.w600),
                shape: const StadiumBorder(),
                onSelected: (_) => setState(() => kondisi = k),
              ),
          ]),
          const SizedBox(height: 14),
          Field('Deskripsi (opsional)',
              controller: desk, maxLines: 3, hint: 'Ceritakan kondisi anak lebih detail (gejala, suhu, dll)'),
          Btn('Kirim Laporan', onPressed: _kirim, loading: sending),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('Riwayat Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      Loader<List<dynamic>>(
        future: f,
        onRetry: () => setState(() => f = _fetch()),
        builder: (list) {
          if (list.isEmpty) return const Text('Belum ada laporan yang dikirim.', style: TextStyle(color: C.muted));
          return Column(children: [
            for (final l in list)
              CardBox(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${l['nama_anak']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    Builder(builder: (_) {
                      final (bg, fg) = kondisiColor('${l['kondisi']}');
                      return Badge2('${l['kondisi']}', bg, fg);
                    }),
                  ]),
                  Text(tglSlash(l['tanggal_laporan']), style: const TextStyle(color: C.muted, fontSize: 12.5)),
                  if ((l['deskripsi'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${l['deskripsi']}', style: const TextStyle(fontSize: 13.5)),
                  ],
                  const SizedBox(height: 6),
                  Text(l['status_baca'] == 'sudah' ? '✓ Sudah dibaca kader' : 'Belum dibaca kader',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: l['status_baca'] == 'sudah' ? C.okFg : C.muted)),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }
}
