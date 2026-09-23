import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/transactions/monthly_summary_card.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';

import 'localized_test_app.dart';

void main() {
  testWidgets('English monthly balance uses the localized currency format', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: MonthlySummaryCard(
            result: const TransactionQueryResult(
              items: [],
              totalIncome: 1200,
              totalExpense: 200,
            ),
            isLoading: false,
            hasError: false,
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('₩1,000'), findsOneWidget);
    expect(find.text('1,000원'), findsNothing);
  });
}
