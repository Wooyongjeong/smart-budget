import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_budget/main.dart';
import 'package:smart_budget/entry_form.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'localized_test_app.dart';

class _Repository implements TransactionRepository {
  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash')],
    members: [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<TransactionQueryResult> query(
    String h,
    DateTime s,
    DateTime e,
  ) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
  @override
  Future<void> save(String h, TransactionDraft d) async {}
  @override
  Future<void> saveMany(String h, List<TransactionDraft> d) async {}
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
    await tester.pumpWidget(
      BudgetApp(saveTheme: (_) async {}, transactionRepository: _Repository()),
    );
    await tester.pumpAndSettle();
    final selected = DateTime(2026, 9, 7);
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
      '2026-09-07',
    );
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
