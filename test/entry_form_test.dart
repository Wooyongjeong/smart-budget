import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/main.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

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
  testWidgets('invalid amount and impossible date do not create a preview', (
    tester,
  ) async {
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('date')), '2026-02-30');
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('amount')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('amount')), '93000');
    await preview(tester);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('date')),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('2000~2100년 사이의 실제 날짜를 입력해 주세요.'), findsOneWidget);
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
