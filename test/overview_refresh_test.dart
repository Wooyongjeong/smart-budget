import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/business_date.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'package:smart_budget/main.dart';

class _DelayedRepository extends Fake implements TransactionRepository {
  final requests = <Completer<TransactionQueryResult>>[];

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
    return request.future;
  }
}

void main() {
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
