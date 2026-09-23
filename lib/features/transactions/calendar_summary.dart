import 'package:flutter/foundation.dart';

@immutable
class CalendarDaySummary {
  const CalendarDaySummary({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  bool get hasTransactions => income > 0 || expense > 0;
}

/// Groups transaction rows by calendar day for the month view.
Map<DateTime, CalendarDaySummary> groupCalendarTransactions(
  Iterable<Map<String, dynamic>> items,
) {
  final grouped = <DateTime, CalendarDaySummary>{};
  for (final item in items) {
    final rawDate = item['occurred_on'];
    final rawAmount = item['amount_won'];
    if (rawDate is! String || rawAmount is! num) continue;
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) continue;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final previous = grouped[day] ?? const CalendarDaySummary();
    final amount = rawAmount.toInt();
    if (item['kind'] == 'income') {
      grouped[day] = CalendarDaySummary(
        income: previous.income + amount,
        expense: previous.expense,
      );
    } else if (item['kind'] == 'expense') {
      grouped[day] = CalendarDaySummary(
        income: previous.income,
        expense: previous.expense + amount,
      );
    }
  }
  return grouped;
}
