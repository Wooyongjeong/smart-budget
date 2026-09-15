import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/main.dart';
import 'package:smart_budget/themes.dart';

void main() {
  testWidgets('language selection switches labels and persists', (
    tester,
  ) async {
    String? savedLocale;
    await tester.pumpWidget(
      BudgetApp(
        saveTheme: (_) async {},
        saveLocale: (code) async => savedLocale = code,
      ),
    );
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('영어'), 300);
    await tester.tap(find.text('영어'));
    await tester.pumpAndSettle();
    expect(savedLocale, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      BudgetApp(initialLocale: savedLocale, saveTheme: (_) async {}),
    );
    expect(find.text('Calendar'), findsOneWidget);
  });

  testWidgets('theme selection persists and updates all tabs', (tester) async {
    String? saved;
    await tester.pumpWidget(
      BudgetApp(
        saveTheme: (id) async {
          saved = id;
        },
      ),
    );
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('바다와 모래'));
    await tester.pumpAndSettle();
    expect(saved, 'ocean');
    await tester.tap(find.text('지갑'));
    await tester.pumpAndSettle();
    expect(find.text('결제 수단을 한곳에'), findsOneWidget);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .colorScheme
          .primary,
      palettes[1].primary,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      BudgetApp(initialTheme: saved, saveTheme: (_) async {}),
    );
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .colorScheme
          .primary,
      palettes[1].primary,
    );
  });

  testWidgets(
    'unsupported theme falls back and save failure restores previous selection',
    (tester) async {
      await tester.pumpWidget(
        BudgetApp(
          initialTheme: 'unknown',
          saveTheme: (_) async {
            throw Exception('disk');
          },
        ),
      );
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        palettes.first.primary,
      );
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('바다와 모래'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
        palettes.first.primary,
      );
      expect(find.text('테마를 저장하지 못했어요. 다시 선택해 주세요.'), findsOneWidget);
    },
  );

  testWidgets('small display and large text keep settings scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(BudgetApp(saveTheme: (_) async {}));
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('모노 올리브'), 200);
    expect(tester.takeException(), isNull);
  });
}
