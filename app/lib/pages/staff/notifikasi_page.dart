import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});
  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  late Future<dynamic> f = Api.get('/api/notifikasi');

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('Notifikasi'),
      Loader<dynamic>(
        future: f,
        onRetry: () => setState(() => f = Api.get('/api/notifikasi')),
        builder: (r) {
          final jadwal = (r['jadwal'] as List);
          final belum = r['laporan_belum_dibaca'] as int;
          return CardBox(
            child: (jadwal.isEmpty && belum == 0)
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('Tidak ada notifikasi saat ini.', style: TextStyle(color: C.muted))),
                  )
                : Column(children: [
                    if (belum > 0)
                      AlertBox('📝 Ada $belum laporan kondisi anak yang belum dibaca.', bg: C.warnBg, fg: C.warnFg),
                    for (final j in jadwal)
                      AlertBox(
                        '📅 Jadwal Mendatang: ${tglKartu(j['tanggal'])} – ${j['kegiatan']} di ${j['lokasi']} (${j['jam_mulai']} WIB)',
                      ),
                  ]),
          );
        },
      ),
    ]);
  }
}
