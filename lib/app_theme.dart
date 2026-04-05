import 'package:flutter/material.dart';

class AppTheme {
  // ── Akshar Palette ────────────────────────────────────────────────
  static const Color teal        = Color(0xFF5DD3B6);
  static const Color brown       = Color(0xFF6E5034);
  static const Color gold        = Color(0xFFCDB885);
  static const Color cream       = Color(0xFFEFE1B5);

  static const Color bgDark      = Color(0xFF140E08);
  static const Color bgCard      = Color(0xFF1E1510);
  static const Color bgSurface   = Color(0xFF2A1C10);
  static const Color tealDark    = Color(0xFF3AA88D);
  static const Color goldDark    = Color(0xFFAA9060);
  static const Color textPrimary = Color(0xFFEFE1B5);
  static const Color textSub     = Color(0xFFCDB885);
  static const Color border      = Color(0x406E5034);
  static const Color borderGold  = Color(0x60CDB885);
  static const Color error       = Color(0xFFD4614A);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [teal, Color(0xFF3AA88D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFCDB885), Color(0xFFAA9060)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2A1C10), Color(0xFF1A1008)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF1C1208), Color(0xFF100A04)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        fontFamily: 'Tiro',
        colorScheme: const ColorScheme.dark(
          primary: teal,
          secondary: gold,
          surface: bgCard,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Tiro',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: cream,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(color: cream),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,
            foregroundColor: bgDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderGold, width: 1),
          ),
        ),
        iconTheme: const IconThemeData(color: cream),
        dividerTheme: const DividerThemeData(color: borderGold),
      );
}
