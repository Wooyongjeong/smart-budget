import 'package:flutter/material.dart';

import '../transactions/transaction_repository.dart';
import '../../money_input.dart';
import '../../l10n/generated/app_localizations.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({
    super.key,
    required this.repository,
    required this.contextData,
    this.onReturnToEntry,
    this.embedded = false,
  });

  final TransactionRepository repository;
  final HouseholdContext contextData;
  final VoidCallback? onReturnToEntry;
  final bool embedded;

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late final List<PaymentMethodOption> methods = [
    ...widget.contextData.paymentMethods,
  ];
  late Future<List<Map<String, dynamic>>> cardSummary = _loadCardSummary();
  bool saving = false;

  Future<List<Map<String, dynamic>>> _loadCardSummary() => widget.repository
      .cardPerformance(widget.contextData.householdId, DateTime.now());

  void refreshCardSummary() {
    setState(() {
      cardSummary = _loadCardSummary();
    });
  }

  String kindLabel(BuildContext context, String kind) {
    final l10n = AppLocalizations.of(context)!;
    return switch (kind) {
      'cash' => l10n.cash,
      'bank' => l10n.bank,
      'debit_card' => l10n.debitCard,
      'credit_card' => l10n.creditCard,
      'voucher' => l10n.voucher,
      _ => kind,
    };
  }

  Future<void> add({String initialKind = 'cash'}) async {
    final result = await showDialog<_PaymentMethodDraft>(
      context: context,
      builder: (context) => _PaymentMethodDialog(
        members: widget.contextData.members,
        initialKind: initialKind,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => saving = true);
    try {
      final method = await widget.repository.addPaymentMethod(
        widget.contextData.householdId,
        result.kind,
        result.name,
        result.ownerMemberId,
      );
      if (result.kind == 'voucher' && result.paidAmountWon != null) {
        await widget.repository.recordVoucherEvent(
          widget.contextData.householdId,
          'voucher_topup',
          method.id,
          result.paidAmountWon!,
          result.voucherAmountWon!,
        );
      }
      if ((result.kind == 'debit_card' || result.kind == 'credit_card') &&
          result.targetAmountWon != null) {
        await widget.repository.setCardTarget(
          widget.contextData.householdId,
          method.id,
          DateTime.now(),
          result.targetAmountWon!,
        );
        cardSummary = _loadCardSummary();
      }
      if (!mounted) return;
      setState(() => methods.add(method));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.paymentAdded)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.paymentAddFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> archive(PaymentMethodOption method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.archivePaymentTitle),
        content: Text(
          AppLocalizations.of(context)!.archivePaymentBody(method.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.archive),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.archivePaymentMethod(
        widget.contextData.householdId,
        method.id,
      );
      if (mounted) {
        setState(() => methods.removeWhere((item) => item.id == method.id));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.archivePaymentFailed),
          ),
        );
      }
    }
  }

  Future<void> voucherEvent(PaymentMethodOption method, String kind) async {
    final controller = TextEditingController();
    final voucherController = TextEditingController();
    final amounts = await showDialog<List<int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          kind == 'voucher_use'
              ? AppLocalizations.of(context)!.voucherUse
              : AppLocalizations.of(context)!.voucherTopUp,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: const [WonInputFormatter()],
              decoration: InputDecoration(
                labelText: kind == 'voucher_topup'
                    ? AppLocalizations.of(context)!.actualPaidAmount
                    : AppLocalizations.of(context)!.useAmount,
                suffixText: AppLocalizations.of(context)!.won,
              ),
            ),
            if (kind == 'voucher_topup')
              TextField(
                controller: voucherController,
                keyboardType: TextInputType.number,
                inputFormatters: const [WonInputFormatter()],
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.voucherTopUpAmount,
                  suffixText: AppLocalizations.of(context)!.won,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final paid = parseWon(controller.text);
              final voucher = parseWon(voucherController.text);
              if (paid != null &&
                  paid > 0 &&
                  (kind != 'voucher_topup' ||
                      (voucher != null && voucher > 0))) {
                Navigator.pop(context, [paid, voucher ?? paid]);
              }
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      voucherController.dispose();
    });
    if (amounts == null || !mounted) return;
    try {
      await widget.repository.recordVoucherEvent(
        widget.contextData.householdId,
        kind,
        method.id,
        amounts[0],
        amounts[1],
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.voucherRecorded),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.voucherSaveFailed),
          ),
        );
      }
    }
  }

  Future<void> editTarget(PaymentMethodOption method) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editTargetTitle(method.name)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: const [WonInputFormatter()],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.monthlyTarget,
            suffixText: AppLocalizations.of(context)!.won,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, parseWon(controller.text)),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (value == null || value <= 0 || !mounted) return;
    try {
      await widget.repository.setCardTarget(
        widget.contextData.householdId,
        method.id,
        DateTime.now(),
        value,
      );
      if (mounted) refreshCardSummary();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.targetSaveFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.paymentMethods,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(l10n.paymentMethodsDescription),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: saving ? null : () => add(initialKind: 'voucher'),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: Text(l10n.registerVoucher),
              ),
              FilledButton.icon(
                onPressed: saving ? null : add,
                icon: const Icon(Icons.add),
                label: Text(l10n.registerPaymentMethod),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (methods.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(l10n.noPaymentMethods),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: saving ? null : add,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.registerFirstMethod),
                  ),
                ],
              ),
            ),
          )
        else
          ...methods.map(
            (method) => Card(
              child: ListTile(
                leading: Icon(_iconFor(method.kind)),
                title: Text(method.name),
                subtitle:
                    method.kind == 'debit_card' || method.kind == 'credit_card'
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                        future: cardSummary,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              '${kindLabel(context, method.kind)}${_ownerLabel(context, method)}\n${l10n.performanceLoadFailed}',
                            );
                          }
                          final row = snapshot.data?.firstWhere(
                            (item) => item['payment_method_id'] == method.id,
                            orElse: () => <String, dynamic>{},
                          );
                          return Text(
                            '${kindLabel(context, method.kind)}${_ownerLabel(context, method)}\n${l10n.cardProgress(formatWon((row?['actual_amount_won'] as num?)?.toInt() ?? 0), formatWon((row?['target_amount_won'] as num?)?.toInt() ?? 0))}',
                          );
                        },
                      )
                    : method.kind == 'voucher'
                    ? FutureBuilder<int>(
                        future: widget.repository.voucherBalance(
                          widget.contextData.householdId,
                          method.id,
                        ),
                        builder: (context, snapshot) => Text(
                          '${kindLabel(context, method.kind)}${_ownerLabel(context, method)}\n${l10n.balance(formatWon(snapshot.data ?? 0))}',
                        ),
                      )
                    : Text(
                        '${kindLabel(context, method.kind)}${_ownerLabel(context, method)}',
                      ),
                trailing: method.kind == 'voucher'
                    ? Wrap(
                        children: [
                          IconButton(
                            tooltip: l10n.initialBalanceTopUp,
                            onPressed: () =>
                                voucherEvent(method, 'voucher_topup'),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          IconButton(
                            tooltip: l10n.use,
                            onPressed: () =>
                                voucherEvent(method, 'voucher_use'),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (_) => archive(method),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(l10n.archive),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Wrap(
                        children: [
                          if (method.kind == 'debit_card' ||
                              method.kind == 'credit_card')
                            IconButton(
                              tooltip: l10n.editTarget,
                              onPressed: () => editTarget(method),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (_) => archive(method),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(l10n.archive),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        if (widget.onReturnToEntry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onReturnToEntry,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.backToEntry),
          ),
        ],
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethodManagement)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saving ? null : add,
        icon: const Icon(Icons.add),
        label: Text(l10n.register),
      ),
      body: content,
    );
  }

  String _ownerLabel(BuildContext context, PaymentMethodOption method) {
    final id = method.ownerMemberId;
    if (id == null) return '';
    final member = widget.contextData.members.where((item) => item.id == id);
    return member.isEmpty
        ? ''
        : AppLocalizations.of(context)!.usedBy(member.first.name);
  }

  IconData _iconFor(String kind) => switch (kind) {
    'cash' => Icons.payments_outlined,
    'bank' => Icons.account_balance_outlined,
    'debit_card' || 'credit_card' => Icons.credit_card_outlined,
    _ => Icons.wallet_outlined,
  };
}

