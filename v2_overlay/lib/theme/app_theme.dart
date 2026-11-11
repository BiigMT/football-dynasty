import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF08111D);
  static const panel = Color(0xFF111F30);
  static const panelLight = Color(0xFF1B3045);
  // The Dynasty interface now uses electric cyan as its signature accent.
  static const green = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFC857);
  static const muted = Color(0xFF91A2B7);

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: green,
      onPrimary: navy,
      secondary: gold,
      onSecondary: navy,
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: panel,
      onSurface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: navy,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.055)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: const Color(0xFF0D1928),
        indicatorColor: green.withValues(alpha: 0.16),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 10,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? green : muted,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected) ? green : muted,
        )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: navy,
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: green, width: 1.4)),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
    );
  }
}
