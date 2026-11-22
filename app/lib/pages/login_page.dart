import 'package:flutter/material.dart';
 
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'register_page.dart';
 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
 
class _LoginPageState extends State<LoginPage> {
  bool ibu = false;
  bool loading = false;
  bool showPass = false;
  String? error;
  final id = TextEditingController();
  final pass = TextEditingController();
 
  @override
  void dispose() {
    id.dispose();
    pass.dispose();
    super.dispose();
  }
 
  Future<void> _login() async {
    if (id.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = ibu ? 'Email dan password wajib diisi.' : 'NK dan password wajib diisi.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (ibu) {
        await Api.loginIbu(id.text.trim(), pass.text);
      } else {
        await Api.loginStaff(id.text.trim(), pass.text);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
 
  Future<void> _serverDialog() async {
    final c = TextEditingController(text: Api.baseUrl);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alamat Server'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Field('URL backend', controller: c, hint: 'http://192.168.1.10:8080', keyboard: TextInputType.url),
          const Text(
            'Emulator Android: http://10.0.2.2:8080\nHP asli: http://IP-komputer:8080',
            style: TextStyle(fontSize: 12, color: C.muted),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      await Api.setBaseUrl(c.text);
      if (mounted) showMsg(context, 'Server: ${Api.baseUrl}');
    }
  }
 
  void _switchRole(bool toIbu) {
    if (toIbu == ibu) return;
    setState(() {
      ibu = toIbu;
      error = null;
      id.clear();
      pass.clear();
    });
  }
 
  Widget _roleTab(String label, bool value) {
    final active = ibu == value;
    return Expanded(
      child: InkWell(
        onTap: () => _switchRole(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: active ? C.navy : C.border, width: 2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? C.navy : C.muted,
            ),
          ),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.child_care, color: C.navy, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Posyandu Flamboyan VI',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Silakan masuk untuk melanjutkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: C.muted),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          _roleTab('Admin / Kader', false),
                          _roleTab('Ibu Balita', true),
                        ]),
                        const SizedBox(height: 24),
                        if (error != null) AlertBox(error!, bg: C.badBg, fg: C.badFg),
                        Field(
                          ibu ? 'Email' : 'NK (Nomor Kader)',
                          controller: id,
                          hint: ibu ? 'email@contoh.com' : 'Masukkan NK',
                          keyboard: ibu ? TextInputType.emailAddress : TextInputType.text,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('Password', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                            TextField(
                              controller: pass,
                              obscureText: !showPass,
                              onSubmitted: (_) => _login(),
                              decoration: InputDecoration(
                                hintText: 'Masukkan password',
                                suffixIcon: IconButton(
                                  icon: Icon(showPass ? Icons.visibility_off : Icons.visibility, size: 20),
                                  onPressed: () => setState(() => showPass = !showPass),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        Btn('Masuk', onPressed: _login, big: true, loading: loading),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ibu)
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Belum punya akun? ', style: TextStyle(color: C.muted, fontSize: 13.5)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        ),
                        child: const Text('Daftar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      ),
                    ]),
                  TextButton(
                    onPressed: _serverDialog,
                    child: const Text('Atur alamat server', style: TextStyle(color: C.muted, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}