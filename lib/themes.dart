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
  BudgetPalette(
    'terracotta',
    '살구빛 테라코타',
    Color(0xff984c36),
    Color(0xffefbf9e),
    Color(0xfffff8f2),
  ),
  BudgetPalette(
    'lemon',
    '레몬 가든',
    Color(0xff526629),
    Color(0xffead779),
    Color(0xfffffdef),
  ),
  BudgetPalette(
    'mint',
    '민트 소다',
    Color(0xff146b73),
    Color(0xffa9ddd2),
    Color(0xfff1fbfa),
  ),
  BudgetPalette(
    'cocoa',
    '코코아 라떼',
    Color(0xff6c4c40),
    Color(0xffd6b99b),
    Color(0xfffaf5ef),
  ),
  BudgetPalette(
    'indigo',
    '인디고 구름',
    Color(0xff414f89),
    Color(0xffbfcbee),
    Color(0xfff5f6fd),
  ),
];
