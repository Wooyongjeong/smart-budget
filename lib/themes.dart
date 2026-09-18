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

  ThemeData get theme {
    const ink = Color(0xff17201e);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: ink,
          secondaryContainer: secondary,
          onSecondaryContainer: ink,
          surface: background,
          onSurface: ink,
          error: const Color(0xffd65a52),
        );
    final radius = BorderRadius.circular(20);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamilyFallback: const ['Apple SD Gothic Neo', 'Noto Sans KR'],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.35,
        ),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 17, height: 1.45),
        bodyMedium: TextStyle(fontSize: 15, height: 1.45),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ).apply(bodyColor: ink, displayColor: ink),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: ink,
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 56),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: primary.withValues(alpha: 0.22)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff1f3f1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Color(0xffd65a52)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xffeef1ef),
        selectedColor: primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerColor: const Color(0xffdfe5e1),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.white.withValues(alpha: 0.86),
        indicatorColor: primary.withValues(alpha: 0.13),
        indicatorShape: const CircleBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : const Color(0xff697570),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: background,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
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
  BudgetPalette(
    'plum',
    '자두와 살구',
    Color(0xff7a416f),
    Color(0xfff0a36b),
    Color(0xfffff8f4),
  ),
  BudgetPalette(
    'sky',
    '맑은 하늘',
    Color(0xff236a8d),
    Color(0xff9bd9e8),
    Color(0xfff4fcff),
  ),
];
