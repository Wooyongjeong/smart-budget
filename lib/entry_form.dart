import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'features/transactions/transaction_draft.dart';
import 'features/transactions/transaction_repository.dart';
import 'money_input.dart';

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    this.initialDraft,
    this.paymentMethods = const [],
    this.members = const [],
    this.onConfirm,
    this.onManagePaymentMethods,
  });
  final TransactionDraft? initialDraft;
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
    text: DateFormat(
      'yyyy-MM-dd',
    ).format(widget.initialDraft?.occurredOn ?? DateTime.now()),
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
                title: const Text('입력을 그만할까요?'),
                content: const Text('작성 중인 내용은 저장되지 않아요.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('계속 작성'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('버리기'),
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
        : '1~999,999,999원의 정수를 입력해 주세요.';
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
          title: const Text('입력 내용 확인'),
          content: SingleChildScrollView(
            child: Text(
              '${income ? '수입' : '지출'} · ${formatWon(parseWon(amount.text)!)}원\n'
              '${date.text.trim()}\n${merchant.text.trim()}\n$category · ${_paymentName()} · ${_memberName()}\n'
              '${memo.text.trim()}\n\n${widget.onConfirm == null ? '미리보기이며 실제 가계부에는 저장되지 않아요.' : '확인 후 저장할 수 있어요.'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('돌아가서 수정'),
            ),
            if (widget.onConfirm != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('확정'),
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
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || !dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) close();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: close,
          tooltip: '닫기',
          icon: const Icon(Icons.close),
        ),
        title: const Text('직접 입력'),
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
                const Text('입력 내용 확인 후 가계부에 저장해요.'),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('지출')),
                    ButtonSegment(value: true, label: Text('수입')),
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
                  decoration: const InputDecoration(
                    labelText: '금액',
                    suffixText: '원',
                  ),
                  validator: validateAmount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('date'),
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: '날짜',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
                      return 'YYYY-MM-DD 형식으로 입력해 주세요.';
                    }
                    try {
                      final parsed = DateFormat('yyyy-MM-dd').parseStrict(raw);
                      if (parsed.year >= 2000 && parsed.year <= 2100) {
                        return null;
                      }
                    } catch (_) {
                      /* Show field validation below. */
                    }
                    return '2000~2100년 사이의 실제 날짜를 입력해 주세요.';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('merchant'),
                  controller: merchant,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: income ? '수입 내용' : '사용처',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '내용을 입력해 주세요.'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$income'),
                  initialValue: category,
                  decoration: const InputDecoration(labelText: '카테고리'),
                  items:
                      (income
                              ? ['급여', '용돈', '기타']
                              : ['식비', '생활', '교통', '주거', '쇼핑', '기타'])
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: payment,
                  decoration: InputDecoration(
                    labelText: income ? '입금 수단' : '결제 수단',
                  ),
                  items: widget.paymentMethods
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.name)),
                      )
                      .toList(),
                  validator: (v) => v == null ? '등록된 수단을 선택해 주세요.' : null,
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
                      label: const Text('결제 수단 등록하기'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: person,
                  decoration: const InputDecoration(labelText: '실제 사용자'),
                  items: widget.members
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v.id, child: Text(v.name)),
                      )
                      .toList(),
                  validator: (v) => v == null ? '구성원을 선택해 주세요.' : null,
                  onChanged: (v) => setState(() => person = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: memo,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: '메모 (선택)'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: submitting ? null : preview,
                  child: const Text('입력 내용 확인'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
