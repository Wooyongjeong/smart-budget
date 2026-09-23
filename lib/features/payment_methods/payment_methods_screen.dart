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
  DateTime summaryMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool saving = false;

  Future<List<Map<String, dynamic>>> _loadCardSummary() => widget.repository
      .cardPerformance(widget.contextData.householdId, summaryMonth);

  void _moveSummaryMonth(int offset) {
    setState(() {
      summaryMonth = DateTime(summaryMonth.year, summaryMonth.month + offset);
      cardSummary = _loadCardSummary();
    });
  }

  void _resetSummaryMonth() {
    final now = DateTime.now();
    setState(() {
      summaryMonth = DateTime(now.year, now.month);
      cardSummary = _loadCardSummary();
    });
  }

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
        paymentMethods: widget.contextData.paymentMethods,
        initialKind: initialKind,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => saving = true);
    try {
      final method = result.kind == 'voucher'
          ? await widget.repository.addVoucher(
              widget.contextData.householdId,
              result.name,
              result.ownerMemberId,
              result.paidAmountWon!,
              result.voucherAmountWon!,
              result.sourcePaymentMethodId,
            )
          : await widget.repository.addPaymentMethod(
              widget.contextData.householdId,
              result.kind,
              result.name,
              result.ownerMemberId,
            );
      if ((result.kind == 'debit_card' || result.kind == 'credit_card') &&
          result.targetAmountWon != null) {
        await widget.repository.setCardTarget(
          widget.contextData.householdId,
          method.id,
          summaryMonth,
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
        summaryMonth,
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, widget.embedded ? 124 : 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.wallet,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.paymentMethods,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: IconButton(
                tooltip: l10n.registerPaymentMethod,
                onPressed: saving ? null : add,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.paymentMethodsDescription),
        const SizedBox(height: 20),
        Row(
          children: [
            IconButton(
              key: const ValueKey('wallet-previous-month'),
              tooltip: '이전 달',
              onPressed: saving ? null : () => _moveSummaryMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMonthYear(summaryMonth),
                  key: const ValueKey('wallet-summary-month'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('wallet-next-month'),
              tooltip: '다음 달',
              onPressed: saving ? null : () => _moveSummaryMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
            TextButton(
              onPressed: saving ? null : _resetSummaryMonth,
              child: const Text('이번 달'),
            ),
          ],
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: cardSummary,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(l10n.performanceLoadFailed),
                      TextButton.icon(
                        onPressed: refreshCardSummary,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(value: 0.35)),
              );
            }
            final rows = snapshot.data ?? const <Map<String, dynamic>>[];
            final actual = rows.fold<int>(
              0,
              (sum, row) =>
                  sum + ((row['actual_amount_won'] as num?)?.toInt() ?? 0),
            );
            final target = rows.fold<int>(
              0,
              (sum, row) =>
                  sum + ((row['target_amount_won'] as num?)?.toInt() ?? 0),
            );
            final ratio = target == 0 ? 0.0 : (actual / target).clamp(0.0, 1.0);
            final primary = Theme.of(context).colorScheme.primary;
            return Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 20),
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
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 달 카드 실적',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatWon(actual)} / ${formatWon(target)}원',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xffd8b477),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    target == 0
                        ? '카드별 목표를 설정해 보세요'
                        : '예상 실적 ${(ratio * 100).round()}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: saving ? null : () => add(initialKind: 'voucher'),
            icon: const Icon(Icons.confirmation_number_outlined),
            label: Text(l10n.registerVoucher),
          ),
        ),
        const SizedBox(height: 16),
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
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(_iconFor(method.kind)),
                ),
                title: Text(
                  method.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
                        builder: (context, snapshot) {
                          final prefix =
                              '${kindLabel(context, method.kind)}${_ownerLabel(context, method)}\n';
                          if (snapshot.hasError) {
                            return Text('$prefix${l10n.balanceLoadFailed}');
                          }
                          if (!snapshot.hasData) {
                            return Text('$prefix${l10n.balanceLoading}');
                          }
                          return Text(
                            '$prefix${l10n.balance(formatWon(snapshot.data!))}',
                          );
                        },
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
    this.sourcePaymentMethodId,
    this.targetAmountWon,
  });
  final String kind;
  final String name;
  final String? ownerMemberId;
  final int? paidAmountWon;
  final int? voucherAmountWon;
  final String? sourcePaymentMethodId;
  final int? targetAmountWon;
}

class _PaymentMethodDialog extends StatefulWidget {
  const _PaymentMethodDialog({
    required this.members,
    required this.paymentMethods,
    this.initialKind = 'cash',
  });
  final List<MemberOption> members;
  final List<PaymentMethodOption> paymentMethods;
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
  String? sourcePaymentMethodId;

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
              DropdownButtonFormField<String>(
                initialValue: sourcePaymentMethodId,
                decoration: InputDecoration(labelText: l10n.paymentMethod),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.none)),
                  ...widget.paymentMethods
                      .where((method) => method.kind != 'voucher')
                      .map(
                        (method) => DropdownMenuItem(
                          value: method.id,
                          child: Text(method.name),
                        ),
                      ),
                ],
                onChanged: (value) =>
                    setState(() => sourcePaymentMethodId = value),
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
                  sourcePaymentMethodId: sourcePaymentMethodId,
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
