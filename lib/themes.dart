import 'package:flutter/material.dart';

class BudgetPalette {
  const BudgetPalette(
    this.id,
    this.name,
    this.primary,
    this.secondary,
    this.background,
  );
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;

  ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: const Color(0xff202520),
      secondaryContainer: secondary,
      onSecondaryContainer: const Color(0xff202520),
      surface: background,
      onSurface: const Color(0xff202520),
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: primary,
    ),
  );
}

const palettes = [
  BudgetPalette(
    'forest',
    '숲과 크림',
    Color(0xff286859),
    Color(0xffd8b477),
    Color(0xfffaf7f0),
  ),
  BudgetPalette(
    'ocean',
    '바다와 모래',
    Color(0xff285f88),
    Color(0xffdcc39c),
    Color(0xfff5f8fb),
  ),
  BudgetPalette(
    'lavender',
    '라벤더 밀크',
    Color(0xff69518b),
    Color(0xffd9bdd1),
    Color(0xfffaf7fc),
  ),
  BudgetPalette(
    'rose',
    '로즈 티',
    Color(0xff914f63),
    Color(0xffdbc4a0),
    Color(0xfffcf7f5),
  ),
  BudgetPalette(
    'olive',
    '모노 올리브',
    Color(0xff4f5e42),
    Color(0xffc7c0ae),
    Color(0xfff7f7f2),
  ),
];
