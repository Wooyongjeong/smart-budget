import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../money_input.dart';
import 'query_error_state.dart';
import 'transaction_repository.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({
    super.key,
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final TransactionQueryResult? result;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (hasError) {
      return QueryErrorState(message: l10n.loadHistoryFailed, onRetry: onRetry);
    }
    if (isLoading || result == null) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator(value: 0.35)),
      );
    }
    final data = result!;
    final primary = Theme.of(context).colorScheme.primary;
    final expense = data.totalExpense;
    final income = data.totalIncome;
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.34)!],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.remainingBalance,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            '${formatWon(balance)}원',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.monthIncome(formatWon(income)),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                l10n.monthExpense(formatWon(expense)),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
