import '../../l10n/generated/app_localizations.dart';

String localizedMerchantName(AppLocalizations l10n, String merchant) =>
    switch (merchant) {
      '상품권 초기 잔액' => l10n.voucherInitialBalance,
      '상품권 구매' || '상품권 충전' => l10n.voucherTopUp,
      '상품권 사용' => l10n.voucherUse,
      _ => merchant,
    };

String localizedHouseholdName(AppLocalizations l10n, String name) =>
    name == '우리 가계부' ? l10n.appTitle : name;