class _PaymentMethodDraft {
  const _PaymentMethodDraft(
    this.kind,
    this.name,
    this.ownerMemberId, {
    this.paidAmountWon,
    this.voucherAmountWon,
    this.targetAmountWon,
  });
  final String kind;
  final String name;
  final String? ownerMemberId;
  final int? paidAmountWon;
  final int? voucherAmountWon;
  final int? targetAmountWon;
}

class _PaymentMethodDialog extends StatefulWidget {
  const _PaymentMethodDialog({
    required this.members,
    this.initialKind = 'cash',
  });
  final List<MemberOption> members;
  final String initialKind;
  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final paidAmount = TextEditingController();
  final voucherAmount = TextEditingController();
  final targetAmount = TextEditingController();
  late String kind = widget.initialKind;
  String? owner;

  @override
  void dispose() {
    name.dispose();
    paidAmount.dispose();
    voucherAmount.dispose();
    targetAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kinds = <String, String>{
      'cash': l10n.cash,
      'bank': l10n.bank,
      'debit_card': l10n.debitCard,
      'credit_card': l10n.creditCard,
      'voucher': l10n.voucher,
    };
    return AlertDialog(
      title: Text(l10n.registerPaymentMethod),
      content: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: InputDecoration(labelText: l10n.kind),
              items: kinds.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => kind = value!),
            ),
            TextFormField(
              controller: name,
              autofocus: true,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.nameExample),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.nameRequired
                  : null,
            ),
            if (kind == 'voucher') ...[
              TextFormField(
                controller: paidAmount,
                keyboardType: TextInputType.number,
                inputFormatters: const [WonInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.actualPaidAmount,
                  suffixText: l10n.won,
                ),
                validator: (value) => (parseWon(value ?? '') ?? 0) <= 0
                    ? l10n.paidAmountRequired
                    : null,
              ),
              TextFormField(
                controller: voucherAmount,
                keyboardType: TextInputType.number,
                inputFormatters: const [WonInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.voucherTopUpAmount,
                  suffixText: l10n.won,
                ),
                validator: (value) => (parseWon(value ?? '') ?? 0) <= 0
                    ? l10n.topUpAmountRequired
                    : null,
              ),
            ],
            if (kind == 'debit_card' || kind == 'credit_card')
              TextFormField(
                controller: targetAmount,
                keyboardType: TextInputType.number,
                inputFormatters: const [WonInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.monthlyPerformanceTarget,
                  suffixText: l10n.won,
                ),
                validator: (value) => (parseWon(value ?? '') ?? 0) <= 0
                    ? l10n.targetAmountRequired
                    : null,
              ),
            if (widget.members.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: owner,
                decoration: InputDecoration(labelText: l10n.ownerOptional),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.none)),
                  ...widget.members.map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => owner = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(
                context,
                _PaymentMethodDraft(
                  kind,
                  name.text.trim(),
                  owner,
                  paidAmountWon: parseWon(paidAmount.text),
                  voucherAmountWon: parseWon(voucherAmount.text),
                  targetAmountWon: parseWon(targetAmount.text),
                ),
              );
            }
          },
          child: Text(l10n.register),
        ),
      ],
    );
  }
}
