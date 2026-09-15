import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'transaction_draft.dart';
import 'transaction_repository.dart';
import '../../money_input.dart';

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
  late final items = _fixture();
  bool saving = false;

  List<ReceiptFixtureItem> _fixture() {
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
          merchant: '예시 마트',
          category: '식비',
          paymentMethodId: method?.id,
          memberId: member?.id,
          memo: '',
        ),
        reason: '고정 fixture 분석 예시',
      ),
      ReceiptFixtureItem(
        draft: TransactionDraft(
          kind: TransactionKind.expense,
          occurredOn: DateTime(2026, 9, 13),
          amountWon: 4200,
          merchant: '예시 카페',
          category: '식비',
          paymentMethodId: method?.id,
          memberId: member?.id,
          memo: '',
        ),
        reason: '고정 fixture 분석 예시',
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
          const SnackBar(
            content: Text('선택 항목을 저장하지 못했어요. 값을 확인하고 다시 시도해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('이용내역 검토')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '분석 예시\n고정 fixture를 확인하고 수정할 수 있어요. 실제 이미지 분석은 준비 중입니다.',
            ),
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
                    decoration: const InputDecoration(labelText: '날짜'),
                  ),
                  TextField(
                    controller: item.merchant,
                    decoration: const InputDecoration(labelText: '사용처'),
                  ),
                  TextField(
                    controller: item.amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [WonInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: '금액',
                      suffixText: '원',
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
                ? '저장 중…'
                : '${items.where((item) => item.selected).length}건 저장',
          ),
        ),
      ),
    ),
  );
}
