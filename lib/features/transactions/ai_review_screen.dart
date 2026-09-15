import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_draft.dart';
import 'transaction_repository.dart';
import '../../money_input.dart';
import '../../l10n/generated/app_localizations.dart';

class ReceiptFixtureItem {
  ReceiptFixtureItem({required this.draft, required this.reason})
    : selected = true,
      amount = TextEditingController(
        text: draft.amountWon == null ? '' : formatWon(draft.amountWon!),
      ),
      merchant = TextEditingController(text: draft.merchant),
      date = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(draft.occurredOn),
      );
  final TransactionDraft draft;
  final String reason;
  bool selected;
  final TextEditingController amount;
  final TextEditingController merchant;
  final TextEditingController date;

  TransactionDraft toDraft() => TransactionDraft(
    kind: draft.kind,
    occurredOn: DateFormat('yyyy-MM-dd').parseStrict(date.text.trim()),
    amountWon: parseWon(amount.text),
    merchant: merchant.text.trim(),
    category: draft.category,
    paymentMethodId: draft.paymentMethodId,
    memberId: draft.memberId,
    memo: draft.memo,
  );

  void dispose() {
    amount.dispose();
    merchant.dispose();
    date.dispose();
  }
}

class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({
    super.key,
    required this.repository,
    required this.contextData,
  });
  final TransactionRepository repository;
  final HouseholdContext contextData;

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  late final items = _fixture(AppLocalizations.of(context)!);
  bool saving = false;

  List<ReceiptFixtureItem> _fixture(AppLocalizations l10n) {
    final method = widget.contextData.paymentMethods.isEmpty
        ? null
        : widget.contextData.paymentMethods.first;
    final member = widget.contextData.members.isEmpty
        ? null
        : widget.contextData.members.first;
    return [
      ReceiptFixtureItem(
        draft: TransactionDraft(
          kind: TransactionKind.expense,
          occurredOn: DateTime(2026, 9, 14),
          amountWon: 18500,
          merchant: l10n.fixtureMarket,
          category: '식비',
          paymentMethodId: method?.id,
          memberId: member?.id,
          memo: '',
        ),
        reason: l10n.fixtureReason,
      ),
      ReceiptFixtureItem(
        draft: TransactionDraft(
          kind: TransactionKind.expense,
          occurredOn: DateTime(2026, 9, 13),
          amountWon: 4200,
          merchant: l10n.fixtureCafe,
          category: '식비',
          paymentMethodId: method?.id,
          memberId: member?.id,
          memo: '',
        ),
        reason: l10n.fixtureReason,
      ),
    ];
  }

  @override
  void dispose() {
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final selected = items.where((item) => item.selected).toList();
    if (selected.isEmpty) return;
    setState(() => saving = true);
    try {
      final drafts = selected.map((item) => item.toDraft()).toList();
      if (drafts.any(
        (draft) =>
            draft.amountWon == null ||
            draft.amountWon! <= 0 ||
            draft.merchant.isEmpty,
      )) {
        throw const FormatException();
      }
      await widget.repository.saveMany(widget.contextData.householdId, drafts);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.receiptSaveFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptReview)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.receiptFixtureDescription),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: item.selected,
                      onChanged: saving
                          ? null
                          : (value) =>
                                setState(() => item.selected = value ?? false),
                      title: Text(item.merchant.text),
                      subtitle: Text(item.reason),
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: item.date,
                      decoration: InputDecoration(labelText: l10n.date),
                    ),
                    TextField(
                      controller: item.merchant,
                      decoration: InputDecoration(labelText: l10n.merchant),
                    ),
                    TextField(
                      controller: item.amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [WonInputFormatter()],
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        suffixText: l10n.won,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: saving || !items.any((item) => item.selected)
                ? null
                : save,
            child: Text(
              saving
                  ? l10n.saving
                  : l10n.saveCount(items.where((item) => item.selected).length),
            ),
          ),
        ),
      ),
    );
  }
}
