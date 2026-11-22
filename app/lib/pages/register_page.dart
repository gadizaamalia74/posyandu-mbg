import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Pendaftaran akun ibu balita (kode anak diberikan oleh kader).
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nama = TextEditingController();
  final email = TextEditingController();
  final hp = TextEditingController();
  final pass = TextEditingController();
  final konf = TextEditingController();
  final kode = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await Api.post('/api/auth/register-ibu', {
        'nama': nama.text,
        'email': email.text,
        'no_hp': hp.text,
        'password': pass.text,
        'konfirmasi': konf.text,
        'kode_anak': kode.text,
      }, auth: false);
      if (!mounted) return;
      showMsg(context, r['message'] ?? 'Akun berhasil dibuat!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.navy,
        foregroundColor: Colors.white,
        title: const Text('Daftar Akun Ibu', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (error != null) AlertBox(error!, bg: C.badBg, fg: C.badFg),
              Field('Nama Lengkap', controller: nama, hint: 'Nama ibu'),
              Field('Email', controller: email, hint: 'email@contoh.com', keyboard: TextInputType.emailAddress),
              Field('No HP (opsional)', controller: hp, hint: '08xxxxxxxxxx', keyboard: TextInputType.phone),
              Field('Password', controller: pass, hint: 'minimal 6 karakter', obscure: true),
              Field('Konfirmasi Password', controller: konf, hint: 'ulangi password', obscure: true),
              Field('Kode Anak', controller: kode, hint: 'kode dari kader posyandu'),
              const SizedBox(height: 8),
              Btn('DAFTAR', onPressed: _submit, big: true, loading: loading),
            ]),
          ),
        ),
      ),
    );
  }
}
