import 'package:flutter/material.dart';

abstract final class RoomColors {
  static const coral = Color(0xFFFF592C);
  static const coralInk = Color(0xFFB93A1D);
  static const ink = Color(0xFF171615);
  static const secondary = Color(0xFF55514D);
  static const muted = Color(0xFF726D67);
  static const canvas = Color(0xFFF8F7F4);
  static const surface = Colors.white;
  static const raised = Color(0xFFF1F0ED);
  static const line = Color(0x1A171615);
  static const peach = Color(0xFFFFEEE8);
  static const green = Color(0xFF24734A);
  static const greenWash = Color(0xFFEAF4ED);
  static const red = Color(0xFFB42318);
  static const redWash = Color(0xFFFCEDEA);
  static const amber = Color(0xFF8C5412);
  static const amberWash = Color(0xFFFFF3D8);
}

abstract final class RoomShape {
  static const panel = 22.0;
  static const control = 15.0;
  static const compact = 12.0;
  static const pill = 999.0;
}

abstract final class RoomMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
}

abstract final class RoomTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        scaffoldBackgroundColor: RoomColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RoomColors.coral,
          primary: RoomColors.coralInk,
          surface: RoomColors.surface,
          error: RoomColors.red,
        ),
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: RoomColors.muted, fontSize: 12),
          bodyMedium: TextStyle(color: RoomColors.secondary, fontSize: 14),
          bodyLarge: TextStyle(color: RoomColors.ink, fontSize: 16),
          titleMedium:
              TextStyle(color: RoomColors.ink, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(
              color: RoomColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.12),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: RoomColors.canvas,
          surfaceTintColor: Colors.transparent,
          foregroundColor: RoomColors.ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: RoomColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderSide: const BorderSide(color: RoomColors.line),
              borderRadius: BorderRadius.circular(RoomShape.control)),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: RoomColors.line),
              borderRadius: BorderRadius.circular(RoomShape.control)),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: RoomColors.coralInk, width: 1.5),
              borderRadius: BorderRadius.circular(RoomShape.control)),
        ),
        cardTheme: const CardThemeData(
            color: RoomColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero),
        dividerTheme: const DividerThemeData(
            color: RoomColors.line, thickness: 1, space: 1),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                backgroundColor: RoomColors.ink,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RoomShape.control)))),
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          backgroundColor: RoomColors.ink,
          indicatorColor: const Color(0xFF33312F),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              color: s.contains(WidgetState.selected)
                  ? RoomColors.coral
                  : Colors.white70,
              fontSize: 11)),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? RoomColors.coral
                  : Colors.white70)),
        ),
      );
}
