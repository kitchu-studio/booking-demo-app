import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours taken from the shop itself: ink-blue and barber-pole red on cool paper.
/// Red is the single accent: it marks what is selected, nothing else.
class Palette {
  Palette._();

  static const paper = Color(0xFFF6F7F9);
  static const ink = Color(0xFF101A2E);
  static const pole = Color(0xFFC23B2E);
  static const steel = Color(0xFF6B7589);
  static const rule = Color(0xFFD5DAE3);
}

/// Prompt (geometric Thai) for headings and numbers, Sarabun for reading text.
TextTheme buildTextTheme() {
  final body = GoogleFonts.sarabunTextTheme()
      .apply(bodyColor: Palette.ink, displayColor: Palette.ink);

  TextStyle head(TextStyle? base, FontWeight weight) =>
      GoogleFonts.prompt(textStyle: base, fontWeight: weight);

  return body.copyWith(
    headlineMedium: head(body.headlineMedium, FontWeight.w700),
    headlineSmall: head(body.headlineSmall, FontWeight.w600),
    titleLarge: head(body.titleLarge, FontWeight.w600),
    titleMedium: head(body.titleMedium, FontWeight.w600),
    titleSmall: head(body.titleSmall, FontWeight.w500),
    labelLarge: head(body.labelLarge, FontWeight.w500),
  );
}

/// Digits of equal width, so times line up in a column.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildTheme() {
  final text = buildTextTheme();
  const scheme = ColorScheme.light(
    primary: Palette.ink,
    onPrimary: Colors.white,
    secondary: Palette.pole,
    onSecondary: Colors.white,
    surface: Palette.paper,
    onSurface: Palette.ink,
    error: Palette.pole,
    onError: Colors.white,
    outline: Palette.rule,
  );

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.paper,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Palette.ink,
      unselectedLabelColor: Palette.steel,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge,
      indicatorColor: Palette.pole,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Palette.rule,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Palette.rule,
        disabledForegroundColor: Palette.steel,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: text.labelLarge?.copyWith(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.ink,
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border(Palette.rule),
      enabledBorder: border(Palette.rule),
      focusedBorder: border(Palette.ink, 1.5),
      errorBorder: border(Palette.pole),
      focusedErrorBorder: border(Palette.pole, 1.5),
      labelStyle: const TextStyle(color: Palette.steel),
    ),
    dividerTheme: const DividerThemeData(
      color: Palette.rule,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
  );
}
