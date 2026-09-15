import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/payment_methods/payment_methods_screen.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

class _Repository implements TransactionRepository {
  final methods = <PaymentMethodOption>[];
  int target = 0;
  int voucherAmount = 0;

  @override
  Future<HouseholdContext> loadContext() async => HouseholdContext(
    householdId: 'household',
    paymentMethods: methods,
    members: const [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String h,
    String kind,
    String name,
    String? owner,
  ) async {
    final method = PaymentMethodOption(
      id: 'new',
      name: name,
      kind: kind,
      ownerMemberId: owner,
    );
    methods.add(method);
    return method;
  }

  @override
  Future<void> archivePaymentMethod(String h, String id) async =>
      methods.removeWhere((method) => method.id == id);
  @override
  Future<void> recordVoucherEvent(
    String h,
    String k,
    String v,
    int p,
    int a,
  ) async {
    voucherAmount += k == 'voucher_use' ? -a : a;
  }

  @override
  Future<List<Map<String, dynamic>>> cardPerformance(
    String h,
    DateTime m,
  ) async => methods
      .where(
        (method) => method.kind == 'credit_card' || method.kind == 'debit_card',
      )
      .map(
        (method) => <String, dynamic>{
          'payment_method_id': method.id,
          'actual_amount_won': 120000,
          'target_amount_won': target,
        },
      )
      .toList();
  @override
  Future<void> setCardTarget(String h, String p, DateTime m, int a) async {
    target = a;
  }

  @override
  Future<int> voucherBalance(String h, String v) async => voucherAmount;
  @override
  Future<void> save(String h, TransactionDraft d) async {}
  @override
  Future<void> saveMany(String h, List<TransactionDraft> d) async {}
  @override
  Future<TransactionQueryResult> query(
    String h,
    DateTime s,
    DateTime e,
  ) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
}

void main() {
  testWidgets('registers a payment method from the management screen', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    expect(find.text('등록된 결제 수단이 없어요.'), findsOneWidget);
    await tester.tap(find.text('첫 수단 등록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '생활비 현금');
    await tester.tap(find.text('등록').last);
    await tester.pumpAndSettle();
    expect(find.text('생활비 현금'), findsOneWidget);
  });

  testWidgets('updates a card target and refreshes the summary', (
    tester,
  ) async {
    final repository = _Repository();
    repository.methods.add(
      const PaymentMethodOption(id: 'card', name: '생활 카드', kind: 'credit_card'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('목표 0원'), findsOneWidget);
    await tester.tap(find.byTooltip('실적 목표 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300000');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '300,000',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.textContaining('목표 300000원'), findsOneWidget);
  });

  testWidgets('refreshes a voucher balance after use', (tester) async {
    final repository = _Repository()..voucherAmount = 100000;
    repository.methods.add(
      const PaymentMethodOption(id: 'voucher', name: '온누리', kind: 'voucher'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('잔액 100000원'), findsOneWidget);
    await tester.tap(find.byTooltip('사용'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('잔액 80000원'), findsOneWidget);
  });
}
