import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class ImunisasiPage extends StatefulWidget {
  const ImunisasiPage({super.key});
  @override
  State<ImunisasiPage> createState() => _ImunisasiPageState();
}

class _ImunisasiPageState extends State<ImunisasiPage> {
  static const ketOptions = ['Tepat Waktu', 'Terlambat', 'Tidak Hadir'];
  List<dynamic> vaksin = [];
  String vid = 'BC01';
  final search = TextEditingController();
  final tgl = TextEditingController(text: isoDate(DateTime.now()));
  final kode = TextEditingController();
  final nama = TextEditingController();
  final usia = TextEditingController();
  String ket = ketOptions.first;
  int? selectedId;
  int? selectedIdx;
  Future<List<dynamic>>? f;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      vaksin = (await Api.get('/api/vaksin')) as List;
      if (vaksin.isNotEmpty && !vaksin.any((v) => v['id_vaksin'] == vid)) vid = vaksin.first['id_vaksin'];
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
    if (mounted) setState(() => f = _fetch());
  }

  Future<List<dynamic>> _fetch() async =>
      (await Api.get('/api/imunisasi', {'vaksin': vid, 'search': search.text})) as List;

  void _reload() => setState(() => f = _fetch());

  void _reset() {
    setState(() {
      selectedId = null;
      selectedIdx = null;
      kode.clear();
      nama.clear();
      usia.clear();
      tgl.text = isoDate(DateTime.now());
      ket = ketOptions.first;
    });
  }

  Map<String, dynamic> _body() => {
        'kode_anak': kode.text.trim(),
        'nama_anak': nama.text.trim(),
        'id_vaksin': vid,
        'tanggal_imunisasi': tgl.text,
        'usia_bulan': usia.text,
        'keterangan': ket,
      };

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
    final namaVaksin = vaksin.firstWhere((v) => v['id_vaksin'] == vid, orElse: () => {'nama_vaksin': ''})['nama_vaksin'];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final v in vaksin)
          Btn(
            '${v['id_vaksin']}',
            kind: v['id_vaksin'] == vid ? BtnKind.primary : BtnKind.outline,
            onPressed: () {
              vid = v['id_vaksin'];
              _reset();
              _reload();
            },
          ),
      ]),
      const SizedBox(height: 18),
      PageTitle('DATA IMUNISASI ${'$namaVaksin'.toUpperCase()}'),
      SearchBox(search, hint: 'masukkan nama/kode anak', onSearch: _reload),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          DateField('Tanggal Imunisasi', tgl),
          Field('Kode Anak', controller: kode, hint: 'Kode anak', readOnly: selectedId != null),
          Field('Nama Anak', controller: nama, hint: 'Nama anak (wajib bila anak baru)', readOnly: selectedId != null),
          Field('Usia', controller: usia, hint: '0', keyboard: TextInputType.number, suffix: 'Bulan'),
          Dropdown<String>('Keterangan',
              value: ket,
              items: [for (final k in ketOptions) DropdownMenuItem(value: k, child: Text(k))],
              onChanged: (v) => setState(() => ket = v ?? ketOptions.first)),
          Wrap(spacing: 10, runSpacing: 10, children: [
            Btn('Simpan', onPressed: () => _do(() => Api.post('/api/imunisasi', _body()))),
            Btn('Ubah',
                kind: BtnKind.outline,
                onPressed: selectedId == null ? null : () => _do(() => Api.put('/api/imunisasi/$selectedId', _body()))),
            Btn('Hapus',
                kind: BtnKind.outline,
                onPressed: selectedId == null
                    ? null
                    : () async {
                        if (await confirmDialog(context, 'Hapus data imunisasi ini?')) {
                          await _do(() => Api.delete('/api/imunisasi/$selectedId'));
                        }
                      }),
            Btn('Tambah', kind: BtnKind.outline, onPressed: _reset),
          ]),
        ]),
      ),
      if (f == null)
        const Center(child: CircularProgressIndicator())
      else
        Loader<List<dynamic>>(
          future: f,
          onRetry: _reload,
          builder: (list) => AppTable(
            columns: const ['Kode Anak', 'Nama Anak', 'Tanggal', 'Usia (Bulan)', 'Keterangan'],
            selected: selectedIdx,
            onSelect: (i) {
              final r = list[i] as Map;
              setState(() {
                selectedId = r['id'] as int;
                selectedIdx = i;
                kode.text = r['kode_anak'];
                nama.text = r['nama_anak'];
                tgl.text = r['tanggal_imunisasi'];
                usia.text = '${r['usia_bulan']}';
                ket = ketOptions.contains(r['keterangan']) ? r['keterangan'] : ketOptions.first;
              });
            },
            rows: [
              for (final r in list)
                ['${r['kode_anak']}', '${r['nama_anak']}', tglSlash(r['tanggal_imunisasi']), '${r['usia_bulan']}', '${r['keterangan']}']
            ],
          ),
        ),
    ]);
  }
}
