import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/main.dart';
import 'package:smart_budget/themes.dart';
import 'package:smart_budget/features/household/household_repository.dart';
import 'package:smart_budget/features/household/household_screen.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'localized_test_app.dart';

class _HouseholdRepository implements HouseholdRepository {
  _HouseholdRepository(this.displayName);

  String displayName;

  @override
  Future<String> loadCurrentDisplayName() async => displayName;

  @override
  Future<HouseholdOverview> load() async => HouseholdOverview(
    id: 'household',
    name: '우리 가계부',
    members: [HouseholdMember(id: 'member', name: displayName, isMe: true)],
  );

  @override
  Future<String> updateDisplayName(String name) async {
    displayName = name.trim();
    return displayName;
  }

  @override
  Future<String> createInvitation(String householdId) async => 'a' * 48;

  @override
  Future<String> acceptInvitation(String token) async => 'household';

  @override
  Future<void> leave(String householdId) async {}
}

void main() {
  testWidgets('calendar today button selects today and resets the picker', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    var selectedDate = today;
    await tester.pumpWidget(
      localizedTestApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: CalendarOverview(
              selectedDate: selectedDate,
              result: const TransactionQueryResult(
                items: [],
                totalIncome: 0,
                totalExpense: 0,
              ),
              onDateChanged: (value) {
                setState(() => selectedDate = value);
              },
            ),
          ),
        ),
      ),
    );

    final pickerContext = tester.element(find.byType(CalendarDatePicker));
    final todayMonth = MaterialLocalizations.of(
      pickerContext,
    ).formatMonthYear(today);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text(todayMonth), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar-today')));
    await tester.pumpAndSettle();

    expect(selectedDate, today);
    expect(find.text(todayMonth), findsOneWidget);
    expect(
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .initialDate,
      selectedDate,
    );
  });

  testWidgets('profile avatar uses the saved display name initial', (
    tester,
  ) async {
    await tester.pumpWidget(
      BudgetApp(
        saveTheme: (_) async {},
        householdRepository: _HouseholdRepository('민지'),
      ),
    );
    await tester.pumpAndSettle();

    final avatar = find.byKey(const ValueKey('profile-avatar'));
    expect(
      find.descendant(of: avatar, matching: find.text('민')),
      findsOneWidget,
    );
    expect(find.text('우'), findsNothing);
  });

  testWidgets(
    'editing the household name updates the avatar without an error',
    (tester) async {
      final repository = _HouseholdRepository('나');
      await tester.pumpWidget(
        localizedTestApp(
          home: BudgetApp(
            saveTheme: (_) async {},
            householdRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('공동 가계부'), 300);
      await tester.drag(find.byType(ListView).last, const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '공동 가계부'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('edit-display-name')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '테스트계정입니다');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.text('테스트계정입니다'), findsOneWidget);
      expect(find.text('공동 가계부 작업을 완료하지 못했어요. 다시 시도해 주세요.'), findsNothing);
      Navigator.of(tester.element(find.byType(HouseholdScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('캘린더'));
      await tester.pumpAndSettle();
      final avatar = find.byKey(const ValueKey('profile-avatar'));
      expect(
        find.descendant(of: avatar, matching: find.text('테')),
        findsOneWidget,
      );
    },
  );

  testWidgets('new theme choices can be selected and saved', (tester) async {
    String? saved;
    await tester.pumpWidget(BudgetApp(saveTheme: (id) async => saved = id));
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('자두와 살구'), 250);
    await tester.tap(find.text('자두와 살구'));
    await tester.pumpAndSettle();
    expect(saved, 'plum');
    expect(find.text('맑은 하늘'), findsOneWidget);
  });

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
    expect(find.byType(ChoiceChip), findsNWidgets(palettes.length));
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((chip) => chip.showCheckmark == false),
      isTrue,
    );
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

  testWidgets('sign out requires confirmation and calls the session callback', (
    tester,
  ) async {
    var signOutCount = 0;
    await tester.pumpWidget(
      BudgetApp(saveTheme: (_) async {}, onSignOut: () async => signOutCount++),
    );
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    final signOut = find.byKey(const ValueKey('sign-out'));
    await tester.scrollUntilVisible(signOut, 300);

    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.text('로그아웃할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(signOutCount, 0);

    await tester.tap(signOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(signOutCount, 1);
  });

  testWidgets('a failed sign out keeps the app open and shows an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      BudgetApp(
        saveTheme: (_) async {},
        onSignOut: () async => throw Exception('network'),
      ),
    );
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    final signOut = find.byKey(const ValueKey('sign-out'));
    await tester.scrollUntilVisible(signOut, 300);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();

    expect(find.text('로그아웃하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
