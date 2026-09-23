import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/payment_methods/payment_methods_screen.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';
import 'package:smart_budget/features/transactions/transaction_repository.dart';
import 'localized_test_app.dart';

class _Repository implements TransactionRepository {
  final methods = <PaymentMethodOption>[];
  int target = 0;
  int voucherAmount = 0;
  DateTime? lastPerformanceMonth;
  DateTime? lastTargetMonth;
  bool failNextPerformance = false;
  String? lastVoucherMode;
  String? lastVoucherMemberId;
  String? lastVoucherRequestId;
  int? lastVoucherPaidAmount;
  String? lastVoucherSource;

  @override
  Future<HouseholdContext> loadContext() async => HouseholdContext(
    householdId: 'household',
    paymentMethods: methods,
    members: const [MemberOption(id: 'member', name: '나')],
  );

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String h,
    String kind,
    String name,
    String? owner,
  ) async {
    final method = PaymentMethodOption(
      id: 'new',
      name: name,
      kind: kind,
      ownerMemberId: owner,
    );
    methods.add(method);
    return method;
  }

  @override
  Future<void> archivePaymentMethod(String h, String id) async =>
      methods.removeWhere((method) => method.id == id);
  @override
  Future<void> recordVoucherEvent(
    String h,
    String k,
    String v,
    int p,
    int a,
  ) async {
    voucherAmount += k == 'voucher_use' ? -a : a;
  }

  @override
  Future<List<Map<String, dynamic>>> cardPerformance(
    String h,
    DateTime m,
  ) async {
    lastPerformanceMonth = m;
    if (failNextPerformance) {
      failNextPerformance = false;
      throw Exception('network');
    }
    return methods
        .where(
          (method) =>
              method.kind == 'credit_card' || method.kind == 'debit_card',
        )
        .map(
          (method) => <String, dynamic>{
            'payment_method_id': method.id,
            'actual_amount_won': 120000,
            'target_amount_won': target,
          },
        )
        .toList();
  }

  @override
  Future<void> setCardTarget(String h, String p, DateTime m, int a) async {
    lastTargetMonth = m;
    target = a;
  }

  @override
  Future<int> voucherBalance(String h, String v) async => voucherAmount;
  @override
  Future<void> save(String h, TransactionDraft d) async {}
  @override
  Future<PaymentMethodOption> addVoucher(
    String h,
    String name,
    String? owner,
    int paid,
    int amount,
    String? source, {
    required String mode,
    required String actualMemberId,
    String? requestId,
  }) async {
    lastVoucherMode = mode;
    lastVoucherMemberId = actualMemberId;
    lastVoucherRequestId = requestId;
    lastVoucherPaidAmount = paid;
    lastVoucherSource = source;
    final method = PaymentMethodOption(
      id: 'new-voucher',
      name: name,
      kind: 'voucher',
      ownerMemberId: owner,
    );
    methods.add(method);
    voucherAmount += amount;
    return method;
  }

  @override
  Future<void> saveMany(
    String h,
    List<TransactionDraft> d, {
    String? requestId,
  }) async {}
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
  Future<TransactionQueryResult> query(
    String h,
    DateTime s,
    DateTime e, {
    String? memberId,
    String? paymentMethodId,
    String? category,
    TransactionQueryCursor? cursor,
    int limit = 50,
  }) async =>
      const TransactionQueryResult(items: [], totalIncome: 0, totalExpense: 0);
}

