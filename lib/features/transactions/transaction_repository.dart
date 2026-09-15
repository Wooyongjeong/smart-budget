import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'transaction_draft.dart';

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.kind,
    this.ownerMemberId,
  });
  final String id;
  final String name;
  final String kind;
  final String? ownerMemberId;
}

class MemberOption {
  const MemberOption({required this.id, required this.name});
  final String id;
  final String name;
}

class HouseholdContext {
  const HouseholdContext({
    required this.householdId,
    required this.paymentMethods,
    required this.members,
  });
  final String householdId;
  final List<PaymentMethodOption> paymentMethods;
  final List<MemberOption> members;
}

class TransactionQueryResult {
  const TransactionQueryResult({
    required this.items,
    required this.totalIncome,
    required this.totalExpense,
  });
  final List<Map<String, dynamic>> items;
  final int totalIncome;
  final int totalExpense;
}

abstract interface class TransactionRepository {
  Future<HouseholdContext> loadContext();
  Future<void> save(String householdId, TransactionDraft draft);
  Future<void> saveMany(String householdId, List<TransactionDraft> drafts);
  Future<PaymentMethodOption> addPaymentMethod(
    String householdId,
    String kind,
    String name,
    String? ownerMemberId,
  );
  Future<void> archivePaymentMethod(String householdId, String paymentMethodId);
  Future<void> recordVoucherEvent(
    String householdId,
    String kind,
    String voucherId,
    int paidAmountWon,
    int voucherAmountWon,
  );
  Future<List<Map<String, dynamic>>> cardPerformance(
    String householdId,
    DateTime month,
  );
  Future<void> setCardTarget(
    String householdId,
    String paymentMethodId,
    DateTime month,
    int targetAmountWon,
  );
  Future<int> voucherBalance(String householdId, String voucherId);
  Future<TransactionQueryResult> query(
    String householdId,
    DateTime start,
    DateTime end,
  );
}

class TransactionSaveException implements Exception {
  const TransactionSaveException(this.code);
  final String code;
  @override
  String toString() => 'TransactionSaveException($code)';
}

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;
  final SupabaseClient client;

  @override
  Future<HouseholdContext> loadContext() async {
    final rows = await client
        .from('households')
        .select('id')
        .order('created_at')
        .limit(1);
    String householdId;
    if (rows.isEmpty) {
      final created = await client.rpc(
        'create_household',
        params: {'p_name': '우리 가계부'},
      );
      householdId = created as String;
    } else {
      householdId = rows.first['id'] as String;
    }
    final methods = await client
        .from('payment_methods')
        .select('id,name,kind,owner_member_id')
        .eq('household_id', householdId)
        .isFilter('archived_at', null)
        .order('created_at');
    final members = await client
        .from('household_members')
        .select('id,user_id')
        .eq('household_id', householdId)
        .isFilter('left_at', null)
        .order('joined_at');
    return HouseholdContext(
      householdId: householdId,
      paymentMethods: methods
          .map(
            (row) => PaymentMethodOption(
              id: row['id'] as String,
              name: row['name'] as String,
              kind: row['kind'] as String,
              ownerMemberId: row['owner_member_id'] as String?,
            ),
          )
          .toList(growable: false),
      members: members
          .map((row) {
            return MemberOption(id: row['id'] as String, name: '구성원');
          })
          .toList(growable: false),
    );
  }

  @override
  Future<PaymentMethodOption> addPaymentMethod(
    String householdId,
    String kind,
    String name,
    String? ownerMemberId,
  ) async {
    final function = kind == 'debit_card' || kind == 'credit_card'
        ? 'add_card_payment_method'
        : 'add_payment_method';
    final id = await client.rpc(
      function,
      params: {
        'p_household_id': householdId,
        'p_kind': kind,
        'p_name': name,
        'p_owner_member_id': ownerMemberId,
      },
    );
    return PaymentMethodOption(
      id: id as String,
      name: name.trim(),
      kind: kind,
      ownerMemberId: ownerMemberId,
    );
  }

  @override
  Future<void> archivePaymentMethod(
    String householdId,
    String paymentMethodId,
  ) async {
    await client.rpc(
      'archive_payment_method',
      params: {
        'p_household_id': householdId,
        'p_payment_method_id': paymentMethodId,
      },
    );
  }

  @override
  Future<void> recordVoucherEvent(
    String householdId,
    String kind,
    String voucherId,
    int paidAmountWon,
    int voucherAmountWon,
  ) async {
    await client.rpc(
      'record_voucher_event',
      params: {
        'p_household_id': householdId,
        'p_kind': kind,
        'p_voucher_id': voucherId,
        'p_paid_amount_won': paidAmountWon,
        'p_voucher_amount_won': voucherAmountWon,
        'p_occurred_on': _dateOnly(DateTime.now()),
        'p_merchant': kind == 'voucher_topup' ? '상품권 충전' : '상품권 사용',
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> cardPerformance(
    String householdId,
    DateTime month,
  ) async {
    final result = await client.rpc(
      'card_performance',
      params: {
        'p_household_id': householdId,
        'p_target_month': _dateOnly(DateTime(month.year, month.month, 1)),
      },
    );
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> setCardTarget(
    String householdId,
    String paymentMethodId,
    DateTime month,
    int targetAmountWon,
  ) async {
    await client.rpc(
      'set_card_target',
      params: {
        'p_household_id': householdId,
        'p_payment_method_id': paymentMethodId,
        'p_target_month': _dateOnly(DateTime(month.year, month.month, 1)),
        'p_target_amount_won': targetAmountWon,
      },
    );
  }

  @override
  Future<int> voucherBalance(String householdId, String voucherId) async {
    final rows = await client
        .from('voucher_movements')
        .select('delta_won')
        .eq('household_id', householdId)
        .eq('voucher_id', voucherId);
    return rows.fold<int>(
      0,
      (sum, row) => sum + (row['delta_won'] as num).toInt(),
    );
  }

  @override
  Future<void> save(String householdId, TransactionDraft draft) async {
    await saveMany(householdId, [draft]);
  }

  @override
  Future<void> saveMany(
    String householdId,
    List<TransactionDraft> drafts,
  ) async {
    if (drafts.isEmpty) return;
    final requestId = _requestId();
    try {
      await client.rpc(
        'save_transactions',
        params: {
          'p_household_id': householdId,
          'p_request_id': requestId,
          'p_entries': drafts
              .map(
                (draft) => {
                  'kind': draft.kind.name,
                  'occurred_on': _dateOnly(draft.occurredOn),
                  'amount_won': draft.amountWon,
                  'merchant': draft.merchant,
                  'category': draft.category,
                  'payment_method_id': draft.paymentMethodId,
                  'member_id': draft.memberId,
                  'memo': draft.memo.isEmpty ? null : draft.memo,
                },
              )
              .toList(),
        },
      );
    } on PostgrestException catch (error) {
      throw TransactionSaveException(error.message);
    }
  }

  @override
  Future<TransactionQueryResult> query(
    String householdId,
    DateTime start,
    DateTime end,
  ) async {
    final result = await client.rpc(
      'query_transactions',
      params: {
        'p_household_id': householdId,
        'p_start_date': _dateOnly(start),
        'p_end_date': _dateOnly(end),
        'p_limit': 100,
      },
    );
    final data = result as Map<String, dynamic>;
    return TransactionQueryResult(
      items: (data['items'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      totalIncome: (data['total_income'] as num? ?? 0).toInt(),
      totalExpense: (data['total_expense'] as num? ?? 0).toInt(),
    );
  }
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _requestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
