import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/business_date.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'package:smart_budget/main.dart';

class _DelayedRepository extends Fake implements TransactionRepository {
  final requests = <Completer<TransactionQueryResult>>[];
  final cursors = <TransactionQueryCursor?>[];

  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [],
    members: [],
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
  }) {
    final request = Completer<TransactionQueryResult>();
    requests.add(request);
    cursors.add(cursor);
    return request.future;
  }
}

void main() {
  testWidgets('calendar loads every monthly page before displaying rows', (
    tester,
  ) async {
    final repository = _DelayedRepository();
    await tester.pumpWidget(
      BudgetApp(
        saveTheme: (_) async {},
        transactionRepository: repository,
        businessDateProvider: BusinessDateProvider(
          utcNow: () => DateTime.utc(2026, 9, 23),
        ),
      ),
    );
    await tester.pump();
    repository.requests.first.complete(
      TransactionQueryResult(
        items: List.generate(
          50,
          (index) => {
            'id': 'newer-$index',
            'occurred_on': '2026-09-22',
            'kind': 'income',
            'merchant': 'Income $index',
            'amount_won': 2,
          },
        ),
        totalIncome: 100,
        totalExpense: 9300,
        nextCursor: TransactionQueryCursor(
          date: '2026-09-23',
          createdAt: '2026-09-23T00:00:00Z',
          id: 'first',
        ),
      ),
    );
    await tester.pump();
    expect(repository.requests, hasLength(2));
    expect(repository.cursors.last?.id, 'first');
    repository.requests.last.complete(
      TransactionQueryResult(
        items: [
          {
            'id': 'older',
            'occurred_on': '2026-09-01',
            'kind': 'expense',
            'merchant': 'Older transaction',
            'amount_won': 9300,
          },
        ],
        totalIncome: 100,
        totalExpense: 9300,
      ),
    );
    await tester.pump();
    await tester.pump();
    final overview = tester.widget<CalendarOverview>(
      find.byType(CalendarOverview),
    );
    expect(overview.result!.items, hasLength(51));
    expect(overview.result!.items.last['id'], 'older');
    expect(overview.result!.totalIncome, 100);
    expect(overview.result!.totalExpense, 9300);
    expect(overview.result!.nextCursor, isNull);
  });

  testWidgets(
    'late result from an old month query does not enter current cache',
    (tester) async {
      final repository = _DelayedRepository();
      await tester.pumpWidget(
        BudgetApp(
          saveTheme: (_) async {},
          transactionRepository: repository,
          businessDateProvider: BusinessDateProvider(
            utcNow: () => DateTime.utc(2026, 9, 23),
          ),
        ),
      );
      await tester.pump();
      expect(repository.requests, hasLength(1));

      tester
          .widget<CalendarOverview>(find.byType(CalendarOverview))
          .onDateChanged(DateTime(2026, 10, 1));
      await tester.pump();
      expect(repository.requests, hasLength(2));

      tester
          .widget<CalendarOverview>(find.byType(CalendarOverview))
          .onDateChanged(DateTime(2026, 9, 23));
      await tester.pump();
      expect(repository.requests, hasLength(3));

      repository.requests.first.complete(
        const TransactionQueryResult(
          items: [],
          totalIncome: 999,
          totalExpense: 0,
        ),
      );
      await tester.pump();
      tester
          .widget<CalendarOverview>(find.byType(CalendarOverview))
          .onDateChanged(DateTime(2026, 9, 24));
      await tester.pump();
      expect(find.text('999원'), findsNothing);

      repository.requests.last.complete(
        const TransactionQueryResult(
          items: [],
          totalIncome: 100,
          totalExpense: 0,
        ),
      );
      await tester.pump();
      expect(find.text('100원'), findsOneWidget);
    },
  );
}
