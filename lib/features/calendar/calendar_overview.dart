import 'package:flutter/material.dart';

import '../../business_date.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../money_input.dart';
import 'calendar_summary.dart';
import '../transactions/query_error_state.dart';
import '../transactions/transaction_display.dart';
import '../transactions/transaction_repository.dart';

class CalendarOverview extends StatefulWidget {
  const CalendarOverview({
    super.key,
    required this.selectedDate,
    required this.result,
    required this.onDateChanged,
    this.onTransactionTap,
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasError = false,
    this.hasRefreshError = false,
    this.onRetry,
    this.onRefresh,
    this.businessDateProvider = const BusinessDateProvider(),
  });

  final DateTime selectedDate;
  final TransactionQueryResult? result;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<Map<String, dynamic>>? onTransactionTap;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasError;
  final bool hasRefreshError;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final BusinessDateProvider businessDateProvider;

  @override
  State<CalendarOverview> createState() => _CalendarOverviewState();
}

class _CalendarOverviewState extends State<CalendarOverview> {
  int _pickerRevision = 0;

  void _goToToday() {
    final today = widget.businessDateProvider.today;
    setState(() => _pickerRevision++);
    widget.onDateChanged(today);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.hasError) {
      return QueryErrorState(
        message: l10n.loadHistoryFailed,
        onRetry: widget.onRetry,
      );
    }
    final items =
        widget.result?.items
            .where((item) => item['occurred_on'] == _date(widget.selectedDate))
            .toList() ??
        [];
    final summaries = groupCalendarTransactions(
      widget.result?.items ?? const [],
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onRefresh != null)
              IconButton(
                key: const ValueKey('calendar-refresh'),
                tooltip: l10n.refresh,
                onPressed: widget.isRefreshing || widget.isLoading
                    ? null
                    : widget.onRefresh,
                icon: widget.isRefreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            TextButton.icon(
              key: const ValueKey('calendar-today'),
              onPressed: _goToToday,
              icon: const Icon(Icons.today_outlined, size: 18),
              label: Text(l10n.today),
            ),
          ],
        ),
        if (widget.hasRefreshError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.loadHistoryFailed)),
                TextButton(
                  onPressed: widget.onRefresh,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: CalendarMonthPicker(
            key: ValueKey(_pickerRevision),
            selectedDate: widget.selectedDate,
            summaries: summaries,
            onDateChanged: widget.onDateChanged,
            businessDateProvider: widget.businessDateProvider,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isLoading || widget.result == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(value: 0.35),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noTransactionsForDate),
          )
        else
          Card(
            child: Column(
              children: items.map((item) {
                final isIncome = item['kind'] == 'income';
                final color = isIncome
                    ? Colors.teal.shade700
                    : Theme.of(context).colorScheme.error;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: color,
                      size: 19,
                    ),
                  ),
                  title: Text(
                    localizedMerchantName(l10n, item['merchant'] as String),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(isIncome ? l10n.income : l10n.expense),
                  trailing: Text(
                    '${isIncome ? '+' : '−'}${l10n.formattedAmount(formatWon((item['amount_won'] as num).toInt()))}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  onTap: widget.onTransactionTap == null
                      ? null
                      : () => widget.onTransactionTap!(item),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
