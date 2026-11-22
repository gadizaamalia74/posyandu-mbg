import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna sama dengan css/style.css lama.
class C {
  static const navy = Color(0xFF0D2D4A);
  static const navyMid = Color(0xFF1A4A6E);
  static const blueLight = Color(0xFFB8D4E8);
  static const bg = Color(0xFFEEF3F7);
  static const muted = Color(0xFF6B8AA0);
  static const border = Color(0xFFD0DDE8);
  static const topbar = Color(0xFFD9E6F0);
  static const danger = Color(0xFFC0392B);
  static const okBg = Color(0xFFD4EDDA);
  static const okFg = Color(0xFF155724);
  static const badBg = Color(0xFFF8D7DA);
  static const badFg = Color(0xFF721C24);
  static const warnBg = Color(0xFFFFF3CD);
  static const warnFg = Color(0xFF856404);
  static const infoBg = Color(0xFFD1ECF1);
  static const infoFg = Color(0xFF0C5460);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.navy, primary: C.navy, surface: Colors.white),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: C.navy, displayColor: C.navy),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: Color(0xFFA0B4C5), fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: C.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: C.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: C.navyMid, width: 1.5),
      ),
    ),
  );
}
