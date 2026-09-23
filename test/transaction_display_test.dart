import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_budget/features/transactions/transaction_display.dart';
import 'package:smart_budget/l10n/generated/app_localizations.dart';

void main() {
  test('maps stored default labels without changing user data', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ko = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(localizedMerchantName(en, '상품권 사용'), 'Use voucher');
    expect(localizedMerchantName(ko, '상품권 사용'), '상품권 사용');
    expect(localizedHouseholdName(en, '우리 가계부'), 'Our Budget');
    expect(localizedHouseholdName(en, 'My custom budget'), 'My custom budget');
    expect(en.receiptItemsFound(2), '2 items found');
    expect(ko.receiptItemsFound(2), '2개 찾음');
  });
}
