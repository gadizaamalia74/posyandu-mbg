import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';

class VaksinPage extends StatefulWidget {
  const VaksinPage({super.key});
  @override
  State<VaksinPage> createState() => _VaksinPageState();
}

class _VaksinPageState extends State<VaksinPage> {
  final id = TextEditingController();
  final nama = TextEditingController();
  String? idLama;
  int? selectedIdx;
  late Future<List<dynamic>> f = _fetch();

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/vaksin')) as List;
  void _reload() => setState(() => f = _fetch());

  void _reset() => setState(() {
        id.clear();
        nama.clear();
        idLama = null;
        selectedIdx = null;
      });

  Future<void> _do(Future<dynamic> Function() fn) async {
    try {
      final r = await fn();
      if (mounted) showMsg(context, r['message'] ?? 'Berhasil');
      _reset();
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('DATA VAKSIN & VITAMIN'),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Field('ID Vaksin', controller: id, hint: 'Cth: HB01'),
          Field('Nama Vaksin / Vitamin', controller: nama, hint: 'Nama vaksin'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            Btn('Simpan',
                onPressed: () => _do(() => Api.post('/api/vaksin', {'id_vaksin': id.text.trim(), 'nama_vaksin': nama.text.trim()}))),
            Btn('Ubah',
                kind: BtnKind.outline,
                onPressed: idLama == null
                    ? null
                    : () => _do(() => Api.put('/api/vaksin/$idLama', {'id_vaksin': id.text.trim(), 'nama_vaksin': nama.text.trim()}))),
            Btn('Hapus',
                kind: BtnKind.outline,
                onPressed: idLama == null
                    ? null
                    : () async {
                        if (await confirmDialog(context, 'Hapus vaksin ini? Data imunisasi terkait ikut terhapus.')) {
                          await _do(() => Api.delete('/api/vaksin/$idLama'));
                        }
                      }),
            Btn('Reset', kind: BtnKind.outline, onPressed: _reset),
          ]),
        ]),
      ),
      Loader<List<dynamic>>(
        future: f,
        onRetry: _reload,
        builder: (list) => AppTable(
          columns: const ['ID Vaksin', 'Nama Vaksin / Vitamin'],
          selected: selectedIdx,
          onSelect: (i) => setState(() {
            selectedIdx = i;
            idLama = list[i]['id_vaksin'];
            id.text = list[i]['id_vaksin'];
            nama.text = list[i]['nama_vaksin'];
          }),
          rows: [for (final v in list) ['${v['id_vaksin']}', '${v['nama_vaksin']}']],
        ),
      ),
    ]);
  }
}
