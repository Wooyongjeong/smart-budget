import 'package:flutter/foundation.dart';

enum TransactionKind { income, expense }

@immutable
class TransactionDraft {
  const TransactionDraft({
    required this.kind,
    required this.occurredOn,
    required this.amountWon,
    required this.merchant,
    required this.category,
    required this.paymentMethodId,
    required this.memberId,
    required this.memo,
  });
  final TransactionKind kind;
  final DateTime occurredOn;
  final int? amountWon;
  final String merchant;
  final String? category;
  final String? paymentMethodId;
  final String? memberId;
  final String memo;

  TransactionDraft copyWith({
    TransactionKind? kind,
    DateTime? occurredOn,
    int? amountWon,
    String? merchant,
    String? category,
    String? paymentMethodId,
    String? memberId,
    String? memo,
  }) => TransactionDraft(
    kind: kind ?? this.kind,
    occurredOn: occurredOn ?? this.occurredOn,
    amountWon: amountWon ?? this.amountWon,
    merchant: merchant ?? this.merchant,
    category: category ?? this.category,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    memberId: memberId ?? this.memberId,
    memo: memo ?? this.memo,
  );
}
