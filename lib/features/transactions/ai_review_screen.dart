import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_draft.dart';
import 'transaction_repository.dart';
import 'receipt_analysis.dart';
import '../../money_input.dart';
import '../../l10n/generated/app_localizations.dart';

String _localizedReceiptType(AppLocalizations l10n, String type) =>
    switch (type) {
      'income' => l10n.income,
      'refund' => l10n.receiptRefundType,
      'unknown' => l10n.receiptUnknownType,
      _ => l10n.receiptUnknownType,
    };

const _categories = ['식비', '생활', '교통', '주거', '쇼핑', '기타'];
const _maxImageBytes = 10 * 1024 * 1024;

DateTime? _parseAnalysisDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return DateFormat('yyyy-MM-dd').parseStrict(value);
  } on FormatException {
    return null;
  }
}

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
    AppLocalizations l10n,
  ) {
    final member = context.members.isEmpty ? null : context.members.first;
    final parsedDate = _parseAnalysisDate(item.date);
    final category = _categories.contains(item.categoryHint)
        ? item.categoryHint
        : null;
    final result = ReceiptFixtureItem(
      draft: TransactionDraft(
        kind: TransactionKind.expense,
        occurredOn: parsedDate ?? DateTime.now(),
        amountWon: item.amount,
        merchant: item.merchant ?? '',
        category: category,
        paymentMethodId: null,
        memberId: member?.id,
        memo: '',
      ),
      reason: [
        if (item.paymentHint != null)
          l10n.receiptPaymentHint(item.paymentHint!),
        if (item.categoryHint != null && category == null)
          l10n.receiptCategoryHint,
        if (item.date != null && parsedDate == null)
          l10n.receiptDateHint(item.date!),
        if (item.reviewReasons.isNotEmpty) l10n.receiptNeedsReview,
        if (item.suggestedType != 'expense')
          l10n.receiptUnsupportedType(
            _localizedReceiptType(l10n, item.suggestedType),
          ),
      ].join(' · '),
      suggestedType: item.suggestedType,
    );
    result.date.text = parsedDate == null ? '' : item.date!;
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
    memberId: memberId,
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
  Uint8List? sourceBytes;
  String? saveRequestId;

  bool _isComplete(ReceiptFixtureItem item) {
    if (!item.selected || item.suggestedType != 'expense') return false;
    final date = _parseAnalysisDate(item.date.text.trim());
    final amount = parseWon(item.amount.text);
    return date != null &&
        date.year >= 2000 &&
        date.year <= 2100 &&
        amount != null &&
        amount > 0 &&
        item.merchant.text.trim().isNotEmpty &&
        item.category != null &&
        (widget.contextData.paymentMethods.isEmpty ||
            item.paymentMethodId != null) &&
        (widget.contextData.members.isEmpty || item.memberId != null);
  }

  void _markEdited() {
    saveRequestId = null;
    setState(() {});
  }

  String _analysisErrorMessage(Object error, AppLocalizations l10n) {
    if (error is ReceiptAnalysisException) {
      return switch (error.code) {
        'provider_not_configured' => l10n.receiptProviderMissing,
        'rate_limited' => l10n.receiptRateLimited,
        'provider_unauthorized' => l10n.receiptProviderUnauthorized,
        'provider_model_unavailable' => l10n.receiptProviderModelUnavailable,
        'provider_request_invalid' => l10n.receiptProviderRequestInvalid,
        'timeout' => l10n.receiptTimeout,
        'validation_failed' ||
        'image_type' ||
        'content_type' => l10n.receiptInvalidImage,
        _ => l10n.receiptAnalysisFailed,
      };
    }
    return l10n.receiptNetworkFailed;
  }

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
    final extension = (file.extension ?? '').toLowerCase();
    final contentType = extension == 'jpg' || extension == 'jpeg'
        ? 'image/jpeg'
        : extension == 'png'
        ? 'image/png'
        : '';
    if (contentType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.receiptInvalidImage),
        ),
      );
      return;
    }
    final fileSize = await file.xFile.length();
    if (!mounted) return;
    if (fileSize <= 0 || fileSize > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.receiptImageSize)),
      );
      return;
    }
    final bytes = await file.xFile.readAsBytes();
    if (!mounted) return;
    for (final item in items) {
      item.dispose();
    }
    setState(() {
      analyzing = true;
      fileName = file.name;
      sourceBytes = Uint8List.fromList(bytes);
      saveRequestId = null;
      items = [];
    });
    try {
      final analysis = await client.analyze(
        householdId: widget.contextData.householdId,
        bytes: Uint8List.fromList(bytes),
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() {
        saveRequestId = analysis.draftId.isEmpty ? null : analysis.draftId;
        items = analysis.items
            .map(
              (item) => ReceiptFixtureItem.fromAnalysis(
                item,
                widget.contextData,
                AppLocalizations.of(context)!,
              ),
            )
            .toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _analysisErrorMessage(error, AppLocalizations.of(context)!),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => analyzing = false);
      }
    }
  }

  List<String> _errors(ReceiptFixtureItem item, AppLocalizations l10n) {
    if (!item.selected) return const [];
    final errors = <String>[];
    final date = _parseAnalysisDate(item.date.text.trim());
    if (date == null || date.year < 2000 || date.year > 2100) {
      errors.add(l10n.receiptDateMissing);
    }
    final amount = parseWon(item.amount.text);
    if (amount == null || amount <= 0) {
      errors.add(l10n.receiptAmountMissing);
    }
    if (item.merchant.text.trim().isEmpty) {
      errors.add(l10n.receiptMerchantMissing);
    }
    if (item.category == null) {
      errors.add(l10n.receiptCategoryMissing);
    }
    if (widget.contextData.paymentMethods.isNotEmpty &&
        item.paymentMethodId == null) {
      errors.add(l10n.receiptPaymentMethodMissing);
    }
    if (widget.contextData.members.isNotEmpty && item.memberId == null) {
      errors.add(l10n.receiptMemberMissing);
    }
    if (item.suggestedType != 'expense') errors.add(item.reason);
    return errors;
  }

  String? _fieldError(
    ReceiptFixtureItem item,
    AppLocalizations l10n,
    String field,
  ) {
    if (!item.selected) return null;
    if (field == 'date') {
      final date = _parseAnalysisDate(item.date.text.trim());
      return date != null && date.year >= 2000 && date.year <= 2100
          ? null
          : l10n.receiptDateMissing;
    }
    if (field == 'amount') {
      return (parseWon(item.amount.text) ?? 0) > 0
          ? null
          : l10n.receiptAmountMissing;
    }
    if (field == 'merchant') {
      return item.merchant.text.trim().isNotEmpty
          ? null
          : l10n.receiptMerchantMissing;
    }
    if (field == 'category') {
      return item.category != null ? null : l10n.receiptCategoryMissing;
    }
    if (field == 'payment') {
      return item.paymentMethodId != null
          ? null
          : l10n.receiptPaymentMethodMissing;
    }
    if (field == 'member') {
      return item.memberId != null ? null : l10n.receiptMemberMissing;
    }
    return null;
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
      if (selected.any((item) => !_isComplete(item))) {
        throw const FormatException();
      }
      saveRequestId ??= newTransactionRequestId();
      await widget.repository.saveMany(
        widget.contextData.householdId,
        drafts,
        requestId: saveRequestId,
      );
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
      appBar: AppBar(
        title: Text(l10n.receiptReview),
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  l10n.receiptItemsFound(items.length),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          if (items.isNotEmpty && sourceBytes != null)
            GestureDetector(
              key: const ValueKey('receipt-source-preview'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.memory(sourceBytes!, fit: BoxFit.contain),
                  ),
                ),
              ),
              child: Container(
                height: 152,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff232928),
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(sourceBytes!, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xaa000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Text(
                        l10n.receiptTapToZoom,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.analysisClient != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: analyzing || saving ? null : pickAndAnalyze,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  analyzing ? l10n.receiptAnalyzing : l10n.receiptChooseImage,
                ),
              ),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text(l10n.receiptEmpty)),
            ),
          if (analyzing)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (items.any((item) => _errors(item, l10n).isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.receiptRemainingErrors(
                  items.where((item) => _errors(item, l10n).isNotEmpty).length,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: item.selected && !_isComplete(item)
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.06)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: item.selected,
                      onChanged: saving || item.suggestedType != 'expense'
                          ? null
                          : (value) {
                              item.selected = value ?? false;
                              _markEdited();
                            },
                      title: Text(
                        item.merchant.text.isEmpty
                            ? l10n.receiptMerchantMissing
                            : item.merchant.text,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        item.reason.isEmpty ? l10n.expense : item.reason,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: item.date,
                      onChanged: (_) => _markEdited(),
                      decoration: InputDecoration(
                        labelText: l10n.date,
                        errorText: _fieldError(item, l10n, 'date'),
                      ),
                    ),
                    TextField(
                      controller: item.merchant,
                      onChanged: (_) => _markEdited(),
                      decoration: InputDecoration(
                        labelText: l10n.merchant,
                        errorText: _fieldError(item, l10n, 'merchant'),
                      ),
                    ),
                    TextField(
                      controller: item.amount,
                      onChanged: (_) => _markEdited(),
                      keyboardType: TextInputType.number,
                      inputFormatters: const [WonInputFormatter()],
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        suffixText: l10n.won,
                        errorText: _fieldError(item, l10n, 'amount'),
                      ),
                    ),
                    if (widget.contextData.paymentMethods.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: item.paymentMethodId,
                        decoration: InputDecoration(
                          labelText: l10n.paymentMethod,
                          errorText: _fieldError(item, l10n, 'payment'),
                        ),
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
                            : (value) {
                                item.paymentMethodId = value;
                                _markEdited();
                              },
                      ),
                    if (widget.contextData.members.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: item.memberId,
                        decoration: InputDecoration(
                          labelText: l10n.actualUser,
                          errorText: _fieldError(item, l10n, 'member'),
                        ),
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
                            : (value) {
                                item.memberId = value;
                                _markEdited();
                              },
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: item.category,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        errorText: _fieldError(item, l10n, 'category'),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              item.category = value;
                              _markEdited();
                            },
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
            onPressed:
                saving ||
                    !items.any((item) => item.selected) ||
                    items
                        .where((item) => item.selected)
                        .any((item) => !_isComplete(item))
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
