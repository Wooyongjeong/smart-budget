import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_history_screen.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

import 'localized_test_app.dart';

class _Repository implements TransactionRepository {
  final calls =
      <({DateTime start, DateTime end, TransactionQueryCursor? cursor})>[];
  String? memberId;
  String? paymentMethodId;
  String? category;

  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash')],
    members: [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<TransactionQueryResult> query(
    String householdId,
    DateTime start,
    DateTime end, {
    String? memberId,
    String? paymentMethodId,
    String? category,
    TransactionQueryCursor? cursor,
    int limit = 50,
  }) async {
    calls.add((start: start, end: end, cursor: cursor));
    this.memberId = memberId;
    this.paymentMethodId = paymentMethodId;
    this.category = category;
    if (cursor != null) {
      return TransactionQueryResult(
        items: [
          {
            'id': 'transaction',
            'kind': 'expense',
            'occurred_on': '2026-09-22',
            'amount_won': 12000,
            'merchant': '동네 마트',
          },
          {
            'id': 'next',
            'kind': 'expense',
            'occurred_on': '2026-09-21',
            'amount_won': 3000,
            'merchant': '편의점',
          },
        ],
        totalIncome: 0,
        totalExpense: 0,
      );
    }
    return TransactionQueryResult(
      items: [
        {
          'id': 'transaction',
          'kind': 'expense',
          'occurred_on': '2026-09-22',
          'created_at': '2026-09-22T09:00:00Z',
          'amount_won': 12000,
          'merchant': '동네 마트',
        },
      ],
      totalIncome: 0,
      totalExpense: 12000,
      nextCursor: const TransactionQueryCursor(
        date: '2026-09-22',
        createdAt: '2026-09-22T09:00:00Z',
        id: 'transaction',
      ),
    );
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
  Future<void> edit(
    String h,
    String id,
    int version,
    TransactionDraft d, {
    String? requestId,
  }) async {}
  @override
  Future<void> voidTransaction(
    String id,
    int version, {
    String? requestId,
  }) async {}
  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String h,
    String k,
    String n,
    String? o,
  ) async => PaymentMethodOption(id: 'new', name: n, kind: k);
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
}

void main() {
  testWidgets('history changes period and loads the next page', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      localizedTestApp(
        home: TransactionHistoryScreen(
          repository: repository,
          initialDate: DateTime(2026, 9, 22),
          onTransactionTap: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('동네 마트'), findsOneWidget);
    expect(find.text('−12,000원'), findsOneWidget);
    expect(repository.calls.single.start, DateTime(2026, 9, 1));
    await tester.tap(find.byTooltip('다음 기간'));
    await tester.pumpAndSettle();
    expect(repository.calls.last.start, DateTime(2026, 10, 1));

    await tester.tap(find.text('더 보기'));
    await tester.pumpAndSettle();
    expect(repository.calls.last.cursor, isNotNull);
    expect(find.text('동네 마트'), findsOneWidget);
    expect(find.text('편의점'), findsOneWidget);
  });
}
