import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'business_date.dart';
import 'features/transactions/transaction_draft.dart';
import 'features/transactions/transaction_repository.dart';
import 'money_input.dart';
import 'l10n/generated/app_localizations.dart';

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    this.initialDraft,
    this.initialDate,
    this.businessDateProvider = const BusinessDateProvider(),
    this.paymentMethods = const [],
    this.members = const [],
    this.onConfirm,
    this.onManagePaymentMethods,
  });
  final TransactionDraft? initialDraft;
  final DateTime? initialDate;
  final BusinessDateProvider businessDateProvider;
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
      widget.initialDraft?.occurredOn ??
          widget.initialDate ??
          widget.businessDateProvider.today,
    ),
  );
  late bool income = widget.initialDraft?.kind == TransactionKind.income;
  bool dirty = false;
  bool leaving = false;
  bool asking = false;
  bool submitting = false;
  late String category =
      widget.initialDraft?.category ?? (income ? '급여' : '식비');
  late String? payment;
  late String? person =
      widget.initialDraft?.memberId ??
      (widget.members.isEmpty ? null : widget.members.first.id);

  List<PaymentMethodOption> _paymentMethodsFor(bool isIncome) => widget
      .paymentMethods
      .where(
        (option) => isIncome
            ? option.kind == 'cash' || option.kind == 'bank'
            : option.kind != 'voucher',
      )
      .toList(growable: false);

  String _paymentName(AppLocalizations l10n) {
    final matches = widget.paymentMethods.where(
      (option) => option.id == payment,
    );
    return matches.isEmpty ? l10n.none : matches.first.name;
  }

  String _memberName(AppLocalizations l10n) {
    final matches = widget.members.where((option) => option.id == person);
    return matches.isEmpty ? l10n.none : matches.first.name;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    final eligibleMethods = _paymentMethodsFor(income);
    final initialPayment = draft?.paymentMethodId;
    payment = eligibleMethods.any((method) => method.id == initialPayment)
        ? initialPayment
        : eligibleMethods.firstOrNull?.id;
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
      initialDate = widget.businessDateProvider.today;
    }
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _DatePickerWithToday(
        initialDate: initialDate,
        businessDateProvider: widget.businessDateProvider,
      ),
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
              '${date.text.trim()}\n${merchant.text.trim()}\n${_categoryLabel(AppLocalizations.of(context)!, category)} · ${_paymentName(AppLocalizations.of(context)!)} · ${_memberName(AppLocalizations.of(context)!)}\n'
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
    final eligibleMethods = _paymentMethodsFor(income);
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
    Widget selectionRow({
      required IconData icon,
      required String label,
      required Widget field,
      bool showDivider = true,
    }) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xff697570),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    field,
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 64, endIndent: 16),
      ],
    );
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.entryGuide,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.expense)),
                      ButtonSegment(value: true, label: Text(l10n.income)),
                    ],
                    selected: {income},
                    onSelectionChanged: (values) => setState(() {
                      final nextIncome = values.first;
                      final nextMethods = _paymentMethodsFor(nextIncome);
                      income = nextIncome;
                      category = income ? '급여' : '식비';
                      if (!nextMethods.any((method) => method.id == payment)) {
                        payment = nextMethods.firstOrNull?.id;
                      }
                      dirty = true;
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('amount'),
                    controller: amount,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
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
                  Card(
                    child: Column(
                      children: [
                        selectionRow(
                          icon: Icons.category_rounded,
                          label: l10n.category,
                          field: DropdownButtonFormField<String>(
                            key: ValueKey('category-$income'),
                            initialValue: category,
                            isExpanded: true,
                            icon: const Icon(Icons.chevron_right_rounded),
                            decoration: const InputDecoration.collapsed(
                              hintText: '',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
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
                        ),
                        selectionRow(
                          icon: income
                              ? Icons.account_balance_rounded
                              : Icons.credit_card_rounded,
                          label: income
                              ? l10n.depositMethod
                              : l10n.paymentMethod,
                          field: DropdownButtonFormField<String>(
                            key: ValueKey('payment-$income'),
                            initialValue: payment,
                            isExpanded: true,
                            icon: const Icon(Icons.chevron_right_rounded),
                            decoration: const InputDecoration.collapsed(
                              hintText: '',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                            items: eligibleMethods
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text(v.name),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                v == null ? l10n.methodRequired : null,
                            onChanged: (v) => setState(() => payment = v),
                          ),
                        ),
                        selectionRow(
                          icon: Icons.person_rounded,
                          label: l10n.actualUser,
                          showDivider: false,
                          field: DropdownButtonFormField<String>(
                            initialValue: person,
                            isExpanded: true,
                            icon: const Icon(Icons.chevron_right_rounded),
                            decoration: const InputDecoration.collapsed(
                              hintText: '',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                            items: widget.members
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text(v.name),
                                  ),
                                )
                                .toList(),
                            validator: (v) =>
                                v == null ? l10n.memberRequired : null,
                            onChanged: (v) => setState(() => person = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (eligibleMethods.isEmpty &&
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

  String _categoryLabel(AppLocalizations l10n, String value) => switch (value) {
    '급여' => l10n.salary,
    '용돈' => l10n.allowance,
    '식비' => l10n.food,
    '생활' => l10n.living,
    '교통' => l10n.transportation,
    '주거' => l10n.housing,
    '쇼핑' => l10n.shopping,
    '기타' => l10n.other,
    _ => value,
  };
}

class _DatePickerWithToday extends StatefulWidget {
  const _DatePickerWithToday({
    required this.initialDate,
    required this.businessDateProvider,
  });

  final DateTime initialDate;
  final BusinessDateProvider businessDateProvider;

  @override
  State<_DatePickerWithToday> createState() => _DatePickerWithTodayState();
}

class _DatePickerWithTodayState extends State<_DatePickerWithToday>
    with SingleTickerProviderStateMixin {
  late DateTime selectedDate = DateUtils.dateOnly(widget.initialDate);
  late DateTime displayedMonth = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
  );
  late final AnimationController todayController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  int calendarRevision = 0;
  double todayDirection = 1;
  bool showingToday = false;
  bool movingToToday = false;

  Future<void> moveToToday() async {
    if (movingToToday) return;
    final today = widget.businessDateProvider.today;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        selectedDate = today;
        calendarRevision += 1;
      });
      return;
    }
    setState(() {
      todayDirection = today.isBefore(displayedMonth) ? -1 : 1;
      showingToday = false;
      movingToToday = true;
    });
    await todayController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      selectedDate = today;
      calendarRevision += 1;
      showingToday = true;
    });
    await todayController.forward(from: 0);
    if (mounted) setState(() => movingToToday = false);
  }

  @override
  void dispose() {
    todayController.dispose();
    super.dispose();
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
        child: ClipRect(
          child: AnimatedBuilder(
            animation: todayController,
            builder: (context, child) {
              final progress = Curves.easeInOutCubic.transform(
                todayController.value,
              );
              final dx = showingToday
                  ? todayDirection * 0.12 * (1 - progress)
                  : -todayDirection * 0.12 * progress;
              final opacity = showingToday ? progress : 1 - progress;
              return FadeTransition(
                opacity: AlwaysStoppedAnimation(opacity.clamp(0.0, 1.0)),
                child: SlideTransition(
                  key: const Key('today-calendar-slide'),
                  position: AlwaysStoppedAnimation(Offset(dx, 0)),
                  child: child,
                ),
              );
            },
            child: CalendarDatePicker(
              key: ValueKey((selectedDate, calendarRevision)),
              initialDate: selectedDate,
              currentDate: widget.businessDateProvider.today,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDisplayedMonthChanged: (value) {
                displayedMonth = DateTime(value.year, value.month);
              },
              onDateChanged: (value) => setState(() => selectedDate = value),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.tonalIcon(
          onPressed: movingToToday ? null : moveToToday,
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
