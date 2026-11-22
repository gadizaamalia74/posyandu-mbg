const bulanNames = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
  'Agustus', 'September', 'Oktober', 'November', 'Desember'
];
const bulanPendek = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

DateTime? parseDate(String? s) => (s == null || s.length < 10) ? null : DateTime.tryParse(s.substring(0, 10));

/// 2026-04-20 -> 20 April 2026
String tglIndo(String? s) {
  final d = parseDate(s);
  return d == null ? (s ?? '-') : '${d.day} ${bulanNames[d.month]} ${d.year}';
}

/// 2026-04-20 -> 20 APR 2026
String tglKartu(String? s) {
  final d = parseDate(s);
  return d == null ? (s ?? '-') : '${d.day.toString().padLeft(2, '0')} ${bulanPendek[d.month].toUpperCase()} ${d.year}';
}

/// 2026-04-20 -> 20/04/2026
String tglSlash(String? s) {
  final d = parseDate(s);
  return d == null
      ? (s ?? '-')
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String usiaText(int bulan) {
  if (bulan < 12) return '$bulan bulan';
  final t = bulan ~/ 12, b = bulan % 12;
  return b == 0 ? '$t tahun' : '$t tahun $b bulan';
}
