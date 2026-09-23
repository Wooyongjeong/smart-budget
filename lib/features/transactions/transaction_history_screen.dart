import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../money_input.dart';
import 'transaction_repository.dart';

enum HistoryPeriod { day, week, month }

class HistoryFilter {
  const HistoryFilter({this.memberId, this.paymentMethodId, this.category});

  final String? memberId;
  final String? paymentMethodId;
  final String? category;

  bool get isEmpty =>
      memberId == null && paymentMethodId == null && category == null;
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({
    super.key,
    required this.repository,
    required this.initialDate,
    required this.onTransactionTap,
  });

  final TransactionRepository repository;
  final DateTime initialDate;
  final ValueChanged<Map<String, dynamic>> onTransactionTap;

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const categories = ['급여', '용돈', '식비', '생활', '교통', '주거', '쇼핑', '기타'];

  late DateTime anchor = DateUtils.dateOnly(widget.initialDate);
  HistoryPeriod period = HistoryPeriod.month;
  HistoryFilter filter = const HistoryFilter();
  HouseholdContext? contextData;
  List<Map<String, dynamic>> items = [];
  TransactionQueryCursor? cursor;
  int totalIncome = 0;
  int totalExpense = 0;
  bool loading = true;
  bool loadingMore = false;
  Object? error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  DateTimeRange _range() {
    return switch (period) {
      HistoryPeriod.day => DateTimeRange(
        start: anchor,
        end: anchor.add(const Duration(days: 1)),
      ),
      HistoryPeriod.week => _weekRange(anchor),
      HistoryPeriod.month => DateTimeRange(
        start: DateTime(anchor.year, anchor.month),
        end: DateTime(anchor.year, anchor.month + 1),
      ),
    };
  }

  DateTimeRange _weekRange(DateTime value) {
    final monday = value.subtract(Duration(days: value.weekday - 1));
    final start = DateUtils.dateOnly(monday);
    return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
  }

