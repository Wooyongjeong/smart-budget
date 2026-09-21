// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Our Budget';

  @override
  String get calendar => 'Calendar';

  @override
  String get history => 'History';

  @override
  String get wallet => 'Wallet';

  @override
  String get settings => 'Settings';

  @override
  String get record => 'Add record';

  @override
  String get directEntry => 'Manual entry';

  @override
  String get directEntrySubtitle => 'Save income and expenses';

  @override
  String get captureStatement => 'Upload statement';

  @override
  String get captureStatementSubtitle => 'Review analysis sample';

  @override
  String get calendarHeading => 'Our daily budget';

  @override
  String get historyHeading => 'Income and expenses';

  @override
  String get walletHeading => 'Payment methods';

  @override
  String get calendarDescription => 'View income and expenses by date.';

  @override
  String get historyDescription => 'Browse daily, weekly, and monthly records.';

  @override
  String get walletDescription => 'Track card spending and voucher balances.';

  @override
  String get noTransactionsForDate => 'No transactions on the selected date.';

  @override
  String monthIncome(String amount) {
    return 'Income this month: ₩$amount';
  }

  @override
  String monthExpense(String amount) {
    return 'Expenses this month: ₩$amount';
  }

  @override
  String get noTransactions => 'No transactions in this period.';

  @override
  String get previewUnavailable =>
      'Preview mode\nBudget data is not connected yet.';

  @override
  String get loadHistoryFailed => 'Couldn\'t load your history. Try again.';

  @override
  String get themeTitle => 'App theme';

  @override
  String get themeDescription =>
      'Choose colors for your budget.\nThe theme is saved only on this device.';

  @override
  String get selected => 'Selected';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDescription => 'Choose the language used in the app.';

  @override
  String get korean => 'Korean';

  @override
  String get english => 'English';

  @override
  String get accountHousehold => 'Account · Shared budget';

  @override
  String get accountComingSoon =>
      'Kakao login and partner invitations will be connected in a later step.';

  @override
  String get themeSaveFailed => 'Couldn\'t save the theme. Try again.';

  @override
  String get languageSaveFailed => 'Couldn\'t save the language. Try again.';

  @override
  String get transactionSaved => 'Transaction saved.';

  @override
  String get transactionSaveFailed =>
      'Couldn\'t save the transaction. Try again.';

  @override
  String get householdLoadFailed => 'Couldn\'t load the budget. Try again.';

  @override
  String get walletLoadFailedRetry => 'Couldn\'t load the wallet. Try again';

  @override
  String get paymentMethodsManage => 'Add or manage payment methods';

  @override
  String get close => 'Close';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get amount => 'Amount';

  @override
  String get won => 'KRW';

  @override
  String formattedAmount(String amount) {
    return '₩$amount';
  }

  @override
  String get date => 'Date';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get merchant => 'Merchant';

  @override
  String get incomeDescription => 'Income description';

  @override
  String get category => 'Category';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get depositMethod => 'Deposit method';

  @override
  String get actualUser => 'Used by';

  @override
  String get memoOptional => 'Memo (optional)';

  @override
  String get reviewEntry => 'Review entry';

  @override
  String get entryGuide => 'Review the details before saving.';

  @override
  String get cancel => 'Cancel';

  @override
  String get today => 'Today';

  @override
  String get choose => 'Select';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get register => 'Add';

  @override
  String get archive => 'Archive';

  @override
  String get discard => 'Discard';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get stopEntryTitle => 'Stop entering this transaction?';

  @override
  String get stopEntryBody => 'Your changes won\'t be saved.';

  @override
  String get backToEdit => 'Go back';

  @override
  String get finalize => 'Confirm';

  @override
  String get addPaymentMethod => 'Add a payment method';

  @override
  String get selectRequired => 'Please select an option.';

  @override
  String get amountValidation =>
      'Enter a whole amount from 1 to 999,999,999 KRW.';

  @override
  String get contentRequired => 'Enter a description.';

  @override
  String get dateValidation => 'Choose a valid date between 2000 and 2100.';

  @override
  String get previewOnly => 'This is a preview and won\'t be saved.';

  @override
  String get confirmToSave => 'Confirm to save this transaction.';

  @override
  String get paymentMethods => 'Payment methods';

  @override
  String get paymentMethodsDescription =>
      'Add methods used for card goals and transactions.';

  @override
  String get registerVoucher => 'Add voucher';

  @override
  String get registerPaymentMethod => 'Add payment method';

  @override
  String get noPaymentMethods => 'No payment methods yet.';

  @override
  String get registerFirstMethod => 'Add the first method';

  @override
  String get cash => 'Cash';

  @override
  String get bank => 'Bank account';

  @override
  String get debitCard => 'Debit card';

  @override
  String get creditCard => 'Credit card';

  @override
  String get voucher => 'Voucher';

  @override
  String get paymentMethodManagement => 'Manage payment methods';

  @override
  String get editTarget => 'Edit spending goal';

  @override
  String get initialBalanceTopUp => 'Initial balance · Top up';

  @override
  String get use => 'Use';

  @override
  String balance(String amount) {
    return 'Balance ₩$amount';
  }

  @override
  String cardProgress(String actual, String target) {
    return 'This month ₩$actual / Goal ₩$target';
  }

  @override
  String get receiptReview => 'Review statement';

  @override
  String get receiptFixtureDescription =>
      'Analysis sample\nReview and edit fixture data. Image analysis is coming soon.';

  @override
  String saveCount(int count) {
    return 'Save $count items';
  }

  @override
  String get loginTagline => 'Household spending, recorded together';

  @override
  String get loginWithKakao => 'Continue with Kakao';

  @override
  String get loginLoading => 'Preparing Kakao login…';

  @override
  String get salary => 'Salary';

  @override
  String get allowance => 'Allowance';

  @override
  String get food => 'Food';

  @override
  String get living => 'Living';

  @override
  String get transportation => 'Transportation';

  @override
  String get housing => 'Housing';

  @override
  String get shopping => 'Shopping';

  @override
  String get other => 'Other';

  @override
  String get methodRequired => 'Select a registered payment method.';

  @override
  String get memberRequired => 'Select a household member.';

  @override
  String get paymentAdded => 'Payment method added.';

  @override
  String get paymentAddFailed => 'Couldn\'t add the payment method. Try again.';

  @override
  String get archivePaymentTitle => 'Archive this payment method?';

  @override
  String archivePaymentBody(String name) {
    return '$name will be hidden from new transactions.';
  }

  @override
  String get archivePaymentFailed =>
      'Couldn\'t archive the payment method. Try again.';

  @override
  String get voucherUse => 'Use voucher';

  @override
  String get voucherTopUp => 'Initial balance · Top up';

  @override
  String get actualPaidAmount => 'Amount paid';

  @override
  String get useAmount => 'Amount used';

  @override
  String get voucherTopUpAmount => 'Voucher value';

  @override
  String get voucherRecorded => 'Voucher transaction saved.';

  @override
  String get voucherSaveFailed => 'Couldn\'t save the voucher transaction.';

  @override
  String editTargetTitle(String name) {
    return 'Edit $name spending goal';
  }

  @override
  String get monthlyTarget => 'Monthly goal';

  @override
  String get targetSaveFailed => 'Couldn\'t update the spending goal.';

  @override
  String get performanceLoadFailed => 'Couldn\'t load spending progress.';

  @override
  String get balanceLoadFailed => 'Couldn\'t load the balance.';

  @override
  String get balanceLoading => 'Loading balance…';

  @override
  String get kind => 'Type';

  @override
  String get nameExample => 'Name (e.g. Everyday debit card)';

  @override
  String get nameRequired => 'Enter a name.';

  @override
  String get paidAmountRequired => 'Enter the amount paid.';

  @override
  String get topUpAmountRequired => 'Enter the voucher value.';

  @override
  String get targetAmountRequired => 'Enter a goal amount.';

  @override
  String get monthlyPerformanceTarget => 'Monthly spending goal';

  @override
  String get ownerOptional => 'Owner (optional)';

  @override
  String get none => 'None';

  @override
  String usedBy(String name) {
    return ' · Used by $name';
  }

  @override
  String get backToEntry => 'Back to transaction entry';

  @override
  String get paymentLoadFailed => 'Couldn\'t load payment methods. Try again.';

  @override
  String transactionSaveFailedCode(String code) {
    return 'Couldn\'t save the transaction. ($code)';
  }

  @override
  String get receiptSaveFailed =>
      'Couldn\'t save the selected items. Check the values and try again.';

  @override
  String get receiptAnalyzing => 'Analyzing…';

  @override
  String get receiptChooseImage => 'Choose statement image';

  @override
  String get receiptEmpty => 'Choose an image to see the analysis here.';

  @override
  String get receiptMerchantMissing => 'Merchant required';

  @override
  String get receiptImageSize => 'Choose an image no larger than 10 MB.';

  @override
  String get receiptProviderMissing =>
      'The image analysis provider is not configured.';

  @override
  String get receiptRateLimited =>
      'Today\'s analysis limit has been reached. Try again tomorrow.';

  @override
  String get receiptProviderUnauthorized =>
      'The OpenRouter API key is invalid.';

  @override
  String get receiptProviderModelUnavailable =>
      'The analysis model is currently unavailable.';

  @override
  String get receiptProviderRequestInvalid =>
      'The analysis request was rejected.';

  @override
  String get receiptTimeout => 'Analysis timed out. Please try again.';

  @override
  String get receiptInvalidImage => 'Choose a valid JPEG or PNG image.';

  @override
  String get receiptAnalysisFailed =>
      'Image analysis failed. Please try again shortly.';

  @override
  String get receiptNetworkFailed =>
      'Check your network connection and try again.';

  @override
  String get saving => 'Saving…';

  @override
  String get loginCancelled => 'Login cancelled.';

  @override
  String get loginFailed =>
      'Something went wrong during Kakao login. Try again shortly.';

  @override
  String get fixtureMarket => 'Sample market';

  @override
  String get fixtureCafe => 'Sample cafe';

  @override
  String get fixtureReason => 'Fixed analysis fixture';

  @override
  String get configRequiredTitle => 'Authentication setup required';

  @override
  String get configRequiredBody =>
      'Configure Supabase and Kakao Login before running the app.\n\nSUPABASE_URL\nSUPABASE_PUBLISHABLE_KEY\nAUTH_REDIRECT_URL\n\nPass all three values with --dart-define.';

  @override
  String get themeForest => 'Forest Cream';

  @override
  String get themeOcean => 'Ocean Sand';

  @override
  String get themeLavender => 'Lavender Milk';

  @override
  String get themeRose => 'Rose Tea';

  @override
  String get themeOlive => 'Mono Olive';

  @override
  String get themeTerracotta => 'Apricot Terracotta';

  @override
  String get themeLemon => 'Lemon Garden';

  @override
  String get themeMint => 'Mint Soda';

  @override
  String get themeCocoa => 'Cocoa Latte';

  @override
  String get themeIndigo => 'Indigo Cloud';

  @override
  String get themePlum => 'Plum & Apricot';

  @override
  String get themeSky => 'Clear Sky';

  @override
  String get sharedHousehold => 'Shared budget';

  @override
  String get manageHouseholdDescription =>
      'View members and invite your partner.';

  @override
  String householdMembersCount(int count) {
    return '$count of 2 members';
  }

  @override
  String get me => 'Me';

  @override
  String get invitePartner => 'Invite your partner';

  @override
  String get invitationDescription =>
      'An invitation code can be used once within 7 days.';

  @override
  String get createInvitation => 'Create invitation code';

  @override
  String get invitationExpires => 'Share this code within 7 days.';

  @override
  String get copyInvitation => 'Copy invitation code';

  @override
  String get invitationCopied => 'Invitation code copied.';

  @override
  String get joinHousehold => 'Join with an invitation';

  @override
  String get invitationCode => '48-character invitation code';

  @override
  String get acceptInvitation => 'Join shared budget';

  @override
  String get invitationAccepted => 'You joined the shared budget.';

  @override
  String get invitationInvalid => 'Check the 48-character invitation code.';

  @override
  String get invitationExpiredOrUsed =>
      'This invitation has expired or was already used.';

  @override
  String get alreadyHouseholdMember =>
      'You are already a member of this shared budget.';

  @override
  String get householdFull => 'A shared budget can have up to two members.';

  @override
  String get householdUnavailable =>
      'This budget is no longer available to join.';

  @override
  String get householdForbidden =>
      'You do not have permission for this action.';

  @override
  String get householdActionFailed =>
      'Couldn\'t complete the shared budget action. Try again.';

  @override
  String get leaveHousehold => 'Leave shared budget';

  @override
  String get leaveHouseholdTitle => 'Leave the shared budget?';

  @override
  String get leaveHouseholdBody =>
      'You will immediately lose access to shared records and be signed out. Existing records remain available to the other member.';

  @override
  String get retry => 'Try again';

  @override
  String get shareInvitation => 'Invite via KakaoTalk';

  @override
  String get invitationOnboardingTitle => 'Join the shared budget?';

  @override
  String get invitationOnboardingDescription =>
      'This is an invitation from your partner. Confirm the code to start recording together.';

  @override
  String get skipInvitation => 'I\'ll join later';

  @override
  String get invitationLinkInvalid =>
      'We couldn\'t read this invitation link. Ask for a new one.';

  @override
  String get editDisplayName => 'Edit name';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameInvalid =>
      'Enter at least one character for your name.';

  @override
  String get nicknameOnboardingTitle => 'Choose a name for your budget';

  @override
  String get nicknameOnboardingDescription =>
      'This is the name shown when you record together. You can change it anytime.';

  @override
  String get nickname => 'Name';

  @override
  String get nicknameSave => 'Start with this name';

  @override
  String get nicknameInvalid => 'Enter at least one character.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutDescription =>
      'End the Kakao login session on this device.';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Only this device will be signed out. Your budget data won\'t be deleted.';

  @override
  String get signOutFailed => 'Couldn\'t sign out. Try again.';
}
