import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      // Hero
      Container(
        height: 190,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [C.navy, C.navyMid, Color(0xFF3A7CA5)]),
        ),
        child: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CEGAH STUNTING SEJAK USIA DINI!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('untuk generasi yang lebih kuat, sehat dan cerdas',
              style: TextStyle(color: Colors.white70, fontSize: 14.5)),
        ]),
      ),
      // Info posyandu
      const CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('POSYANDU\nFLAMBOYAN VI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
          SizedBox(height: 16),
          _Contact(Icons.phone, '+62 897-1334-11877'),
          _Contact(Icons.email_outlined, 'posyanduflamboyan6@gmail.com'),
          _Contact(Icons.camera_alt_outlined, 'posyandu_flamboyan6'),
          _Contact(Icons.facebook, 'posyandu_flamboyan6'),
        ]),
      ),
      // Artikel
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ARTIKEL TERKAIT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          const _Artikel('Kegiatan Posyandu Saat Masa Pandemi 2022',
              'https://diskes.baliprov.go.id/posyandu-di-masa-pandemi-covid-19/'),
          const _Artikel('Stunting Di Indonesia',
              'https://rspp.co.id/artikel-detail-734-Stunting-di-Indonesia-Penyebab,-Dampak,-dan-Upaya-Pencegahan-.html'),
          const Divider(height: 28),
          for (final t in const [
            'Panduan Pengisian Data Penimbangan',
            'Panduan Pengisian Data Imunisasi',
            'Panduan Penambahan Jadwal',
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                const Icon(Icons.description_outlined, size: 18, color: C.navyMid),
                const SizedBox(width: 10),
                Expanded(child: Text(t, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _Contact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Contact(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: C.navy),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ]),
      );
}

class _Artikel extends StatelessWidget {
  final String title, url;
  const _Artikel(this.title, this.url);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 70,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(8)),
            child: const Text('📰', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(url, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
        ]),
      );
}
