import 'package:flutter/material.dart';

import 'core/api.dart';
import 'core/theme.dart';
import 'pages/ibu/ibu_pages.dart';
import 'pages/profil_page.dart';
import 'pages/staff/dashboard_page.dart';
import 'pages/staff/imunisasi_page.dart';
import 'pages/staff/jadwal_page.dart';
import 'pages/staff/kehadiran_page.dart';
import 'pages/staff/laporan_page.dart';
import 'pages/staff/notifikasi_page.dart';
import 'pages/staff/penimbangan_page.dart';
import 'pages/staff/statistik_page.dart';
import 'pages/staff/users_page.dart';
import 'pages/staff/vaksin_page.dart';

class MenuItem {
  final String id, label;
  final IconData icon;
  final Widget Function() build;
  final bool adminOnly;
  const MenuItem(this.id, this.label, this.icon, this.build, {this.adminOnly = false});
}

/// Memberi halaman anak akses untuk pindah halaman: ShellScope.of(context).go('jadwal')
class ShellScope extends InheritedWidget {
  final void Function(String id) go;
  const ShellScope({super.key, required this.go, required super.child});
  static ShellScope of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<ShellScope>()!;
  @override
  bool updateShouldNotify(ShellScope old) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final List<MenuItem> menu;
  late String current;
  int _notif = 0;
  int _rev = 0; // dinaikkan agar halaman dibuat ulang (memuat data baru) saat berpindah

  @override
  void initState() {
    super.initState();
    if (Api.isIbu) {
      menu = [
        MenuItem('dashboard', 'Beranda', Icons.home, () => const IbuBerandaPage()),
        MenuItem('imunisasi', 'Riwayat Imunisasi', Icons.vaccines, () => const IbuImunisasiPage()),
        MenuItem('jadwal', 'Jadwal Posyandu', Icons.calendar_month, () => const IbuJadwalPage()),
        MenuItem('laporan', 'Laporan Kondisi', Icons.medical_information, () => const IbuLaporanPage()),
        MenuItem('profil', 'Profil', Icons.person, () => const ProfilPage()),
      ];
    } else {
      menu = [
        MenuItem('dashboard', 'Dashboard', Icons.home, () => const DashboardPage()),
        MenuItem('jadwal', 'Jadwal Kegiatan', Icons.calendar_month, () => const JadwalPage()),
        MenuItem('penimbangan', 'Data Penimbangan', Icons.monitor_weight, () => const PenimbanganPage()),
        MenuItem('imunisasi', 'Data Imunisasi', Icons.vaccines, () => const ImunisasiPage()),
        MenuItem('laporan', 'Laporan Kondisi Anak', Icons.medical_information, () => const LaporanPage()),
        MenuItem('kehadiran', 'Kehadiran Ibu', Icons.how_to_reg, () => const KehadiranPage(), adminOnly: true),
        MenuItem('vaksin', 'Data Vaksin & Vitamin', Icons.science, () => const VaksinPage(), adminOnly: true),
        MenuItem('users', 'Manajemen User', Icons.manage_accounts, () => const UsersPage(), adminOnly: true),
        MenuItem('statistik', 'Statistik', Icons.bar_chart, () => const StatistikPage()),
        MenuItem('profil', 'Profil', Icons.person, () => const ProfilPage()),
      ];
    }
    current = 'dashboard';
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    if (Api.isIbu) return;
    try {
      final r = await Api.get('/api/notifikasi');
      if (mounted) setState(() => _notif = (r['jadwal'] as List).length);
    } catch (_) {}
  }

  void go(String id) {
    setState(() {
      current = id;
      _rev++;
    });
    if (id == 'dashboard') _loadNotif();
  }

  Widget _body() {
    if (current == 'notifikasi') return const NotifikasiPage();
    return menu.firstWhere((m) => m.id == current, orElse: () => menu.first).build();
  }

  Widget _navLink(String label, String id) {
    final active = current == id;
    return InkWell(
      onTap: () => go(id),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 700;
    final ibu = Api.isIbu;
    return ShellScope(
      go: go,
      child: Scaffold(
        drawer: _drawer(),
        body: SafeArea(
          child: Column(children: [
            // ---- TOPBAR ----
            Container(
              color: C.topbar,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: C.navy),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined, color: C.navy),
                  onPressed: () => go('profil'),
                ),
                if (!ibu)
                  IconButton(
                    onPressed: () => go('notifikasi'),
                    icon: Stack(clipBehavior: Clip.none, children: [
                      const Icon(Icons.notifications_none, color: C.navy),
                      if (_notif > 0)
                        Positioned(
                          top: -6,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration:
                                BoxDecoration(color: C.danger, borderRadius: BorderRadius.circular(10)),
                            child: Text('$_notif',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ]),
                  ),
              ]),
            ),
            // ---- NAVBAR ----
            Container(
              color: C.navy,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _navLink(ibu ? 'BERANDA' : 'DASHBOARD', 'dashboard'),
                if (wide)
                  Text(ibu ? 'POSYANDU FLAMBOYAN VI' : 'SELAMAT DATANG DI POSYANDU FLAMBOYAN VI',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: .6)),
                Row(children: [
                  if (ibu) ...[
                    _navLink('IMUNISASI', 'imunisasi'),
                    _navLink('JADWAL', 'jadwal'),
                  ] else ...[
                    _navLink('JADWAL', 'jadwal'),
                    _navLink('STATISTIK', 'statistik'),
                  ],
                ]),
              ]),
            ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('$current-$_rev'),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: _body(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: C.navy,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 18, 12, 18),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
            child: Row(children: [
              const Expanded(
                child: Text('MENU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(children: [
              for (final m in menu)
                if (!m.adminOnly || Api.isAdmin)
                  ListTile(
                    leading: Icon(m.icon, color: Colors.white70, size: 20),
                    title: Text(m.label,
                        style: TextStyle(
                            color: current == m.id ? Colors.white : Colors.white70,
                            fontWeight: current == m.id ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14.5)),
                    tileColor: current == m.id ? Colors.white10 : null,
                    onTap: () {
                      Navigator.pop(context);
                      go(m.id);
                    },
                  ),
            ]),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
            title: const Text('Keluar', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(context);
              await Api.logout();
            },
          ),
        ]),
      ),
    );
  }
}
