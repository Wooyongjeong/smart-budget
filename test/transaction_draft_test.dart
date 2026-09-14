import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/transactions/transaction_draft.dart';

void main() {
  test('copyWith preserves omitted fields and replaces supplied fields', () {
    final original = TransactionDraft(
      kind: TransactionKind.expense,
      occurredOn: DateTime(2026, 9, 14),
      amountWon: null,
      merchant: '마트',
      category: '식비',
      paymentMethodId: 'cash',
      memberId: 'me',
      memo: '주말',
    );
    final updated = original.copyWith(amountWon: 93000, merchant: '시장');
    expect(updated.amountWon, 93000);
    expect(updated.merchant, '시장');
    expect(updated.kind, TransactionKind.expense);
    expect(updated.category, '식비');
    expect(original.amountWon, isNull);
    expect(original.merchant, '마트');
  });
}
