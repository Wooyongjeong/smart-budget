import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'features/transactions/transaction_draft.dart';
import 'features/transactions/transaction_repository.dart';
import 'money_input.dart';
import 'l10n/generated/app_localizations.dart';

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    this.initialDraft,
    this.initialDate,
    this.paymentMethods = const [],
    this.members = const [],
    this.onConfirm,
    this.onManagePaymentMethods,
  });
  final TransactionDraft? initialDraft;
  final DateTime? initialDate;
  final List<PaymentMethodOption> paymentMethods;
  final List<MemberOption> members;
  final Future<void> Function(TransactionDraft draft)? onConfirm;
  final VoidCallback? onManagePaymentMethods;

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  final merchant = TextEditingController();
  final memo = TextEditingController();
  late final date = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(
      widget.initialDraft?.occurredOn ?? widget.initialDate ?? DateTime.now(),
    ),
  );
  late bool income = widget.initialDraft?.kind == TransactionKind.income;
  bool dirty = false;
  bool leaving = false;
  bool asking = false;
  bool submitting = false;
  late String category =
      widget.initialDraft?.category ?? (income ? '급여' : '식비');
  late String? payment =
      widget.initialDraft?.paymentMethodId ??
      (widget.paymentMethods.isEmpty ? null : widget.paymentMethods.first.id);
  late String? person =
      widget.initialDraft?.memberId ??
      (widget.members.isEmpty ? null : widget.members.first.id);

  String _paymentName() {
    final matches = widget.paymentMethods.where(
      (option) => option.id == payment,
    );
    return matches.isEmpty ? '선택 안 됨' : matches.first.name;
  }

  String _memberName() {
    final matches = widget.members.where((option) => option.id == person);
    return matches.isEmpty ? '선택 안 됨' : matches.first.name;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    if (draft != null) {
      amount.text = draft.amountWon == null ? '' : formatWon(draft.amountWon!);
      merchant.text = draft.merchant;
      memo.text = draft.memo;
    }
  }

  @override
  void dispose() {
    for (final controller in [amount, merchant, memo, date]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> close() async {
    if (asking) return;
    asking = true;
    final discard =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.stopEntryTitle),
                content: Text(AppLocalizations.of(context)!.stopEntryBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)!.continueEditing),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(AppLocalizations.of(context)!.discard),
                  ),
                ],
              ),
            ) ==
            true;
    asking = false;
    if (!discard || !mounted) return;
    setState(() => leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  String? validateAmount(String? value) {
    final raw = value?.trim() ?? '';
    final number = parseWon(raw);
    return RegExp(r'^\d{1,3}(,\d{3})*$').hasMatch(raw) &&
            number != null &&
            number > 0 &&
            number <= 999999999
        ? null
        : AppLocalizations.of(context)!.amountValidation;
  }

  Future<void> pickDate() async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('yyyy-MM-dd').parseStrict(date.text.trim());
    } catch (_) {
      initialDate = DateTime.now();
    }
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _DatePickerWithToday(initialDate: initialDate),
    );
    if (selected == null || !mounted) return;
    setState(() {
      date.text = DateFormat('yyyy-MM-dd').format(selected);
      dirty = true;
    });
  }

  Future<void> preview() async {
    if (submitting) return;
    if (!form.currentState!.validate()) return;
    setState(() => submitting = true);
    try {
      final draft = TransactionDraft(
        kind: income ? TransactionKind.income : TransactionKind.expense,
        occurredOn: DateFormat('yyyy-MM-dd').parseStrict(date.text.trim()),
        amountWon: parseWon(amount.text)!,
        merchant: merchant.text.trim(),
        category: category,
        paymentMethodId: payment,
        memberId: person,
        memo: memo.text.trim(),
      );
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.reviewEntry),
          content: SingleChildScrollView(
            child: Text(
              '${income ? AppLocalizations.of(context)!.income : AppLocalizations.of(context)!.expense} · ${AppLocalizations.of(context)!.formattedAmount(formatWon(parseWon(amount.text)!))}\n'
              '${date.text.trim()}\n${merchant.text.trim()}\n$category · ${_paymentName()} · ${_memberName()}\n'
              '${memo.text.trim()}\n\n${widget.onConfirm == null ? AppLocalizations.of(context)!.previewOnly : AppLocalizations.of(context)!.confirmToSave}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.backToEdit),
            ),
            if (widget.onConfirm != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.finalize),
              ),
          ],
        ),
      );
      if (confirmed == true && widget.onConfirm != null && mounted) {
        await widget.onConfirm!(draft);
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryLabels = {
      '급여': l10n.salary,
      '용돈': l10n.allowance,
      '식비': l10n.food,
      '생활': l10n.living,
      '교통': l10n.transportation,
      '주거': l10n.housing,
      '쇼핑': l10n.shopping,
      '기타': l10n.other,
    };
    return PopScope(
      canPop: leaving || !dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: close,
            tooltip: l10n.close,
            icon: const Icon(Icons.close),
          ),
          title: Text(l10n.directEntry),
        ),
        body: SafeArea(
          child: Form(
            key: form,
            onChanged: () {
              if (!dirty) setState(() => dirty = true);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.entryGuide),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.expense)),
                      ButtonSegment(value: true, label: Text(l10n.income)),
                    ],
                    selected: {income},
                    onSelectionChanged: (values) => setState(() {
                      income = values.first;
                      category = income ? '급여' : '식비';
                      dirty = true;
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('amount'),
                    controller: amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [WonInputFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      suffixText: l10n.won,
                    ),
                    validator: validateAmount,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('date'),
                    controller: date,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.date,
                      suffixIcon: IconButton(
                        onPressed: pickDate,
                        tooltip: l10n.chooseDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    onTap: pickDate,
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
                        return l10n.dateValidation;
                      }
                      try {
                        final parsed = DateFormat(
                          'yyyy-MM-dd',
                        ).parseStrict(raw);
                        if (parsed.year >= 2000 && parsed.year <= 2100) {
                          return null;
                        }
                      } catch (_) {
                        /* Show field validation below. */
                      }
                      return l10n.dateValidation;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('merchant'),
                    controller: merchant,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: income
                          ? l10n.incomeDescription
                          : l10n.merchant,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.contentRequired
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$income'),
                    initialValue: category,
                    decoration: InputDecoration(labelText: l10n.category),
                    items:
                        (income
                                ? ['급여', '용돈', '기타']
                                : ['식비', '생활', '교통', '주거', '쇼핑', '기타'])
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(categoryLabels[v]!),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: payment,
                    decoration: InputDecoration(
                      labelText: income
                          ? l10n.depositMethod
                          : l10n.paymentMethod,
                    ),
                    items: widget.paymentMethods
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name),
                          ),
                        )
                        .toList(),
                    validator: (v) => v == null ? l10n.methodRequired : null,
                    onChanged: (v) => setState(() => payment = v),
                  ),
                  if (widget.paymentMethods.isEmpty &&
                      widget.onManagePaymentMethods != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: widget.onManagePaymentMethods,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addPaymentMethod),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: person,
                    decoration: InputDecoration(labelText: l10n.actualUser),
                    items: widget.members
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name),
                          ),
                        )
                        .toList(),
                    validator: (v) => v == null ? l10n.memberRequired : null,
                    onChanged: (v) => setState(() => person = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: memo,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: l10n.memoOptional),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting ? null : preview,
                    child: Text(l10n.reviewEntry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerWithToday extends StatefulWidget {
  const _DatePickerWithToday({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_DatePickerWithToday> createState() => _DatePickerWithTodayState();
}

class _DatePickerWithTodayState extends State<_DatePickerWithToday> {
  late DateTime selectedDate = DateUtils.dateOnly(widget.initialDate);

  void moveToToday() {
    setState(() => selectedDate = DateUtils.dateOnly(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.chooseDate),
      contentPadding: const EdgeInsets.only(top: 8),
      content: SizedBox(
        width: 330,
        height: 330,
        child: CalendarDatePicker(
          key: ValueKey(selectedDate),
          initialDate: selectedDate,
          currentDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: (value) => setState(() => selectedDate = value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.tonalIcon(
          onPressed: moveToToday,
          icon: const Icon(Icons.today_outlined),
          label: Text(l10n.today),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: Text(l10n.choose),
        ),
      ],
    );
  }
}
