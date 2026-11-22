import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});
  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late Future<List<dynamic>> f = _fetch();
  final tgl = TextEditingController();
  final lokasi = TextEditingController();
  final kegiatan = TextEditingController();
  final mulai = TextEditingController();
  final selesai = TextEditingController();
  int bulan = DateTime.now().month;
  int tahun = DateTime.now().year;
  bool saving = false;

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/jadwal')) as List;
  void _reload() => setState(() => f = _fetch());

  void _reset() {
    tgl.clear();
    lokasi.clear();
    kegiatan.clear();
    mulai.clear();
    selesai.clear();
  }

  Future<void> _tambah() async {
    setState(() => saving = true);
    try {
      final r = await Api.post('/api/jadwal', {
        'tanggal': tgl.text,
        'lokasi': lokasi.text,
        'kegiatan': kegiatan.text,
        'jam_mulai': mulai.text,
        'jam_selesai': selesai.text,
      });
      if (mounted) showMsg(context, r['message']);
      _reset();
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _hapus(int id) async {
    if (!await confirmDialog(context, 'Hapus jadwal ini?')) return;
    try {
      final r = await Api.delete('/api/jadwal/$id');
      if (mounted) showMsg(context, r['message']);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  Widget _calendar(Set<String> eventDates) {
    final first = DateTime(tahun, bulan, 1);
    final offset = first.weekday - 1; // Senin = 0
    final days = DateTime(tahun, bulan + 1, 0).day;
    final now = DateTime.now();
    final cells = <Widget>[
      for (final d in const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
        Center(child: Text(d, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.muted))),
      for (var i = 0; i < offset; i++) const SizedBox(),
      for (var d = 1; d <= days; d++)
        Builder(builder: (_) {
          final iso = isoDate(DateTime(tahun, bulan, d));
          final isToday = d == now.day && bulan == now.month && tahun == now.year;
          final hasEvent = eventDates.contains(iso);
          return InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => tgl.text = iso),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? C.navy : (tgl.text == iso ? C.blueLight : null),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$d',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isToday || hasEvent) ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? Colors.white : (hasEvent ? const Color(0xFF2980B9) : C.navy),
                  )),
            ),
          );
        }),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              bulan--;
              if (bulan < 1) {
                bulan = 12;
                tahun--;
              }
            }),
          ),
          Text('${bulanNames[bulan]} $tahun', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              bulan++;
              if (bulan > 12) {
                bulan = 1;
                tahun++;
              }
            }),
          ),
        ]),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1.25,
          children: cells,
        ),
      ]),
    );
  }

  Widget _card(Map j, bool mendatang) {
    final fg = mendatang ? Colors.white : C.navy;
    final sub = mendatang ? Colors.white70 : C.muted;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: mendatang ? C.navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mendatang ? C.navy : C.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(mendatang ? 'JADWAL MENDATANG' : 'JADWAL SEBELUMNYA',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1, color: sub)),
          Text('ID: ${j['kode_jadwal']}',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sub)),
        ]),
        const SizedBox(height: 8),
        Text(tglKartu(j['tanggal']), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(height: 12),
        _info('LOKASI:', '${j['lokasi']}', sub),
        _info('PUKUL:', '${j['jam_mulai']} - ${j['jam_selesai']} WIB', sub),
        _info('KEGIATAN:', '${j['kegiatan']}', sub),
        if (Api.isAdmin) ...[
          const SizedBox(height: 12),
          Btn('Hapus', kind: BtnKind.danger, onPressed: () => _hapus(j['id'] as int)),
        ],
      ]),
    );
  }

  Widget _info(String k, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$k ', style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 12.5)),
          TextSpan(text: v, style: TextStyle(color: c, fontSize: 12.5)),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      PageTitle('JADWAL KEGIATAN POSYANDU', center: !Api.isAdmin),
      Loader<List<dynamic>>(
        future: f,
        onRetry: _reload,
        builder: (list) {
          final today = isoDate(DateTime.now());
          final mendatang = list.where((j) => (j['tanggal'] as String).compareTo(today) >= 0).toList();
          final lampau = list.where((j) => (j['tanggal'] as String).compareTo(today) < 0).toList();
          final events = {for (final j in list) j['tanggal'] as String};
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (Api.isAdmin)
              CardBox(
                child: LayoutBuilder(builder: (context, c) {
                  final form = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Detail Pelaksanaan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    DateField('Tanggal', tgl),
                    Field('Lokasi', controller: lokasi, hint: 'Nama lokasi'),
                    Field('Kegiatan', controller: kegiatan, hint: 'Nama kegiatan'),
                    Row(children: [
                      Expanded(child: TimeField('Jam mulai', mulai)),
                      const SizedBox(width: 12),
                      Expanded(child: TimeField('Jam selesai', selesai)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(child: Btn('BATALKAN', kind: BtnKind.secondary, onPressed: _reset)),
                      const SizedBox(width: 12),
                      Expanded(child: Btn('TAMBAH JADWAL', onPressed: _tambah, loading: saving)),
                    ]),
                  ]);
                  if (c.maxWidth > 700) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _calendar(events)),
                      const SizedBox(width: 32),
                      Expanded(child: form),
                    ]);
                  }
                  return Column(children: [_calendar(events), const SizedBox(height: 20), form]);
                }),
              ),
            for (final j in mendatang) _card(j as Map, true),
            for (final j in lampau) _card(j as Map, false),
            if (list.isEmpty) const AlertBox('Belum ada jadwal.'),
          ]);
        },
      ),
    ]);
  }
}
