import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});
  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  late Future<List<dynamic>> f = _fetch();
  Future<List<dynamic>> _fetch() async => (await Api.get('/api/statistik')) as List;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('STATISTIK JUMLAH BAYI DAN BALITA YANG TERDAFTAR', center: true),
      Loader<List<dynamic>>(
        future: f,
        onRetry: () => setState(() => f = _fetch()),
        builder: (data) {
          if (data.isEmpty) {
            return const AlertBox('Belum ada data penimbangan dalam 6 bulan terakhir.');
          }
          final maxV = data.map((d) => d['jumlah'] as int).reduce((a, b) => a > b ? a : b);
          final top = maxV == 0 ? 1 : maxV;
          return CardBox(
            child: Column(children: [
              SizedBox(
                height: 300,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final d in data)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text('${d['jumlah']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Container(
                            height: 240 * ((d['jumlah'] as int) / top),
                            constraints: const BoxConstraints(maxWidth: 60),
                            decoration: const BoxDecoration(
                              color: C.navy,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${d['label']}', style: const TextStyle(fontSize: 11.5, color: C.navy)),
                        ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Bulan dan Tahun', style: TextStyle(color: C.muted, fontSize: 13.5)),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('*Jumlah anak unik yang ditimbang per bulan (6 bulan terakhir)',
                    style: TextStyle(color: C.muted, fontSize: 12.5)),
              ),
            ]),
          );
        },
      ),
    ]);
  }
}
