import 'transaction_draft.dart';
import 'transaction_repository.dart';

/// Keeps an idempotency key stable while the same direct-entry draft is retried.
class TransactionRequestTracker {
  String? _requestId;
  TransactionDraft? _draft;

  String requestIdFor(TransactionDraft draft) {
    if (_draft == null || !_sameDraft(_draft!, draft)) {
      _requestId = newTransactionRequestId();
      _draft = draft;
    }
    return _requestId!;
  }

  void markSucceeded() {
    _requestId = null;
    _draft = null;
  }

  bool _sameDraft(TransactionDraft a, TransactionDraft b) =>
      a.kind == b.kind &&
      a.occurredOn == b.occurredOn &&
      a.amountWon == b.amountWon &&
      a.merchant == b.merchant &&
      a.category == b.category &&
      a.paymentMethodId == b.paymentMethodId &&
      a.memberId == b.memberId &&
      a.memo == b.memo;
}
