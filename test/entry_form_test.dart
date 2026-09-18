import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_budget/main.dart';
import 'package:smart_budget/entry_form.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'localized_test_app.dart';

class _Repository implements TransactionRepository {
  DateTime? lastQueryStart;

  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash')],
    members: [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<TransactionQueryResult> query(String h, DateTime s, DateTime e) async {
    lastQueryStart = s;
    return const TransactionQueryResult(
      items: [],
      totalIncome: 0,
      totalExpense: 0,
    );
  }

  @override
  Future<void> save(String h, TransactionDraft d) async {}
  @override
  Future<void> saveMany(
    String h,
    List<TransactionDraft> d, {
    String? requestId,
  }) async {}
  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String h,
    String k,
    String n,
    String? o,
  ) => throw UnimplementedError();
  @override
  Future<void> archivePaymentMethod(String h, String id) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> cardPerformance(String h, DateTime m) =>
      throw UnimplementedError();
  @override
  Future<void> setCardTarget(String h, String p, DateTime m, int a) =>
      throw UnimplementedError();
  @override
  Future<int> voucherBalance(String h, String v) => throw UnimplementedError();
  @override
  Future<void> recordVoucherEvent(String h, String k, String v, int p, int a) =>
      throw UnimplementedError();
}

Future<void> openForm(WidgetTester tester) async {
  await tester.pumpWidget(
    BudgetApp(
      saveTheme: (_) async {},
      entryPaymentMethods: const [
        PaymentMethodOption(
          id: '11111111-1111-4111-8111-111111111111',
          name: '현금',
          kind: 'cash',
        ),
      ],
      entryMembers: const [
        MemberOption(id: '22222222-2222-4222-8222-222222222222', name: '나'),
      ],
    ),
  );
  await tester.tap(find.text('기록하기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('직접 입력'));
  await tester.pumpAndSettle();
}

Future<void> preview(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('입력 내용 확인'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('입력 내용 확인'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('입력 내용 확인'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('income accepts only cash and bank payment methods', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: EntryForm(
          paymentMethods: const [
            PaymentMethodOption(id: 'card', name: '카드', kind: 'credit_card'),
            PaymentMethodOption(id: 'voucher', name: '상품권', kind: 'voucher'),
            PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash'),
            PaymentMethodOption(id: 'bank', name: '계좌', kind: 'bank'),
          ],
        ),
      ),
    );
    final expenseDropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const ValueKey('payment-false')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(expenseDropdown.items!.map((item) => item.value), [
      'card',
      'cash',
      'bank',
    ]);

    await tester.tap(find.text('수입'));
    await tester.pumpAndSettle();
    final incomeDropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const ValueKey('payment-true')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(incomeDropdown.items!.map((item) => item.value), ['cash', 'bank']);
    final incomeField = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const ValueKey('payment-true')),
    );
    expect(incomeField.initialValue, 'cash');
  });

  testWidgets('English locale translates entry fields and date picker', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        home: EntryForm(initialDate: DateTime(2026, 9, 15)),
      ),
    );
    expect(find.text('Manual entry'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    await tester.tap(find.byTooltip('Choose date'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Select'), findsOneWidget);
  });

  testWidgets('calendar selection becomes the direct-entry date', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      BudgetApp(saveTheme: (_) async {}, transactionRepository: repository),
    );
    await tester.pumpAndSettle();
    final selected = DateTime(2025, 2, 7);
    tester
        .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
        .onDateChanged(selected);
    await tester.pump();
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('date')))
          .controller!
          .text,
      '2025-02-07',
    );
    expect(repository.lastQueryStart, DateTime(2025, 2));
  });

  testWidgets('date calendar button updates the direct-entry date', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: EntryForm(
          initialDate: DateTime(2026, 9, 15),
          paymentMethods: const [
            PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash'),
          ],
        ),
      ),
    );
    await tester.tap(find.byTooltip('날짜 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    expect(find.text('오늘'), findsOneWidget);
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('date')))
          .controller!
          .text,
      '2026-09-20',
    );
  });

  testWidgets('today button moves the date picker to today', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(home: EntryForm(initialDate: DateTime(2020, 1, 1))),
    );
    await tester.tap(find.byTooltip('날짜 선택'));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.text('오늘'), matching: find.byType(FilledButton)),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.today_outlined), findsOneWidget);
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('date')))
          .controller!
          .text,
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  });

  testWidgets('today button returns the calendar view after month navigation', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      localizedTestApp(home: EntryForm(initialDate: today)),
    );
    await tester.tap(find.byTooltip('날짜 선택'));
    await tester.pumpAndSettle();

    final pickerContext = tester.element(find.byType(CalendarDatePicker));
    final todayMonth = MaterialLocalizations.of(
      pickerContext,
    ).formatMonthYear(today);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text(todayMonth), findsNothing);

    await tester.tap(find.text('오늘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(
      tester
          .widget<SlideTransition>(
            find.byKey(const Key('today-calendar-slide')),
          )
          .position
          .value
          .dx,
      isNot(0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text(todayMonth), findsOneWidget);
  });

  testWidgets('invalid amount does not create a preview', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('merchant')), '마트');
    for (final amount in ['0', '-10', '1.5', '1000000000']) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('amount')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(const Key('amount')), amount);
      await preview(tester);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('amount')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('1~999,999,999원의 정수를 입력해 주세요.'), findsOneWidget);
    }
  });

  testWidgets(
    'income preview retains edits and closing requires discard confirmation',
    (tester) async {
      await openForm(tester);
      await tester.tap(find.text('수입'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amount')), '3000000');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('amount')))
            .controller!
            .text,
        '3,000,000',
      );
      await tester.enterText(find.byKey(const Key('merchant')), '월급');
      await preview(tester);
      expect(find.textContaining('수입 · 3,000,000원'), findsOneWidget);
      expect(find.textContaining('급여 · 현금 · 나'), findsOneWidget);
      await tester.tap(find.text('돌아가서 수정'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계속 작성'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('merchant')))
            .controller!
            .text,
        '월급',
      );
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('버리기'));
      await tester.pumpAndSettle();
      expect(find.text('함께 기록하는 하루'), findsOneWidget);
    },
  );

  testWidgets('entry is scrollable at small size and double text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openForm(tester);
    await preview(tester);
    expect(tester.takeException(), isNull);
  });
}
