import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'pages/login_page.dart';
import 'shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  runApp(const PosyanduApp());
}

class PosyanduApp extends StatelessWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posyandu Flamboyan VI',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ValueListenableBuilder<bool>(
        valueListenable: Api.loggedIn,
        builder: (_, ok, __) => ok ? const Shell() : const LoginPage(),
      ),
    );
  }
}
