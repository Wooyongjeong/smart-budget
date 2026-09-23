import 'package:flutter/material.dart';
import '../../business_date.dart';

@immutable
class CalendarDaySummary {
  const CalendarDaySummary({this.income = 0, this.expense = 0});

  final int income;
  final int expense;

  bool get hasTransactions => income > 0 || expense > 0;
}

class CalendarMonthPicker extends StatefulWidget {
  const CalendarMonthPicker({
    super.key,
    required this.selectedDate,
    required this.summaries,
    required this.onDateChanged,
    this.businessDateProvider = const BusinessDateProvider(),
  });

  final DateTime selectedDate;
  final Map<DateTime, CalendarDaySummary> summaries;
  final ValueChanged<DateTime> onDateChanged;
  final BusinessDateProvider businessDateProvider;

  @override
  State<CalendarMonthPicker> createState() => _CalendarMonthPickerState();
}

class _CalendarMonthPickerState extends State<CalendarMonthPicker> {
  late DateTime displayedMonth = DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
  );

  @override
  void didUpdateWidget(covariant CalendarMonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameMonth(oldWidget.selectedDate, widget.selectedDate)) {
      displayedMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  void _moveMonth(int offset) {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final first = DateTime(displayedMonth.year, displayedMonth.month);
    final gridStart = first.subtract(Duration(days: first.weekday % 7));
    final today = widget.businessDateProvider.today;
    final weekdays = localizations.narrowWeekdays;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: localizations.previousMonthTooltip,
              onPressed: () => _moveMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                localizations.formatMonthYear(displayedMonth),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: localizations.nextMonthTooltip,
              onPressed: () => _moveMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.15,
          children: [
            ...weekdays.map(
              (day) => Center(
                child: Text(day, style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
            ...List.generate(42, (index) {
              final date = DateUtils.dateOnly(
                gridStart.add(Duration(days: index)),
              );
              final summary = widget.summaries[date];
              final inMonth = DateUtils.isSameMonth(date, displayedMonth);
              final selected = DateUtils.isSameDay(date, widget.selectedDate);
              final isToday = DateUtils.isSameDay(date, today);
              final colorScheme = Theme.of(context).colorScheme;
              final incomeLabel = summary != null && summary.income > 0
                  ? ', +${summary.income}'
                  : '';
              final expenseLabel = summary != null && summary.expense > 0
                  ? ', −${summary.expense}'
                  : '';
              return Semantics(
                button: true,
                selected: selected,
                label:
                    '${localizations.formatFullDate(date)}$incomeLabel$expenseLabel',
                child: InkWell(
                  key: ValueKey(
                    'calendar-day-${date.year}-${date.month}-${date.day}',
                  ),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => widget.onDateChanged(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: selected ? colorScheme.primaryContainer : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: colorScheme.primary)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: inMonth
                                ? null
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  ),
                          ),
                        ),
                        if (summary?.hasTransactions == true)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (summary!.income > 0)
                                Text(
                                  '+',
                                  style: TextStyle(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (summary.expense > 0)
                                Text(
                                  '−',
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
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
