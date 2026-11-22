import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/widgets.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final nk = TextEditingController();
  final nama = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  String role = 'kader';
  int? selectedId;
  int? selectedIdx;
  late Future<List<dynamic>> f = _fetch();

  Future<List<dynamic>> _fetch() async => (await Api.get('/api/users')) as List;
  void _reload() => setState(() => f = _fetch());

  void _reset() => setState(() {
        for (final c in [nk, nama, email, pass]) {
          c.clear();
        }
        role = 'kader';
        selectedId = null;
        selectedIdx = null;
      });

  Map<String, dynamic> _body() => {
        'nk': nk.text.trim(),
        'nama': nama.text.trim(),
        'email': email.text.trim(),
        'password': pass.text,
        'role': role,
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
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageTitle('MANAJEMEN USER'),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Field('NK', controller: nk, hint: 'Nomor kader'),
          Field('Nama', controller: nama, hint: 'Nama lengkap'),
          Field('Email', controller: email, hint: 'email@contoh.com', keyboard: TextInputType.emailAddress),
          Field(selectedId == null ? 'Password' : 'Password (kosongkan jika tidak diganti)',
              controller: pass, obscure: true),
          Dropdown<String>('Role',
              value: role,
              items: const [
                DropdownMenuItem(value: 'kader', child: Text('Kader')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => role = v ?? 'kader')),
          Wrap(spacing: 10, runSpacing: 10, children: [
            Btn('Tambah', onPressed: () => _do(() => Api.post('/api/users', _body()))),
            Btn('Ubah',
                kind: BtnKind.outline,
                onPressed: selectedId == null ? null : () => _do(() => Api.put('/api/users/$selectedId', _body()))),
            Btn('Hapus',
                kind: BtnKind.outline,
                onPressed: selectedId == null
                    ? null
                    : () async {
                        if (await confirmDialog(context, 'Hapus user ini?')) {
                          await _do(() => Api.delete('/api/users/$selectedId'));
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
          columns: const ['NK', 'Nama', 'Email', 'Role'],
          selected: selectedIdx,
          onSelect: (i) => setState(() {
            final u = list[i] as Map;
            selectedIdx = i;
            selectedId = int.parse('${u['id']}');
            nk.text = u['nk'] ?? '';
            nama.text = u['nama'] ?? '';
            email.text = u['email'] ?? '';
            pass.clear();
            role = u['role'] == 'admin' ? 'admin' : 'kader';
          }),
          rows: [for (final u in list) ['${u['nk']}', '${u['nama']}', '${u['email'] ?? '-'}', '${u['role']}']],
        ),
      ),
    ]);
  }
}
