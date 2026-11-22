import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Profil untuk admin/kader dan ibu balita.
class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});
  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final nama = TextEditingController();
  final email = TextEditingController();
  final hp = TextEditingController();
  final pass = TextEditingController();
  final kodeAnak = TextEditingController();
  Future<List<dynamic>>? anakFuture;
  bool ready = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await Api.get('/api/me');
      nama.text = me['nama'] ?? '';
      email.text = me['email'] ?? '';
      hp.text = me['no_hp'] ?? '';
      Api.user = {...Api.user, ...Map<String, dynamic>.from(me as Map)};
      if (Api.isIbu) anakFuture = Api.get('/api/ibu/anak').then((v) => v as List);
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
    if (mounted) setState(() => ready = true);
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final r = await Api.put('/api/me', {
        'nama': nama.text,
        'email': email.text,
        'no_hp': hp.text,
        'password': pass.text,
      });
      pass.clear();
      if (mounted) showMsg(context, r['message'] ?? 'Profil diperbarui.');
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _tambahAnak() async {
    try {
      final r = await Api.post('/api/ibu/anak', {'kode_anak': kodeAnak.text.trim()});
      kodeAnak.clear();
      if (mounted) {
        showMsg(context, r['message'] ?? 'Berhasil.');
        setState(() => anakFuture = Api.get('/api/ibu/anak').then((v) => v as List));
      }
    } on ApiException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Center(child: CircularProgressIndicator());
    final ibu = Api.isIbu;
    final initial = nama.text.isEmpty ? '?' : nama.text.characters.first.toUpperCase();
    return ListView(padding: const EdgeInsets.all(20), children: [
      CardBox(
        child: Row(children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: C.blueLight,
            child: Text(initial, style: const TextStyle(fontSize: 34, color: C.navy, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nama.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(email.text, style: const TextStyle(color: C.muted)),
              const SizedBox(height: 6),
              if (!ibu)
                Badge2('NK: ${Api.user['nk'] ?? '-'}  ·  ${(Api.user['role'] ?? '').toString().toUpperCase()}',
                    C.navy, Colors.white),
            ]),
          ),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ubah Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Field('Nama', controller: nama),
          if (ibu)
            Field('No HP', controller: hp, keyboard: TextInputType.phone)
          else
            Field('Email', controller: email, keyboard: TextInputType.emailAddress),
          Field('Password baru (kosongkan jika tidak diganti)', controller: pass, obscure: true),
          Btn('Simpan Perubahan', onPressed: _save, loading: saving),
        ]),
      ),
      if (ibu)
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Anak Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Loader<List<dynamic>>(
              future: anakFuture,
              builder: (list) => Column(children: [
                if (list.isEmpty) const Text('Belum ada anak.', style: TextStyle(color: C.muted)),
                for (final a in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        backgroundColor: C.blueLight,
                        child: Text('${a['nama_anak']}'.characters.first, style: const TextStyle(color: C.navy))),
                    title: Text('${a['nama_anak']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Kode ${a['kode_anak']} · ${usiaText(a['usia_bulan'] as int)}'),
                  ),
              ]),
            ),
            const Divider(height: 28),
            Field('Tambah anak dengan kode', controller: kodeAnak, hint: 'kode dari kader'),
            Btn('Tambah Anak', onPressed: _tambahAnak, kind: BtnKind.secondary),
          ]),
        ),
      Btn('Keluar', onPressed: () => Api.logout(), kind: BtnKind.danger, big: true),
    ]);
  }
}
