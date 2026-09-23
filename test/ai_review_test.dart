import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:smart_budget/features/transactions/ai_review_screen.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/receipt_analysis.dart';
import 'localized_test_app.dart';

class FakeRepository implements TransactionRepository {
  int savedCount = 0;
  bool failNextSave = false;
  final requestIds = <String?>[];
  @override
  Future<HouseholdContext> loadContext() async => const HouseholdContext(
    householdId: 'household',
    paymentMethods: [
      PaymentMethodOption(id: 'method', name: '현금', kind: 'cash'),
    ],
    members: [MemberOption(id: 'member', name: '나')],
  );
  @override
  Future<void> save(String householdId, TransactionDraft draft) async {}
  @override
  Future<void> saveMany(
    String householdId,
    List<TransactionDraft> drafts, {
    String? requestId,
  }) async {
    requestIds.add(requestId);
    if (failNextSave) {
      failNextSave = false;
      throw const TransactionSaveException('unexpected');
    }
    savedCount = drafts.length;
  }

  @override
  Future<void> edit(
    String h,
    String id,
    int version,
    TransactionDraft draft, {
    String? requestId,
  }) async {}
  @override
  Future<void> voidTransaction(
    String id,
    int version, {
    String? requestId,
  }) async {}

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String householdId,
    String kind,
    String name,
    String? ownerMemberId,
  ) async => PaymentMethodOption(
    id: 'new-method',
    name: name,
    kind: kind,
    ownerMemberId: ownerMemberId,
  );

  @override
  Future<void> archivePaymentMethod(
    String householdId,
    String paymentMethodId,
  ) async {}
  @override
  Future<void> recordVoucherEvent(
    String h,
    String k,
    String v,
    int p,
    int a,
  ) async {}
  @override
  Future<List<Map<String, dynamic>>> cardPerformance(
    String h,
    DateTime m,
  ) async => [];
  @override
  Future<void> setCardTarget(String h, String p, DateTime m, int a) async {}
  @override
  Future<int> voucherBalance(String h, String v) async => 0;

  @override
  Future<TransactionQueryResult> query(
    String householdId,
    DateTime start,
    DateTime end, {
    String? memberId,
    String? paymentMethodId,
    String? category,
    TransactionQueryCursor? cursor,
    int limit = 50,
  }) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
}

void main() {
  const context = HouseholdContext(
    householdId: 'household',
    paymentMethods: [
      PaymentMethodOption(id: 'method', name: '현금', kind: 'cash'),
    ],
    members: [MemberOption(id: 'member', name: '나')],
  );

  test('maps nullable dates and payment hints from analysis JSON', () {
    final result = ReceiptAnalysisResult.fromJson({
      'draft_id': 'draft',
      'items': [
        {
          'date': null,
          'merchant': '스몰토커피',
          'amount': 9000,
          'suggested_type': 'expense',
          'payment_hint': 'MG+ S 하나카드',
          'category_hint': '식비',
          'review_reasons': [],
        },
      ],
    });
    expect(result.items.single.date, isNull);
    expect(result.items.single.paymentHint, 'MG+ S 하나카드');
    expect(result.items.single.amount, 9000);
  });

  test('keeps invalid model hints editable instead of throwing', () {
    final item = ReceiptFixtureItem.fromAnalysis(
      const ReceiptAnalysisItem(
        date: '2026-02-31',
        merchant: '마트',
        amount: 1000,
        suggestedType: 'expense',
        paymentHint: '현금',
        categoryHint: 'Dining',
        reviewReasons: [],
      ),
      context,
    );
    addTearDown(item.dispose);

    expect(item.date.text, isEmpty);
    expect(item.category, isNull);
    expect(item.paymentMethodId, isNull);
  });

  test('saves the member selected during review', () {
    final item = ReceiptFixtureItem(
      draft: TransactionDraft(
        kind: TransactionKind.expense,
        occurredOn: DateTime(2026, 9, 18),
        amountWon: 1000,
        merchant: '마트',
        category: '생활',
        paymentMethodId: 'method',
        memberId: 'old-member',
        memo: '',
      ),
      reason: '',
    );
    addTearDown(item.dispose);
    item.memberId = 'new-member';

    expect(item.toDraft().memberId, 'new-member');
  });

  testWidgets('fixture items can be deselected and saved in one batch', (
    tester,
  ) async {
    final repository = FakeRepository();
    await tester.pumpWidget(
      localizedTestApp(
        home: AiReviewScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    expect(find.text('2건 저장'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('1건 저장'), findsOneWidget);
    await tester.tap(find.text('1건 저장'));
    await tester.pumpAndSettle();
    expect(repository.savedCount, 1);
  });

  testWidgets('a failed unchanged batch retries with the same request id', (
    tester,
  ) async {
    final repository = FakeRepository()..failNextSave = true;
    await tester.pumpWidget(
      localizedTestApp(
        home: AiReviewScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );

    await tester.tap(find.text('2건 저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2건 저장'));
    await tester.pumpAndSettle();

    expect(repository.requestIds, hasLength(2));
    expect(repository.requestIds.first, isNotNull);
    expect(repository.requestIds.last, repository.requestIds.first);
    expect(repository.savedCount, 2);
  });
}