  Future<TransactionQueryResult> _query(TransactionQueryCursor? next) {
    final range = _range();
    return widget.repository.query(
      contextData!.householdId,
      range.start,
      range.end,
      memberId: filter.memberId,
      paymentMethodId: filter.paymentMethodId,
      category: filter.category,
      cursor: next,
      limit: 50,
    );
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
        items = [];
        cursor = null;
      });
    }
    try {
      contextData ??= await widget.repository.loadContext();
      final result = await _query(null);
      if (!mounted) return;
      setState(() {
        items = result.items;
        totalIncome = result.totalIncome;
        totalExpense = result.totalExpense;
        cursor = result.nextCursor;
        loading = false;
      });
    } catch (value) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = value;
      });
    }
  }

  Future<void> _loadMore() async {
    final next = cursor;
    if (next == null || loadingMore || contextData == null) return;
    setState(() => loadingMore = true);
    try {
      final result = await _query(next);
      if (!mounted) return;
      setState(() {
        items.addAll(result.items);
        cursor = result.nextCursor;
        loadingMore = false;
      });
    } catch (value) {
      if (!mounted) return;
      setState(() {
        loadingMore = false;
        error = value;
      });
    }
  }

  void _move(int amount) {
    setState(() {
      anchor = switch (period) {
        HistoryPeriod.day => anchor.add(Duration(days: amount)),
        HistoryPeriod.week => anchor.add(Duration(days: amount * 7)),
        HistoryPeriod.month => DateTime(anchor.year, anchor.month + amount, 1),
      };
    });
    _reload();
  }

  String _periodLabel(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return switch (period) {
      HistoryPeriod.day => DateFormat('yyyy-MM-dd').format(anchor),
      HistoryPeriod.week => () {
        final range = _weekRange(anchor);
        return '${DateFormat('MM/dd').format(range.start)} – ${DateFormat('MM/dd').format(range.end.subtract(const Duration(days: 1)))}';
      }(),
      HistoryPeriod.month => localizations.formatMonthYear(
        DateTime(anchor.year, anchor.month),
      ),
    };
  }

  String _periodName(AppLocalizations l10n) => switch (period) {
    HistoryPeriod.day => l10n.historyDay,
    HistoryPeriod.week => l10n.historyWeek,
    HistoryPeriod.month => l10n.historyMonth,
  };

  String _categoryLabel(AppLocalizations l10n, String category) =>
      switch (category) {
        '급여' => l10n.salary,
        '용돈' => l10n.allowance,
        '식비' => l10n.food,
        '생활' => l10n.living,
        '교통' => l10n.transportation,
        '주거' => l10n.housing,
        '쇼핑' => l10n.shopping,
        '기타' => l10n.other,
        _ => category,
      };

  Future<void> _chooseFilter() async {
    final data = contextData;
    if (data == null) return;
    final result = await showModalBottomSheet<HistoryFilter>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var memberId = filter.memberId ?? '';
        var methodId = filter.paymentMethodId ?? '';
        var category = filter.category ?? '';
        final l10n = AppLocalizations.of(sheetContext)!;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.historyFilterTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: InputDecoration(labelText: l10n.actualUser),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l10n.allMembers)),
                    ...data.members.map(
                      (member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => memberId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: methodId,
                  decoration: InputDecoration(labelText: l10n.paymentMethod),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.allPaymentMethods),
                    ),
                    ...data.paymentMethods.map(
                      (method) => DropdownMenuItem(
                        value: method.id,
                        child: Text(method.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => methodId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.allCategories),
                    ),
                    ...categories.map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_categoryLabel(l10n, value)),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => category = value ?? ''),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, const HistoryFilter()),
                      child: Text(l10n.clearFilters),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        sheetContext,
                        HistoryFilter(
                          memberId: memberId.isEmpty ? null : memberId,
                          paymentMethodId: methodId.isEmpty ? null : methodId,
                          category: category.isEmpty ? null : category,
                        ),
                      ),
                      child: Text(l10n.applyFilters),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() => filter = result);
    _reload();
  }

  Widget _transactionTile(
    BuildContext context,
    Map<String, dynamic> item,
    AppLocalizations l10n,
  ) {
    final kind = item['kind'] as String?;
    final amount = (item['amount_won'] as num).toInt();
    final isIncome = kind == 'income';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 19,
        ),
      ),
      title: Text(
        item['merchant'] as String,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${item['occurred_on']} · ${isIncome ? l10n.income : l10n.expense}',
      ),
      trailing: Text(
        '${isIncome ? '+' : '−'}${l10n.formattedAmount(formatWon(amount))}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isIncome
              ? Colors.teal.shade700
              : Theme.of(context).colorScheme.error,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: () => widget.onTransactionTap(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<HistoryPeriod>(
          segments: [
            ButtonSegment(
              value: HistoryPeriod.day,
              label: Text(l10n.historyDay),
            ),
            ButtonSegment(
              value: HistoryPeriod.week,
              label: Text(l10n.historyWeek),
            ),
            ButtonSegment(
              value: HistoryPeriod.month,
              label: Text(l10n.historyMonth),
            ),
          ],
          selected: {period},
          onSelectionChanged: (value) {
            setState(() => period = value.first);
            _reload();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: l10n.previousPeriod,
              onPressed: loading ? null : () => _move(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                _periodLabel(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l10n.nextPeriod,
              onPressed: loading ? null : () => _move(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: l10n.historyFilters,
              onPressed: loading ? null : _chooseFilter,
              icon: Badge(
                isLabelVisible: !filter.isEmpty,
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        if (!filter.isEmpty)
          Wrap(
            spacing: 8,
            children: [
              if (filter.memberId != null)
                InputChip(
                  label: Text(l10n.actualUser),
                  onDeleted: () {
                    setState(
                      () => filter = HistoryFilter(
                        paymentMethodId: filter.paymentMethodId,
                        category: filter.category,
                      ),
                    );
                    _reload();
                  },
                ),
              if (filter.paymentMethodId != null)
                InputChip(
                  label: Text(l10n.paymentMethod),
                  onDeleted: () {
                    setState(
                      () => filter = HistoryFilter(
                        memberId: filter.memberId,
                        category: filter.category,
                      ),
                    );
                    _reload();
                  },
                ),
              if (filter.category != null)
                InputChip(
                  label: Text(_categoryLabel(l10n, filter.category!)),
                  onDeleted: () {
                    setState(
                      () => filter = HistoryFilter(
                        memberId: filter.memberId,
                        paymentMethodId: filter.paymentMethodId,
                      ),
                    );
                    _reload();
                  },
                ),
            ],
          ),
        const SizedBox(height: 12),
        if (loading)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(value: 0.35)),
          )
        else if (error != null && items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(l10n.loadHistoryFailed, textAlign: TextAlign.center),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(l10n.monthIncome(formatWon(totalIncome))),
                  Text(l10n.monthExpense(formatWon(totalExpense))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.historyPeriodEmpty, textAlign: TextAlign.center),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: items
                      .map((item) => _transactionTile(context, item, l10n))
                      .toList(),
                ),
              ),
            ),
          if (cursor != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: loadingMore ? null : _loadMore,
                icon: loadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          value: 0.35,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(l10n.loadMore),
              ),
            )
          else if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(l10n.noMoreTransactions, textAlign: TextAlign.center),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          _periodName(l10n),
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
