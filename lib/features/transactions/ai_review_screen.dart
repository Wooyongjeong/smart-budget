import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_draft.dart';
import 'transaction_repository.dart';
import 'receipt_analysis.dart';
import '../../money_input.dart';
import '../../l10n/generated/app_localizations.dart';

class ReceiptFixtureItem {
  ReceiptFixtureItem({
    required this.draft,
    required this.reason,
    this.suggestedType = 'expense',
  }) : paymentMethodId = draft.paymentMethodId,
       memberId = draft.memberId,
       category = draft.category,
       selected = suggestedType == 'expense',
       amount = TextEditingController(
         text: draft.amountWon == null ? '' : formatWon(draft.amountWon!),
       ),
       merchant = TextEditingController(text: draft.merchant),
       date = TextEditingController(
         text: draft.amountWon == null
             ? ''
             : DateFormat('yyyy-MM-dd').format(draft.occurredOn),
       );

  factory ReceiptFixtureItem.fromAnalysis(
    ReceiptAnalysisItem item,
    HouseholdContext context,
  ) {
    final matchingMethods = context.paymentMethods.where(
      (m) => m.name == item.paymentHint,
    );
    final method = matchingMethods.isEmpty ? null : matchingMethods.first;
    final member = context.members.isEmpty ? null : context.members.first;
    final parsedDate = item.date == null
        ? DateTime.now()
        : DateFormat('yyyy-MM-dd').parseStrict(item.date!);
    final result = ReceiptFixtureItem(
      draft: TransactionDraft(
        kind: TransactionKind.expense,
        occurredOn: parsedDate,
        amountWon: item.amount,
        merchant: item.merchant ?? '',
        category: item.categoryHint,
        paymentMethodId: method?.id,
        memberId: member?.id,
        memo: '',
      ),
      reason: [
        if (item.paymentHint != null) '결제 수단: ${item.paymentHint}',
        ...item.reviewReasons,
        if (item.suggestedType != 'expense') '분류: ${item.suggestedType}',
      ].join(' · '),
      suggestedType: item.suggestedType,
    );
    result.date.text = item.date ?? '';
    return result;
  }

  final TransactionDraft draft;
  final String reason;
  final String suggestedType;
  String? paymentMethodId;
  String? memberId;
  String? category;
  bool selected;
  final TextEditingController amount;
  final TextEditingController merchant;
  final TextEditingController date;
  TransactionDraft toDraft() => TransactionDraft(
    kind: draft.kind,
    occurredOn: DateFormat('yyyy-MM-dd').parseStrict(date.text.trim()),
    amountWon: parseWon(amount.text),
    merchant: merchant.text.trim(),
    category: category,
    paymentMethodId: paymentMethodId,
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
    this.analysisClient,
  });
  final TransactionRepository repository;
  final HouseholdContext contextData;
  final ReceiptAnalysisClient? analysisClient;
  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  List<ReceiptFixtureItem> items = [];
  bool fixtureInitialized = false;
  bool saving = false;
  bool analyzing = false;
  String? fileName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!fixtureInitialized && widget.analysisClient == null) {
      items = _fixture(AppLocalizations.of(context)!);
      fixtureInitialized = true;
    }
  }

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

  Future<void> pickAndAnalyze() async {
    final client = widget.analysisClient;
    if (client == null || analyzing) return;
    final file = await FilePicker.pickFile(type: FileType.image);
    if (!mounted || file == null) return;
    final bytes = await file.xFile.readAsBytes();
    if (!mounted) return;
    final extension = (file.extension ?? '').toLowerCase();
    final contentType = extension == 'jpg' || extension == 'jpeg'
        ? 'image/jpeg'
        : extension == 'png'
        ? 'image/png'
        : '';
    if (contentType.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('JPEG 또는 PNG 이미지만 지원합니다.')));
      return;
    }
    setState(() {
      analyzing = true;
      fileName = file.name;
    });
    try {
      final analysis = await client.analyze(
        householdId: widget.contextData.householdId,
        bytes: Uint8List.fromList(bytes),
        contentType: contentType,
      );
      for (final item in items) {
        item.dispose();
      }
      if (!mounted) return;
      setState(() {
        items = analysis.items
            .map(
              (item) =>
                  ReceiptFixtureItem.fromAnalysis(item, widget.contextData),
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 분석에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => analyzing = false);
    }
  }

  Future<void> save() async {
    final selected = items.where((item) => item.selected).toList();
    if (selected.isEmpty) return;
    setState(() => saving = true);
    try {
      final drafts = selected.map((item) => item.toDraft()).toList();
      if (selected.any((item) => item.suggestedType != 'expense') ||
          drafts.any(
            (d) =>
                d.amountWon == null || d.amountWon! <= 0 || d.merchant.isEmpty,
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
          if (widget.analysisClient != null)
            FilledButton.icon(
              onPressed: analyzing || saving ? null : pickAndAnalyze,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(analyzing ? '분석 중…' : '이용내역 이미지 선택'),
            ),
          if (fileName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                fileName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (items.isEmpty && !analyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('이미지를 선택하면 분석 결과가 여기에 표시됩니다.')),
            ),
          if (analyzing)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
          ...items.map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: item.selected,
                      onChanged: saving || item.suggestedType != 'expense'
                          ? null
                          : (value) =>
                                setState(() => item.selected = value ?? false),
                      title: Text(
                        item.merchant.text.isEmpty
                            ? '사용처 미입력'
                            : item.merchant.text,
                      ),
                      subtitle: Text(
                        item.reason.isEmpty ? '일반 지출' : item.reason,
                      ),
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
                    if (widget.contextData.paymentMethods.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: item.paymentMethodId,
                        decoration: const InputDecoration(labelText: '결제 수단'),
                        items: widget.contextData.paymentMethods
                            .map(
                              (method) => DropdownMenuItem(
                                value: method.id,
                                child: Text(method.name),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) =>
                                  setState(() => item.paymentMethodId = value),
                      ),
                    if (widget.contextData.members.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: item.memberId,
                        decoration: const InputDecoration(labelText: '실제 사용자'),
                        items: widget.contextData.members
                            .map(
                              (member) => DropdownMenuItem(
                                value: member.id,
                                child: Text(member.name),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setState(() => item.memberId = value),
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: item.category,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: const ['식비', '생활', '교통', '주거', '쇼핑', '기타']
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setState(() => item.category = value),
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
