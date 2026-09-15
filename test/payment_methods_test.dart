import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/payment_methods/payment_methods_screen.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

class _Repository implements TransactionRepository {
  final methods = <PaymentMethodOption>[];

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
  Future<void> recordVoucherEvent(String h, String k, String v, int a) async {}
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
}
