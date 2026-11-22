import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Konfirmasi kehadiran ibu balita per jadwal (khusus admin).
class KehadiranPage extends StatefulWidget {
  const KehadiranPage({super.key});
  @override
  State<KehadiranPage> createState() => _KehadiranPageState();
}

class _KehadiranPageState extends State<KehadiranPage> {
  List<dynamic> jadwal = [];
  int? jid;
  Future<List<dynamic>>? f;
  bool loadingJadwal = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      jadwal = (await Api.get('/api/jadwal')) as List;
      final today = isoDate(DateTime.now());
      // Jadwal terdekat yang akan datang; kalau tidak ada, jadwal terbaru
      final upcoming = jadwal.where((j) => (j['tanggal'] as String).compareTo(today) >= 0).toList()
        ..sort((a, b) => (a['tanggal'] as String).compareTo(b['tanggal'] as String));
      jid = upcoming.isNotEmpty ? upcoming.first['id'] as int : (jadwal.isNotEmpty ? jadwal.first['id'] as int : null);
      if (jid != null) f = _fetch();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
    if (mounted) setState(() => loadingJadwal = false);
  }

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/kehadiran', {'jadwal': '$jid'})) as List;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('KONFIRMASI KEHADIRAN IBU BALITA'),
      if (loadingJadwal)
        const Center(child: CircularProgressIndicator())
      else if (jadwal.isEmpty)
        const AlertBox('Belum ada jadwal.')
      else ...[
        CardBox(
          child: Dropdown<int>('Pilih jadwal',
              value: jid,
              items: [
                for (final j in jadwal)
                  DropdownMenuItem(
                    value: j['id'] as int,
                    child: Text('${tglSlash(j['tanggal'])} – ${j['kegiatan']}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() {
                    jid = v;
                    f = _fetch();
                  })),
        ),
        Loader<List<dynamic>>(
          future: f,
          onRetry: () => setState(() => f = _fetch()),
          builder: (rows) {
            final hadir = rows.where((r) => r['status'] == 'hadir').length;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('Hadir: $hadir  ·  Tidak hadir: ${rows.length - hadir}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              AppTable(
                columns: const ['Kode Anak', 'Nama Anak', 'Ibu', 'No HP', 'Status', 'Keterangan'],
                empty: 'Belum ada konfirmasi untuk jadwal ini',
                rows: [
                  for (final r in rows)
                    [
                      '${r['kode_anak']}',
                      '${r['nama_anak']}',
                      '${r['nama_ibu']}',
                      (r['no_hp'] ?? '').toString().isEmpty ? '-' : '${r['no_hp']}',
                      r['status'] == 'hadir' ? 'HADIR' : 'TIDAK HADIR',
                      (r['keterangan'] ?? '').toString().isEmpty ? '-' : '${r['keterangan']}',
                    ]
                ],
              ),
            ]);
          },
        ),
      ],
    ]);
  }
}
