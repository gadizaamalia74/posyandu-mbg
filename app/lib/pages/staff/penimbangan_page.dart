import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class PenimbanganPage extends StatefulWidget {
  const PenimbanganPage({super.key});
  @override
  State<PenimbanganPage> createState() => _PenimbanganPageState();
}

class _PenimbanganPageState extends State<PenimbanganPage> {
  final search = TextEditingController();
  final filterTgl = TextEditingController();
  final tgl = TextEditingController(text: isoDate(DateTime.now()));
  final kode = TextEditingController();
  final nama = TextEditingController();
  final alamat = TextEditingController();
  final usia = TextEditingController();
  final ibu = TextEditingController();
  final bb = TextEditingController();
  final tb = TextEditingController();
  String jk = 'P';
  int? selectedId;
  int? selectedIdx;
  late Future<List<dynamic>> f = _fetch();

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/penimbangan', {
        'search': search.text,
        'tanggal': filterTgl.text,
      })) as List;

  void _reload() => setState(() => f = _fetch());

  void _reset() {
    setState(() {
      selectedId = null;
      selectedIdx = null;
      for (final c in [kode, nama, alamat, usia, ibu, bb, tb]) {
        c.clear();
      }
      tgl.text = isoDate(DateTime.now());
      jk = 'P';
    });
  }

  void _select(Map row, int idx) {
    setState(() {
      selectedId = row['id'] as int;
      selectedIdx = idx;
      tgl.text = row['tanggal_kegiatan'];
      kode.text = row['kode_anak'];
      nama.text = row['nama_anak'];
      alamat.text = row['alamat'] ?? '';
      usia.text = '${row['usia_bulan']}';
      ibu.text = row['nama_ibu'] ?? '';
      bb.text = '${row['bb']}';
      tb.text = '${row['tb']}';
      jk = row['jenis_kelamin'] ?? 'P';
    });
  }

  Map<String, dynamic> _body() => {
        'tanggal_kegiatan': tgl.text,
        'kode_anak': kode.text.trim(),
        'nama_anak': nama.text.trim(),
        'alamat': alamat.text.trim(),
        'usia_bulan': usia.text,
        'nama_ibu': ibu.text.trim(),
        'bb': bb.text,
        'tb': tb.text,
        'jenis_kelamin': jk,
      };

  Future<void> _do(Future<dynamic> Function() fn, {bool reset = true}) async {
    try {
      final r = await fn();
      if (mounted) showMsg(context, r['message'] ?? 'Berhasil');
      if (reset) _reset();
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('DATA PENIMBANGAN'),
      SearchBox(search, hint: 'masukkan nama/kode anak', onSearch: _reload),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: DateField('Filter tanggal kegiatan', filterTgl)),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Btn('Reset', kind: BtnKind.outline, onPressed: () {
            search.clear();
            filterTgl.clear();
            _reload();
          }),
        ),
      ]),
      CardBox(
        child: LayoutBuilder(builder: (context, c) {
          final kiri = Column(children: [
            DateField('Tanggal Kegiatan', tgl),
            Field('Kode Anak', controller: kode, hint: 'Kode anak', readOnly: selectedId != null),
            Field('Nama Anak', controller: nama, hint: 'Nama anak'),
            Field('Alamat', controller: alamat, hint: 'Alamat'),
          ]);
          final kanan = Column(children: [
            Field('Usia', controller: usia, hint: '0', keyboard: TextInputType.number, suffix: 'Bulan'),
            Field('Nama Ibu', controller: ibu, hint: 'Nama ibu'),
            Row(children: [
              Expanded(child: Field('BB', controller: bb, hint: '0.0', keyboard: TextInputType.number, suffix: 'Kg')),
              const SizedBox(width: 12),
              Expanded(child: Field('TB', controller: tb, hint: '0.0', keyboard: TextInputType.number, suffix: 'Cm')),
            ]),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'P', label: Text('Perempuan')),
                    ButtonSegment(value: 'L', label: Text('Laki-laki')),
                  ],
                  selected: {jk},
                  onSelectionChanged: (s) => setState(() => jk = s.first),
                ),
              ),
            ),
          ]);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (c.maxWidth > 700)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: kiri),
                const SizedBox(width: 32),
                Expanded(child: kanan),
              ])
            else ...[kiri, kanan],
            Wrap(spacing: 10, runSpacing: 10, children: [
              Btn('Simpan', kind: BtnKind.primary, onPressed: () => _do(() => Api.post('/api/penimbangan', _body()))),
              Btn('Ubah',
                  kind: BtnKind.outline,
                  onPressed: selectedId == null
                      ? null
                      : () => _do(() => Api.put('/api/penimbangan/$selectedId', _body()))),
              Btn('Hapus',
                  kind: BtnKind.outline,
                  onPressed: selectedId == null
                      ? null
                      : () async {
                          if (await confirmDialog(context, 'Hapus data penimbangan ini?')) {
                            await _do(() => Api.delete('/api/penimbangan/$selectedId'));
                          }
                        }),
              Btn('Tambah', kind: BtnKind.outline, onPressed: _reset),
            ]),
          ]);
        }),
      ),
      Loader<List<dynamic>>(
        future: f,
        onRetry: _reload,
        builder: (list) => AppTable(
          columns: const ['Kode Anak', 'Nama Anak', 'J. Kelamin', 'Usia (Bulan)', 'Nama Ibu', 'Alamat', 'BB', 'TB', 'Status Gizi'],
          selected: selectedIdx,
          onSelect: (i) => _select(list[i] as Map, i),
          rows: [
            for (final r in list)
              [
                '${r['kode_anak']}',
                '${r['nama_anak']}',
                '${r['jenis_kelamin']}',
                '${r['usia_bulan']}',
                '${r['nama_ibu']}',
                '${r['alamat']}',
                '${r['bb']}',
                '${r['tb']}',
                '${r['status_gizi']}',
              ]
          ],
        ),
      ),
    ]);
  }
}
