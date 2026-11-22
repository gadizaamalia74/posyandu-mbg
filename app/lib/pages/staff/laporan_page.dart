import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

(Color, Color) kondisiColor(String k) => switch (k) {
      'Baik' => (C.okBg, C.okFg),
      'Demam' || 'Alergi' => (C.badBg, C.badFg),
      'Rewel' => (C.warnBg, C.warnFg),
      _ => (const Color(0xFFE2E8F0), const Color(0xFF444444)),
    };

/// Laporan kondisi anak yang dikirim ibu (dilihat admin/kader).
class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});
  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool semua = false;
  late Future<List<dynamic>> f = _fetch();

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/laporan')) as List;
  void _reload() => setState(() => f = _fetch());

  Future<void> _baca(int id) async {
    try {
      final r = await Api.post('/api/laporan/$id/baca', {});
      if (mounted) showMsg(context, r['message']);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('LAPORAN KONDISI ANAK'),
      Wrap(spacing: 8, children: [
        Btn('Belum dibaca', kind: semua ? BtnKind.outline : BtnKind.primary, onPressed: () => setState(() => semua = false)),
        Btn('Semua', kind: semua ? BtnKind.primary : BtnKind.outline, onPressed: () => setState(() => semua = true)),
      ]),
      const SizedBox(height: 16),
      Loader<List<dynamic>>(
        future: f,
        onRetry: _reload,
        builder: (all) {
          final rows = semua ? all : all.where((r) => r['status_baca'] == 'belum').toList();
          if (rows.isEmpty) return const AlertBox('Tidak ada laporan.');
          return Column(children: [
            for (final r in rows)
              CardBox(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text('${r['nama_anak']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    Builder(builder: (_) {
                      final (bg, fg) = kondisiColor('${r['kondisi']}');
                      return Badge2('${r['kondisi']}', bg, fg);
                    }),
                  ]),
                  Text('${r['kode_anak']} · ${tglSlash(r['tanggal_laporan'])}',
                      style: const TextStyle(color: C.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Text('Ibu: ${r['nama_ibu']} (${(r['no_hp'] ?? '').toString().isEmpty ? '-' : r['no_hp']})',
                      style: const TextStyle(fontSize: 13)),
                  if ((r['deskripsi'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${r['deskripsi']}', style: const TextStyle(fontSize: 13.5)),
                  ],
                  if (r['status_baca'] == 'belum') ...[
                    const SizedBox(height: 10),
                    Btn('Tandai sudah dibaca', kind: BtnKind.secondary, onPressed: () => _baca(int.parse('${r['id']}'))),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('✓ Sudah dibaca', style: TextStyle(color: C.okFg, fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }
}
