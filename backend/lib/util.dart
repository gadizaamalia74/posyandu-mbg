import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:shelf/shelf.dart';

Response jsonResponse(Object? data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Response fail(String message, [int status = 400]) =>
    jsonResponse({'error': message}, status);

Future<Map<String, dynamic>> readBody(Request req) async {
  final text = await req.readAsString();
  if (text.trim().isEmpty) return {};
  final data = jsonDecode(text);
  return data is Map<String, dynamic> ? data : {};
}

String str(Map<String, dynamic> b, String key, [String def = '']) =>
    (b[key] ?? def).toString().trim();

int toInt(Object? v, [int def = 0]) => int.tryParse('${v ?? ''}') ?? def;
double toDouble(Object? v, [double def = 0]) =>
    double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? def;

/// Ambil 'YYYY-MM-DD' dari nilai DATE/DATETIME.
String dateOnly(String? v) => (v ?? '').length >= 10 ? v!.substring(0, 10) : (v ?? '');

String hhmm(String? v) => (v ?? '').length >= 5 ? v!.substring(0, 5) : (v ?? '');

String today() => dateOnly(DateTime.now().toIso8601String());

/// Hash password baru (kompatibel dengan password_verify PHP).
String hashPassword(String plain) => BCrypt.hashpw(plain, BCrypt.gensalt());

/// Verifikasi hash. Hash PHP berawalan $2y$ -> dinormalkan ke $2a$ (format identik).
bool verifyPassword(String plain, String hash) {
  try {
    final h = hash.startsWith(r'$2y$') ? r'$2a$' + hash.substring(4) : hash;
    return BCrypt.checkpw(plain, h);
  } catch (_) {
    return false;
  }
}

String newToken() {
  final r = Random.secure();
  return List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// Usia dalam bulan dari tanggal lahir (setara hitungUsia() di PHP).
int usiaBulan(String tanggalLahir, [DateTime? now]) {
  final lahir = DateTime.tryParse(dateOnly(tanggalLahir));
  if (lahir == null) return 0;
  final n = now ?? DateTime.now();
  var bulan = (n.year - lahir.year) * 12 + (n.month - lahir.month);
  if (n.day < lahir.day) bulan--;
  return bulan < 0 ? 0 : bulan;
}

/// Status gizi sederhana, sama dengan penimbangan.php lama.
String statusGizi(double bb) {
  if (bb < 5) return 'Gizi Buruk';
  if (bb < 7) return 'Gizi Kurang';
  return 'Normal';
}

/// Jadwal imunisasi standar Kemenkes: [id_vaksin, nama, usia_min]
const jadwalKemenkes = <List<Object>>[
  ['HB01', 'Hepatitis B (HB-0)', 0],
  ['BC01', 'BCG + Polio 1', 1],
  ['DH11', 'DPT-HB-HiB 1 + Polio 2', 2],
  ['DH11', 'DPT-HB-HiB 2 + Polio 3', 3],
  ['DH11', 'DPT-HB-HiB 3 + Polio 4', 4],
  ['IP01', 'IPV (Polio Suntik)', 4],
  ['CM01', 'Campak/MR', 9],
  ['DH02', 'DPT-HB-HiB (Lanjutan)', 18],
  ['CM02', 'Campak/MR (Lanjutan)', 18],
];
