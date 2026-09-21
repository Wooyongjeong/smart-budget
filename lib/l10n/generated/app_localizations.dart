import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'우리 가계부'**
  String get appTitle;

  /// No description provided for @calendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calendar;

  /// No description provided for @history.
  ///
  /// In ko, this message translates to:
  /// **'내역'**
  String get history;

  /// No description provided for @wallet.
  ///
  /// In ko, this message translates to:
  /// **'지갑'**
  String get wallet;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @record.
  ///
  /// In ko, this message translates to:
  /// **'기록하기'**
  String get record;

  /// No description provided for @directEntry.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get directEntry;

  /// No description provided for @directEntrySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'수입과 지출을 가계부에 저장'**
  String get directEntrySubtitle;

  /// No description provided for @captureStatement.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 캡처'**
  String get captureStatement;

  /// No description provided for @captureStatementSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'분석 예시 검토'**
  String get captureStatementSubtitle;

  /// No description provided for @calendarHeading.
  ///
  /// In ko, this message translates to:
  /// **'함께 기록하는 하루'**
  String get calendarHeading;

  /// No description provided for @historyHeading.
  ///
  /// In ko, this message translates to:
  /// **'우리의 수입과 지출'**
  String get historyHeading;

  /// No description provided for @walletHeading.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 한곳에'**
  String get walletHeading;

  /// No description provided for @calendarDescription.
  ///
  /// In ko, this message translates to:
  /// **'날짜별 수입과 지출을 확인할 공간이에요.'**
  String get calendarDescription;

  /// No description provided for @historyDescription.
  ///
  /// In ko, this message translates to:
  /// **'일·주·월별로 내역을 모아볼 공간이에요.'**
  String get historyDescription;

  /// No description provided for @walletDescription.
  ///
  /// In ko, this message translates to:
  /// **'카드 실적과 상품권 잔액을 관리할 공간이에요.'**
  String get walletDescription;

  /// No description provided for @noTransactionsForDate.
  ///
  /// In ko, this message translates to:
  /// **'선택한 날짜에 거래가 없어요.'**
  String get noTransactionsForDate;

  /// No description provided for @monthIncome.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 수입 {amount}원'**
  String monthIncome(String amount);

  /// No description provided for @monthExpense.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지출 {amount}원'**
  String monthExpense(String amount);

  /// No description provided for @noTransactions.
  ///
  /// In ko, this message translates to:
  /// **'거래가 없는 기간이에요.'**
  String get noTransactions;

  /// No description provided for @previewUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'화면 미리보기\n아직 가계부 데이터가 연결되지 않았어요.'**
  String get previewUnavailable;

  /// No description provided for @loadHistoryFailed.
  ///
  /// In ko, this message translates to:
  /// **'내역을 불러오지 못했어요. 다시 시도해 주세요.'**
  String get loadHistoryFailed;

  /// No description provided for @themeTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 테마'**
  String get themeTitle;

  /// No description provided for @themeDescription.
  ///
  /// In ko, this message translates to:
  /// **'우리 가계부를 나만의 색으로\n선택한 테마는 이 기기에만 적용돼요.'**
  String get themeDescription;

  /// No description provided for @selected.
  ///
  /// In ko, this message translates to:
  /// **'선택됨'**
  String get selected;

  /// No description provided for @languageTitle.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In ko, this message translates to:
  /// **'앱에서 사용할 언어를 선택해 주세요.'**
  String get languageDescription;

  /// No description provided for @korean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @english.
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get english;

  /// No description provided for @accountHousehold.
  ///
  /// In ko, this message translates to:
  /// **'계정 · 공동 가계부'**
  String get accountHousehold;

  /// No description provided for @accountComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인과 배우자 초대는 다음 단계에서 연결할 예정이에요.'**
  String get accountComingSoon;

  /// No description provided for @themeSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'테마를 저장하지 못했어요. 다시 선택해 주세요.'**
  String get themeSaveFailed;

  /// No description provided for @languageSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'언어를 저장하지 못했어요. 다시 선택해 주세요.'**
  String get languageSaveFailed;

  /// No description provided for @transactionSaved.
  ///
  /// In ko, this message translates to:
  /// **'거래를 저장했어요.'**
  String get transactionSaved;

  /// No description provided for @transactionSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'거래를 저장하지 못했어요. 다시 시도해 주세요.'**
  String get transactionSaveFailed;

  /// No description provided for @householdLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'가계부 정보를 불러오지 못했어요. 다시 시도해 주세요.'**
  String get householdLoadFailed;

  /// No description provided for @walletLoadFailedRetry.
  ///
  /// In ko, this message translates to:
  /// **'지갑을 불러오지 못했어요. 다시 시도'**
  String get walletLoadFailedRetry;

  /// No description provided for @paymentMethodsManage.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 등록·관리'**
  String get paymentMethodsManage;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @expense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get income;

  /// No description provided for @amount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get amount;

  /// No description provided for @won.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get won;

  /// No description provided for @formattedAmount.
  ///
  /// In ko, this message translates to:
  /// **'{amount}원'**
  String formattedAmount(String amount);

  /// No description provided for @date.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get date;

  /// No description provided for @chooseDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get chooseDate;

  /// No description provided for @merchant.
  ///
  /// In ko, this message translates to:
  /// **'사용처'**
  String get merchant;

  /// No description provided for @incomeDescription.
  ///
  /// In ko, this message translates to:
  /// **'수입 내용'**
  String get incomeDescription;

  /// No description provided for @category.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get category;

  /// No description provided for @paymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단'**
  String get paymentMethod;

  /// No description provided for @depositMethod.
  ///
  /// In ko, this message translates to:
  /// **'입금 수단'**
  String get depositMethod;

  /// No description provided for @actualUser.
  ///
  /// In ko, this message translates to:
  /// **'실제 사용자'**
  String get actualUser;

  /// No description provided for @memoOptional.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get memoOptional;

  /// No description provided for @reviewEntry.
  ///
  /// In ko, this message translates to:
  /// **'입력 내용 확인'**
  String get reviewEntry;

  /// No description provided for @entryGuide.
  ///
  /// In ko, this message translates to:
  /// **'입력 내용 확인 후 가계부에 저장해요.'**
  String get entryGuide;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @choose.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get choose;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @register.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get register;

  /// No description provided for @archive.
  ///
  /// In ko, this message translates to:
  /// **'보관'**
  String get archive;

  /// No description provided for @discard.
  ///
  /// In ko, this message translates to:
  /// **'버리기'**
  String get discard;

  /// No description provided for @continueEditing.
  ///
  /// In ko, this message translates to:
  /// **'계속 작성'**
  String get continueEditing;

  /// No description provided for @stopEntryTitle.
  ///
  /// In ko, this message translates to:
  /// **'입력을 그만할까요?'**
  String get stopEntryTitle;

  /// No description provided for @stopEntryBody.
  ///
  /// In ko, this message translates to:
  /// **'작성 중인 내용은 저장되지 않아요.'**
  String get stopEntryBody;

  /// No description provided for @backToEdit.
  ///
  /// In ko, this message translates to:
  /// **'돌아가서 수정'**
  String get backToEdit;

  /// No description provided for @finalize.
  ///
  /// In ko, this message translates to:
  /// **'확정'**
  String get finalize;

  /// No description provided for @addPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 등록하기'**
  String get addPaymentMethod;

  /// No description provided for @selectRequired.
  ///
  /// In ko, this message translates to:
  /// **'선택해 주세요.'**
  String get selectRequired;

  /// No description provided for @amountValidation.
  ///
  /// In ko, this message translates to:
  /// **'1~999,999,999원의 정수를 입력해 주세요.'**
  String get amountValidation;

  /// No description provided for @contentRequired.
  ///
  /// In ko, this message translates to:
  /// **'내용을 입력해 주세요.'**
  String get contentRequired;

  /// No description provided for @dateValidation.
  ///
  /// In ko, this message translates to:
  /// **'2000~2100년 사이의 실제 날짜를 선택해 주세요.'**
  String get dateValidation;

  /// No description provided for @previewOnly.
  ///
  /// In ko, this message translates to:
  /// **'미리보기이며 실제 가계부에는 저장되지 않아요.'**
  String get previewOnly;

  /// No description provided for @confirmToSave.
  ///
  /// In ko, this message translates to:
  /// **'확인 후 저장할 수 있어요.'**
  String get confirmToSave;

  /// No description provided for @paymentMethods.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단'**
  String get paymentMethods;

  /// No description provided for @paymentMethodsDescription.
  ///
  /// In ko, this message translates to:
  /// **'카드 실적과 거래 입력에 사용할 수단을 등록해요.'**
  String get paymentMethodsDescription;

  /// No description provided for @registerVoucher.
  ///
  /// In ko, this message translates to:
  /// **'상품권 등록'**
  String get registerVoucher;

  /// No description provided for @registerPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 등록'**
  String get registerPaymentMethod;

  /// No description provided for @noPaymentMethods.
  ///
  /// In ko, this message translates to:
  /// **'등록된 결제 수단이 없어요.'**
  String get noPaymentMethods;

  /// No description provided for @registerFirstMethod.
  ///
  /// In ko, this message translates to:
  /// **'첫 수단 등록'**
  String get registerFirstMethod;

  /// No description provided for @cash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get cash;

  /// No description provided for @bank.
  ///
  /// In ko, this message translates to:
  /// **'계좌'**
  String get bank;

  /// No description provided for @debitCard.
  ///
  /// In ko, this message translates to:
  /// **'체크카드'**
  String get debitCard;

  /// No description provided for @creditCard.
  ///
  /// In ko, this message translates to:
  /// **'신용카드'**
  String get creditCard;

  /// No description provided for @voucher.
  ///
  /// In ko, this message translates to:
  /// **'상품권'**
  String get voucher;

  /// No description provided for @paymentMethodManagement.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단 관리'**
  String get paymentMethodManagement;

  /// No description provided for @editTarget.
  ///
  /// In ko, this message translates to:
  /// **'실적 목표 수정'**
  String get editTarget;

  /// No description provided for @initialBalanceTopUp.
  ///
  /// In ko, this message translates to:
  /// **'초기 잔액·충전'**
  String get initialBalanceTopUp;

  /// No description provided for @use.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get use;

  /// No description provided for @balance.
  ///
  /// In ko, this message translates to:
  /// **'잔액 {amount}원'**
  String balance(String amount);

  /// No description provided for @cardProgress.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {actual}원 / 목표 {target}원'**
  String cardProgress(String actual, String target);

  /// No description provided for @receiptReview.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 검토'**
  String get receiptReview;

  /// No description provided for @receiptFixtureDescription.
  ///
  /// In ko, this message translates to:
  /// **'분석 예시\n고정 예시 데이터를 확인하고 수정할 수 있어요. 실제 이미지 분석은 준비 중입니다.'**
  String get receiptFixtureDescription;

  /// No description provided for @saveCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 저장'**
  String saveCount(int count);

  /// No description provided for @loginTagline.
  ///
  /// In ko, this message translates to:
  /// **'둘이 함께 기록하는 생활비'**
  String get loginTagline;

  /// No description provided for @loginWithKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 시작하기'**
  String get loginWithKakao;

  /// No description provided for @loginLoading.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 준비 중…'**
  String get loginLoading;

  /// No description provided for @salary.
  ///
  /// In ko, this message translates to:
  /// **'급여'**
  String get salary;

  /// No description provided for @allowance.
  ///
  /// In ko, this message translates to:
  /// **'용돈'**
  String get allowance;

  /// No description provided for @food.
  ///
  /// In ko, this message translates to:
  /// **'식비'**
  String get food;

  /// No description provided for @living.
  ///
  /// In ko, this message translates to:
  /// **'생활'**
  String get living;

  /// No description provided for @transportation.
  ///
  /// In ko, this message translates to:
  /// **'교통'**
  String get transportation;

  /// No description provided for @housing.
  ///
  /// In ko, this message translates to:
  /// **'주거'**
  String get housing;

  /// No description provided for @shopping.
  ///
  /// In ko, this message translates to:
  /// **'쇼핑'**
  String get shopping;

  /// No description provided for @other.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get other;

  /// No description provided for @methodRequired.
  ///
  /// In ko, this message translates to:
  /// **'등록된 수단을 선택해 주세요.'**
  String get methodRequired;

  /// No description provided for @memberRequired.
  ///
  /// In ko, this message translates to:
  /// **'구성원을 선택해 주세요.'**
  String get memberRequired;

  /// No description provided for @paymentAdded.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 등록했어요.'**
  String get paymentAdded;

  /// No description provided for @paymentAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 등록하지 못했어요. 다시 시도해 주세요.'**
  String get paymentAddFailed;

  /// No description provided for @archivePaymentTitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 보관할까요?'**
  String get archivePaymentTitle;

  /// No description provided for @archivePaymentBody.
  ///
  /// In ko, this message translates to:
  /// **'{name}은(는) 새 거래 입력에서 숨겨져요.'**
  String archivePaymentBody(String name);

  /// No description provided for @archivePaymentFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 보관하지 못했어요. 다시 시도해 주세요.'**
  String get archivePaymentFailed;

  /// No description provided for @voucherUse.
  ///
  /// In ko, this message translates to:
  /// **'상품권 사용'**
  String get voucherUse;

  /// No description provided for @voucherTopUp.
  ///
  /// In ko, this message translates to:
  /// **'상품권 초기 잔액·충전'**
  String get voucherTopUp;

  /// No description provided for @actualPaidAmount.
  ///
  /// In ko, this message translates to:
  /// **'실제 결제 금액'**
  String get actualPaidAmount;

  /// No description provided for @useAmount.
  ///
  /// In ko, this message translates to:
  /// **'사용 금액'**
  String get useAmount;

  /// No description provided for @voucherTopUpAmount.
  ///
  /// In ko, this message translates to:
  /// **'상품권 충전액'**
  String get voucherTopUpAmount;

  /// No description provided for @voucherRecorded.
  ///
  /// In ko, this message translates to:
  /// **'상품권 내역을 기록했어요.'**
  String get voucherRecorded;

  /// No description provided for @voucherSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'상품권 내역을 저장하지 못했어요.'**
  String get voucherSaveFailed;

  /// No description provided for @editTargetTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 실적 목표 수정'**
  String editTargetTitle(String name);

  /// No description provided for @monthlyTarget.
  ///
  /// In ko, this message translates to:
  /// **'월 목표'**
  String get monthlyTarget;

  /// No description provided for @targetSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'실적 목표를 수정하지 못했어요.'**
  String get targetSaveFailed;

  /// No description provided for @performanceLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'실적을 불러오지 못했어요.'**
  String get performanceLoadFailed;

  /// No description provided for @balanceLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'잔액을 불러오지 못했어요.'**
  String get balanceLoadFailed;

  /// No description provided for @balanceLoading.
  ///
  /// In ko, this message translates to:
  /// **'잔액을 불러오는 중…'**
  String get balanceLoading;

  /// No description provided for @kind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get kind;

  /// No description provided for @nameExample.
  ///
  /// In ko, this message translates to:
  /// **'이름 (예: 국민 체크카드)'**
  String get nameExample;

  /// No description provided for @nameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해 주세요.'**
  String get nameRequired;

  /// No description provided for @paidAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액을 입력해 주세요.'**
  String get paidAmountRequired;

  /// No description provided for @topUpAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'충전액을 입력해 주세요.'**
  String get topUpAmountRequired;

  /// No description provided for @targetAmountRequired.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액을 입력해 주세요.'**
  String get targetAmountRequired;

  /// No description provided for @monthlyPerformanceTarget.
  ///
  /// In ko, this message translates to:
  /// **'월 실적 목표'**
  String get monthlyPerformanceTarget;

  /// No description provided for @ownerOptional.
  ///
  /// In ko, this message translates to:
  /// **'소유자 (선택)'**
  String get ownerOptional;

  /// No description provided for @none.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get none;

  /// No description provided for @usedBy.
  ///
  /// In ko, this message translates to:
  /// **' · {name} 사용'**
  String usedBy(String name);

  /// No description provided for @backToEntry.
  ///
  /// In ko, this message translates to:
  /// **'거래 입력으로 돌아가기'**
  String get backToEntry;

  /// No description provided for @paymentLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단을 불러오지 못했어요. 다시 시도해 주세요.'**
  String get paymentLoadFailed;

  /// No description provided for @transactionSaveFailedCode.
  ///
  /// In ko, this message translates to:
  /// **'거래를 저장하지 못했어요. ({code})'**
  String transactionSaveFailedCode(String code);

  /// No description provided for @receiptSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'선택 항목을 저장하지 못했어요. 값을 확인하고 다시 시도해 주세요.'**
  String get receiptSaveFailed;

  /// No description provided for @receiptAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'분석 중…'**
  String get receiptAnalyzing;

  /// No description provided for @receiptChooseImage.
  ///
  /// In ko, this message translates to:
  /// **'이용내역 이미지 선택'**
  String get receiptChooseImage;

  /// No description provided for @receiptEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 선택하면 분석 결과가 여기에 표시됩니다.'**
  String get receiptEmpty;

  /// No description provided for @receiptMerchantMissing.
  ///
  /// In ko, this message translates to:
  /// **'사용처 미입력'**
  String get receiptMerchantMissing;

  /// No description provided for @receiptImageSize.
  ///
  /// In ko, this message translates to:
  /// **'10MB 이하의 이미지를 선택해 주세요.'**
  String get receiptImageSize;

  /// No description provided for @receiptProviderMissing.
  ///
  /// In ko, this message translates to:
  /// **'이미지 분석 제공자가 설정되지 않았어요.'**
  String get receiptProviderMissing;

  /// No description provided for @receiptRateLimited.
  ///
  /// In ko, this message translates to:
  /// **'오늘 분석 한도를 초과했어요. 내일 다시 시도해 주세요.'**
  String get receiptRateLimited;

  /// No description provided for @receiptProviderUnauthorized.
  ///
  /// In ko, this message translates to:
  /// **'OpenRouter 인증 키가 유효하지 않아요.'**
  String get receiptProviderUnauthorized;

  /// No description provided for @receiptProviderModelUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'현재 분석 모델을 사용할 수 없어요.'**
  String get receiptProviderModelUnavailable;

  /// No description provided for @receiptProviderRequestInvalid.
  ///
  /// In ko, this message translates to:
  /// **'분석 요청 형식이 거부됐어요.'**
  String get receiptProviderRequestInvalid;

  /// No description provided for @receiptTimeout.
  ///
  /// In ko, this message translates to:
  /// **'분석 시간이 초과됐어요. 다시 시도해 주세요.'**
  String get receiptTimeout;

  /// No description provided for @receiptInvalidImage.
  ///
  /// In ko, this message translates to:
  /// **'유효한 JPEG 또는 PNG 이미지를 선택해 주세요.'**
  String get receiptInvalidImage;

  /// No description provided for @receiptAnalysisFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 분석에 실패했어요. 잠시 후 다시 시도해 주세요.'**
  String get receiptAnalysisFailed;

  /// No description provided for @receiptNetworkFailed.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인하고 다시 시도해 주세요.'**
  String get receiptNetworkFailed;

  /// No description provided for @saving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중…'**
  String get saving;

  /// No description provided for @loginCancelled.
  ///
  /// In ko, this message translates to:
  /// **'로그인을 취소했어요.'**
  String get loginCancelled;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.'**
  String get loginFailed;

  /// No description provided for @fixtureMarket.
  ///
  /// In ko, this message translates to:
  /// **'예시 마트'**
  String get fixtureMarket;

  /// No description provided for @fixtureCafe.
  ///
  /// In ko, this message translates to:
  /// **'예시 카페'**
  String get fixtureCafe;

  /// No description provided for @fixtureReason.
  ///
  /// In ko, this message translates to:
  /// **'고정 데이터 분석 예시'**
  String get fixtureReason;

  /// No description provided for @configRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'인증 설정이 필요해요'**
  String get configRequiredTitle;

  /// No description provided for @configRequiredBody.
  ///
  /// In ko, this message translates to:
  /// **'Supabase와 카카오 로그인 설정 후 실행할 수 있어요.\n\nSUPABASE_URL\nSUPABASE_PUBLISHABLE_KEY\nAUTH_REDIRECT_URL\n\n세 값은 --dart-define으로 전달해 주세요.'**
  String get configRequiredBody;

  /// No description provided for @themeForest.
  ///
  /// In ko, this message translates to:
  /// **'숲과 크림'**
  String get themeForest;

  /// No description provided for @themeOcean.
  ///
  /// In ko, this message translates to:
  /// **'바다와 모래'**
  String get themeOcean;

  /// No description provided for @themeLavender.
  ///
  /// In ko, this message translates to:
  /// **'라벤더 밀크'**
  String get themeLavender;

  /// No description provided for @themeRose.
  ///
  /// In ko, this message translates to:
  /// **'로즈 티'**
  String get themeRose;

  /// No description provided for @themeOlive.
  ///
  /// In ko, this message translates to:
  /// **'모노 올리브'**
  String get themeOlive;

  /// No description provided for @themeTerracotta.
  ///
  /// In ko, this message translates to:
  /// **'살구빛 테라코타'**
  String get themeTerracotta;

  /// No description provided for @themeLemon.
  ///
  /// In ko, this message translates to:
  /// **'레몬 가든'**
  String get themeLemon;

  /// No description provided for @themeMint.
  ///
  /// In ko, this message translates to:
  /// **'민트 소다'**
  String get themeMint;

  /// No description provided for @themeCocoa.
  ///
  /// In ko, this message translates to:
  /// **'코코아 라떼'**
  String get themeCocoa;

  /// No description provided for @themeIndigo.
  ///
  /// In ko, this message translates to:
  /// **'인디고 구름'**
  String get themeIndigo;

  /// No description provided for @themePlum.
  ///
  /// In ko, this message translates to:
  /// **'자두와 살구'**
  String get themePlum;

  /// No description provided for @themeSky.
  ///
  /// In ko, this message translates to:
  /// **'맑은 하늘'**
  String get themeSky;

  /// No description provided for @sharedHousehold.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부'**
  String get sharedHousehold;

  /// No description provided for @manageHouseholdDescription.
  ///
  /// In ko, this message translates to:
  /// **'구성원을 확인하고 배우자를 초대해요.'**
  String get manageHouseholdDescription;

  /// No description provided for @householdMembersCount.
  ///
  /// In ko, this message translates to:
  /// **'구성원 {count}/2명'**
  String householdMembersCount(int count);

  /// No description provided for @me.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get me;

  /// No description provided for @invitePartner.
  ///
  /// In ko, this message translates to:
  /// **'배우자 초대'**
  String get invitePartner;

  /// No description provided for @invitationDescription.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드는 7일 동안 한 번만 사용할 수 있어요.'**
  String get invitationDescription;

  /// No description provided for @createInvitation.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 만들기'**
  String get createInvitation;

  /// No description provided for @invitationExpires.
  ///
  /// In ko, this message translates to:
  /// **'7일 이내에 전달해 주세요.'**
  String get invitationExpires;

  /// No description provided for @copyInvitation.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 복사'**
  String get copyInvitation;

  /// No description provided for @invitationCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 복사했어요.'**
  String get invitationCopied;

  /// No description provided for @joinHousehold.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드로 참여'**
  String get joinHousehold;

  /// No description provided for @invitationCode.
  ///
  /// In ko, this message translates to:
  /// **'48자리 초대 코드'**
  String get invitationCode;

  /// No description provided for @acceptInvitation.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부 참여'**
  String get acceptInvitation;

  /// No description provided for @invitationAccepted.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부에 참여했어요.'**
  String get invitationAccepted;

  /// No description provided for @invitationInvalid.
  ///
  /// In ko, this message translates to:
  /// **'48자리 초대 코드를 확인해 주세요.'**
  String get invitationInvalid;

  /// No description provided for @invitationExpiredOrUsed.
  ///
  /// In ko, this message translates to:
  /// **'만료되었거나 이미 사용한 초대 코드예요.'**
  String get invitationExpiredOrUsed;

  /// No description provided for @alreadyHouseholdMember.
  ///
  /// In ko, this message translates to:
  /// **'이미 이 공동 가계부에 참여 중이에요.'**
  String get alreadyHouseholdMember;

  /// No description provided for @householdFull.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부에는 두 명까지만 참여할 수 있어요.'**
  String get householdFull;

  /// No description provided for @householdUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'더 이상 참여할 수 없는 가계부예요.'**
  String get householdUnavailable;

  /// No description provided for @householdForbidden.
  ///
  /// In ko, this message translates to:
  /// **'이 가계부에서 해당 작업을 할 권한이 없어요.'**
  String get householdForbidden;

  /// No description provided for @householdActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부 작업을 완료하지 못했어요. 다시 시도해 주세요.'**
  String get householdActionFailed;

  /// No description provided for @leaveHousehold.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부 나가기'**
  String get leaveHousehold;

  /// No description provided for @leaveHouseholdTitle.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부를 나갈까요?'**
  String get leaveHouseholdTitle;

  /// No description provided for @leaveHouseholdBody.
  ///
  /// In ko, this message translates to:
  /// **'즉시 모든 공동 기록에 접근할 수 없게 되고 로그아웃돼요. 기존 기록은 남은 구성원에게 유지됩니다.'**
  String get leaveHouseholdBody;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @shareInvitation.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡으로 초대하기'**
  String get shareInvitation;

  /// No description provided for @invitationOnboardingTitle.
  ///
  /// In ko, this message translates to:
  /// **'공동 가계부에 참여할까요?'**
  String get invitationOnboardingTitle;

  /// No description provided for @invitationOnboardingDescription.
  ///
  /// In ko, this message translates to:
  /// **'배우자가 보낸 초대 링크예요. 코드를 확인한 뒤 함께 기록을 시작할 수 있어요.'**
  String get invitationOnboardingDescription;

  /// No description provided for @skipInvitation.
  ///
  /// In ko, this message translates to:
  /// **'나중에 참여할게요'**
  String get skipInvitation;

  /// No description provided for @invitationLinkInvalid.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 확인할 수 없어요. 다시 전달받아 주세요.'**
  String get invitationLinkInvalid;

  /// No description provided for @editDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'이름 수정'**
  String get editDisplayName;

  /// No description provided for @displayName.
  ///
  /// In ko, this message translates to:
  /// **'표시할 이름'**
  String get displayName;

  /// No description provided for @displayNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'이름을 한 글자 이상 입력해 주세요.'**
  String get displayNameInvalid;

  /// No description provided for @nicknameOnboardingTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부에서 사용할 이름을 정해요'**
  String get nicknameOnboardingTitle;

  /// No description provided for @nicknameOnboardingDescription.
  ///
  /// In ko, this message translates to:
  /// **'함께 기록할 때 보여줄 이름이에요. 언제든 수정할 수 있어요.'**
  String get nicknameOnboardingDescription;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get nickname;

  /// No description provided for @nicknameSave.
  ///
  /// In ko, this message translates to:
  /// **'이 이름으로 시작하기'**
  String get nicknameSave;

  /// No description provided for @nicknameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'이름을 한 글자 이상 입력해 주세요.'**
  String get nicknameInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