void main() {
  testWidgets('English locale translates the wallet management screen', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    expect(find.text('Payment methods'), findsOneWidget);
    expect(find.text('Add voucher'), findsOneWidget);
    expect(find.text('No payment methods yet.'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Card spending this month'), findsOneWidget);
  });

  testWidgets('registers a payment method from the management screen', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      localizedTestApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    expect(find.text('등록된 결제 수단이 없어요.'), findsOneWidget);
    await tester.tap(find.text('첫 수단 등록'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '생활비 현금');
    await tester.tap(find.text('등록').last);
    await tester.pumpAndSettle();
    expect(find.text('생활비 현금'), findsOneWidget);
  });

  testWidgets('registers a voucher with its initial balance atomically', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      localizedTestApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.tap(find.text('상품권 등록'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '온누리');
    await tester.enterText(fields.at(1), '100000');
    await tester.tap(find.text('등록').last);
    await tester.pumpAndSettle();
    expect(find.text('온누리'), findsOneWidget);
    expect(find.textContaining('잔액 100,000원'), findsOneWidget);
    expect(repository.lastVoucherMode, 'initial_balance');
    expect(repository.lastVoucherPaidAmount, 0);
    expect(repository.lastVoucherMemberId, 'member');
    expect(repository.lastVoucherRequestId, isNotEmpty);
  });

  testWidgets('updates a card target and refreshes the summary', (
    tester,
  ) async {
    final repository = _Repository();
    repository.methods.add(
      const PaymentMethodOption(id: 'card', name: '생활 카드', kind: 'credit_card'),
    );
    await tester.pumpWidget(
      localizedTestApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initialMonth = repository.lastPerformanceMonth!;
    await tester.tap(find.byKey(const ValueKey('wallet-previous-month')));
    await tester.pumpAndSettle();
    expect(
      repository.lastPerformanceMonth,
      DateTime(initialMonth.year, initialMonth.month - 1),
    );
    expect(find.textContaining('목표 0원'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('실적 목표 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '300000');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '300,000',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(
      repository.lastTargetMonth,
      DateTime(initialMonth.year, initialMonth.month - 1),
    );
    expect(find.textContaining('목표 300,000원'), findsOneWidget);
  });

  testWidgets('registers a paid voucher purchase with source and user', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Repository();
    repository.methods.add(
      const PaymentMethodOption(id: 'cash', name: '현금', kind: 'cash'),
    );
    await tester.pumpWidget(
      localizedTestApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.tap(find.text('상품권 등록'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('유상 구매'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '온누리');
    await tester.enterText(fields.at(1), '93000');
    await tester.enterText(fields.at(2), '100000');
    final sourceDropdown = find.byType(DropdownButtonFormField<String>).at(1);
    await tester.ensureVisible(sourceDropdown);
    await tester.tap(sourceDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('현금').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('등록').last);
    await tester.tap(find.text('등록').last);
    await tester.pumpAndSettle();

    expect(repository.lastVoucherMode, 'purchase');
    expect(repository.lastVoucherPaidAmount, 93000);
    expect(repository.lastVoucherSource, 'cash');
    expect(repository.lastVoucherMemberId, 'member');
  });

  testWidgets(
    'card summary error retries without changing the selected month',
    (tester) async {
      final repository = _Repository()..failNextPerformance = true;
      await tester.pumpWidget(
        localizedTestApp(
          home: PaymentMethodsScreen(
            repository: repository,
            contextData: await repository.loadContext(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final failedMonth = repository.lastPerformanceMonth;
      expect(find.text('실적을 불러오지 못했어요.'), findsOneWidget);
      await tester.tap(find.text('다시 시도').first);
      await tester.pumpAndSettle();
      expect(repository.lastPerformanceMonth, failedMonth);
      expect(find.text('실적을 불러오지 못했어요.'), findsNothing);
    },
  );

  testWidgets('refreshes a voucher balance after use', (tester) async {
    final repository = _Repository()..voucherAmount = 100000;
    repository.methods.add(
      const PaymentMethodOption(id: 'voucher', name: '온누리', kind: 'voucher'),
    );
    await tester.pumpWidget(
      localizedTestApp(
        home: PaymentMethodsScreen(
          repository: repository,
          contextData: await repository.loadContext(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('잔액 100,000원'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('사용'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('잔액 80,000원'), findsOneWidget);
  });
}
