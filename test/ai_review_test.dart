import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_budget/features/transactions/ai_review_screen.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';

class FakeRepository implements TransactionRepository {
  int savedCount = 0;
  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [
      PaymentMethodOption(id: 'method', name: '현금', kind: 'cash'),
    ],
    members: [MemberOption(id: 'member', name: '나')],
  );
  @override
  Future<void> save(String householdId, TransactionDraft draft) async {}
  @override
  Future<void> saveMany(
    String householdId,
    List<TransactionDraft> drafts,
  ) async {
    savedCount = drafts.length;
  }

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String householdId,
    String kind,
    String name,
    String? ownerMemberId,
  ) async => PaymentMethodOption(
    id: 'new-method',
    name: name,
    kind: kind,
    ownerMemberId: ownerMemberId,
  );

  @override
  Future<void> archivePaymentMethod(
    String householdId,
    String paymentMethodId,
  ) async {}
  @override
  Future<void> recordVoucherEvent(String h, String k, String v, int a) async {}

  @override
  Future<TransactionQueryResult> query(
    String householdId,
    DateTime start,
    DateTime end,
  ) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
}

void main() {
  testWidgets('fixture items can be deselected and saved in one batch', (
    tester,
  ) async {
    final repository = FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AiReviewScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    expect(find.text('2건 저장'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1건 저장'), findsOneWidget);
    await tester.tap(find.text('1건 저장'));
    await tester.pumpAndSettle();
    expect(repository.savedCount, 1);
  });
}
