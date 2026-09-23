import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../entry_form.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../money_input.dart';
import 'transaction_repository.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.repository,
    required this.householdId,
    required this.contextData,
    required this.transaction,
    required this.onChanged,
  });

  final TransactionRepository repository;
  final String householdId;
  final HouseholdContext contextData;
  final TransactionRecord transaction;
  final VoidCallback onChanged;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool busy = false;

  String _methodName(AppLocalizations l10n) {
    final match = widget.contextData.paymentMethods.where(
      (method) => method.id == widget.transaction.paymentMethodId,
    );
    return match.isEmpty ? l10n.none : match.first.name;
  }

  String _memberName(AppLocalizations l10n) {
    final match = widget.contextData.members.where(
      (member) => member.id == widget.transaction.memberId,
    );
    return match.isEmpty ? l10n.none : match.first.name;
  }

  String _kindLabel(AppLocalizations l10n) => switch (widget.transaction.kind) {
    'income' => l10n.income,
    'expense' => l10n.expense,
    _ => widget.transaction.kind,
  };

  String _errorMessage(Object error, AppLocalizations l10n) {
    if (error is TransactionSaveException && error.code == 'version_conflict') {
      return l10n.transactionVersionConflict;
    }
    return l10n.transactionSaveFailed;
  }

  Future<void> _edit() async {
    if (busy || !widget.transaction.isEditable) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (entryContext) => EntryForm(
          initialDraft: widget.transaction.toDraft(),
          paymentMethods: widget.contextData.paymentMethods,
          members: widget.contextData.members,
          onConfirm: (draft) async {
            try {
              await widget.repository.edit(
                widget.householdId,
                widget.transaction.id,
                widget.transaction.version,
                draft,
              );
              if (entryContext.mounted) {
                Navigator.of(entryContext).pop(true);
              }
            } catch (error) {
              if (entryContext.mounted) {
                ScaffoldMessenger.of(entryContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      _errorMessage(error, AppLocalizations.of(entryContext)!),
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
    if (updated != true || !mounted) return;
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.transactionUpdated)),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _void() async {
    if (busy || !widget.transaction.isEditable) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.voidTransactionTitle),
        content: Text(l10n.voidTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.voidTransaction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.repository.voidTransaction(
        widget.transaction.id,
        widget.transaction.version,
      );
      if (!mounted) return;
      widget.onChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.transactionVoided)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error, l10n))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _row(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Text(value, textAlign: TextAlign.end),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transaction = widget.transaction;
    final amount = l10n.formattedAmount(formatWon(transaction.amountWon));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionDetail)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.merchant,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  _row(l10n.transactionType, _kindLabel(l10n)),
                  _row(
                    l10n.date,
                    DateFormat('yyyy-MM-dd').format(transaction.occurredOn),
                  ),
                  _row(l10n.category, transaction.category ?? l10n.none),
                  _row(l10n.paymentMethod, _methodName(l10n)),
                  _row(l10n.actualUser, _memberName(l10n)),
                  if (transaction.memo.isNotEmpty)
                    _row(l10n.memoOptional, transaction.memo),
                ],
              ),
            ),
          ),
          if (!transaction.isEditable) ...[
            const SizedBox(height: 16),
            Text(
              l10n.transactionReadOnly,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editTransaction),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: busy ? null : _void,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.voidTransaction),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
