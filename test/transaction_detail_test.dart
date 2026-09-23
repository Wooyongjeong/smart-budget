import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_budget/features/transactions/transaction_detail_screen.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

import 'localized_test_app.dart';

class _Repository implements TransactionRepository {
  bool edited = false;
  bool voided = false;
  String? editRequestId;

  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash')],
    members: [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<void> edit(
    String householdId,
    String transactionId,
    int expectedVersion,
    TransactionDraft draft, {
    String? requestId,
  }) async {
    edited = true;
    editRequestId = requestId;
  }

  @override
  Future<void> voidTransaction(
    String transactionId,
    int expectedVersion, {
    String? requestId,
  }) async {
    voided = true;
  }

  @override
  Future<void> save(String h, TransactionDraft d) async {}
  @override
  Future<PaymentMethodOption> addVoucher(
    String h,
    String name,
    String? owner,
    int paid,
    int amount,
    String? source,
  ) => throw UnimplementedError();

  @override
  Future<void> saveMany(
    String h,
    List<TransactionDraft> d, {
    String? requestId,
  }) async {}

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String h,
    String kind,
    String name,
    String? owner,
  ) async => PaymentMethodOption(id: 'new', name: name, kind: kind);

  @override
  Future<void> archivePaymentMethod(String h, String id) async {}

  @override
  Future<void> recordVoucherEvent(
    String h,
    String k,
    String v,
    int p,
    int a,
  ) async {}

  @override
  Future<List<Map<String, dynamic>>> cardPerformance(
    String h,
    DateTime m,
  ) async => [];

  @override
  Future<void> setCardTarget(String h, String p, DateTime m, int a) async {}

  @override
  Future<int> voucherBalance(String h, String v) async => 0;

  @override
  Future<TransactionQueryResult> query(
    String h,
    DateTime s,
    DateTime e, {
    String? memberId,
    String? paymentMethodId,
    String? category,
    TransactionQueryCursor? cursor,
    int limit = 50,
  }) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
}

TransactionRecord _record() => TransactionRecord(
  id: 'transaction',
  kind: 'expense',
  occurredOn: DateTime(2026, 9, 22),
  amountWon: 12000,
  merchant: '동네 마트',
  category: '식비',
  paymentMethodId: 'cash',
  memberId: 'member',
  memo: '장보기',
  version: 3,
);

void main() {
  testWidgets('transaction detail edits a general transaction', (tester) async {
    final repository = _Repository();
    var changed = false;
    await tester.pumpWidget(
      localizedTestApp(
        home: TransactionDetailScreen(
          repository: repository,
          householdId: 'household',
          contextData: await repository.loadContext(),
          transaction: _record(),
          onChanged: () => changed = true,
        ),
      ),
    );

    expect(find.text('동네 마트'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.tap(find.text('거래 수정'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.text('입력 내용 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확정'));
    await tester.pumpAndSettle();

    expect(repository.edited, isTrue);
    expect(repository.editRequestId, isNotNull);
    expect(changed, isTrue);
  });

  testWidgets('transaction detail voids after confirmation', (tester) async {
    final repository = _Repository();
    var changed = false;
    await tester.pumpWidget(
      localizedTestApp(
        home: TransactionDetailScreen(
          repository: repository,
          householdId: 'household',
          contextData: await repository.loadContext(),
          transaction: _record(),
          onChanged: () => changed = true,
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.tap(find.text('거래 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거래 삭제').last);
    await tester.pumpAndSettle();

    expect(repository.voided, isTrue);
    expect(changed, isTrue);
  });
}
