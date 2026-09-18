// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '우리 가계부';

  @override
  String get calendar => '캘린더';

  @override
  String get history => '내역';

  @override
  String get wallet => '지갑';

  @override
  String get settings => '설정';

  @override
  String get record => '기록하기';

  @override
  String get directEntry => '직접 입력';

  @override
  String get directEntrySubtitle => '수입과 지출을 가계부에 저장';

  @override
  String get captureStatement => '이용내역 캡처';

  @override
  String get captureStatementSubtitle => '분석 예시 검토';

  @override
  String get calendarHeading => '함께 기록하는 하루';

  @override
  String get historyHeading => '우리의 수입과 지출';

  @override
  String get walletHeading => '결제 수단을 한곳에';

  @override
  String get calendarDescription => '날짜별 수입과 지출을 확인할 공간이에요.';

  @override
  String get historyDescription => '일·주·월별로 내역을 모아볼 공간이에요.';

  @override
  String get walletDescription => '카드 실적과 상품권 잔액을 관리할 공간이에요.';

  @override
  String get noTransactionsForDate => '선택한 날짜에 거래가 없어요.';

  @override
  String monthIncome(String amount) {
    return '이번 달 수입 $amount원';
  }

  @override
  String monthExpense(String amount) {
    return '이번 달 지출 $amount원';
  }

  @override
  String get noTransactions => '거래가 없는 기간이에요.';

  @override
  String get previewUnavailable => '화면 미리보기\n아직 가계부 데이터가 연결되지 않았어요.';

  @override
  String get loadHistoryFailed => '내역을 불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String get themeTitle => '앱 테마';

  @override
  String get themeDescription => '우리 가계부를 나만의 색으로\n선택한 테마는 이 기기에만 적용돼요.';

  @override
  String get selected => '선택됨';

  @override
  String get languageTitle => '언어';

  @override
  String get languageDescription => '앱에서 사용할 언어를 선택해 주세요.';

  @override
  String get korean => '한국어';

  @override
  String get english => '영어';

  @override
  String get accountHousehold => '계정 · 공동 가계부';

  @override
  String get accountComingSoon => '카카오 로그인과 배우자 초대는 다음 단계에서 연결할 예정이에요.';

  @override
  String get themeSaveFailed => '테마를 저장하지 못했어요. 다시 선택해 주세요.';

  @override
  String get languageSaveFailed => '언어를 저장하지 못했어요. 다시 선택해 주세요.';

  @override
  String get transactionSaved => '거래를 저장했어요.';

  @override
  String get transactionSaveFailed => '거래를 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get householdLoadFailed => '가계부 정보를 불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String get walletLoadFailedRetry => '지갑을 불러오지 못했어요. 다시 시도';

  @override
  String get paymentMethodsManage => '결제 수단 등록·관리';

  @override
  String get close => '닫기';

  @override
  String get expense => '지출';

  @override
  String get income => '수입';

  @override
  String get amount => '금액';

  @override
  String get won => '원';

  @override
  String formattedAmount(String amount) {
    return '$amount원';
  }

  @override
  String get date => '날짜';

  @override
  String get chooseDate => '날짜 선택';

  @override
  String get merchant => '사용처';

  @override
  String get incomeDescription => '수입 내용';

  @override
  String get category => '카테고리';

  @override
  String get paymentMethod => '결제 수단';

  @override
  String get depositMethod => '입금 수단';

  @override
  String get actualUser => '실제 사용자';

  @override
  String get memoOptional => '메모 (선택)';

  @override
  String get reviewEntry => '입력 내용 확인';

  @override
  String get entryGuide => '입력 내용 확인 후 가계부에 저장해요.';

  @override
  String get cancel => '취소';

  @override
  String get today => '오늘';

  @override
  String get choose => '선택';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get register => '등록';

  @override
  String get archive => '보관';

  @override
  String get discard => '버리기';

  @override
  String get continueEditing => '계속 작성';

  @override
  String get stopEntryTitle => '입력을 그만할까요?';

  @override
  String get stopEntryBody => '작성 중인 내용은 저장되지 않아요.';

  @override
  String get backToEdit => '돌아가서 수정';

  @override
  String get finalize => '확정';

  @override
  String get addPaymentMethod => '결제 수단 등록하기';

  @override
  String get selectRequired => '선택해 주세요.';

  @override
  String get amountValidation => '1~999,999,999원의 정수를 입력해 주세요.';

  @override
  String get contentRequired => '내용을 입력해 주세요.';

  @override
  String get dateValidation => '2000~2100년 사이의 실제 날짜를 선택해 주세요.';

  @override
  String get previewOnly => '미리보기이며 실제 가계부에는 저장되지 않아요.';

  @override
  String get confirmToSave => '확인 후 저장할 수 있어요.';

  @override
  String get paymentMethods => '결제 수단';

  @override
  String get paymentMethodsDescription => '카드 실적과 거래 입력에 사용할 수단을 등록해요.';

  @override
  String get registerVoucher => '상품권 등록';

  @override
  String get registerPaymentMethod => '결제 수단 등록';

  @override
  String get noPaymentMethods => '등록된 결제 수단이 없어요.';

  @override
  String get registerFirstMethod => '첫 수단 등록';

  @override
  String get cash => '현금';

  @override
  String get bank => '계좌';

  @override
  String get debitCard => '체크카드';

  @override
  String get creditCard => '신용카드';

  @override
  String get voucher => '상품권';

  @override
  String get paymentMethodManagement => '결제 수단 관리';

  @override
  String get editTarget => '실적 목표 수정';

  @override
  String get initialBalanceTopUp => '초기 잔액·충전';

  @override
  String get use => '사용';

  @override
  String balance(String amount) {
    return '잔액 $amount원';
  }

  @override
  String cardProgress(String actual, String target) {
    return '이번 달 $actual원 / 목표 $target원';
  }

  @override
  String get receiptReview => '이용내역 검토';

  @override
  String get receiptFixtureDescription =>
      '분석 예시\n고정 예시 데이터를 확인하고 수정할 수 있어요. 실제 이미지 분석은 준비 중입니다.';

  @override
  String saveCount(int count) {
    return '$count건 저장';
  }

  @override
  String get loginTagline => '둘이 함께 기록하는 생활비';

  @override
  String get loginWithKakao => '카카오로 시작하기';

  @override
  String get loginLoading => '카카오 로그인 준비 중…';

  @override
  String get salary => '급여';

  @override
  String get allowance => '용돈';

  @override
  String get food => '식비';

  @override
  String get living => '생활';

  @override
  String get transportation => '교통';

  @override
  String get housing => '주거';

  @override
  String get shopping => '쇼핑';

  @override
  String get other => '기타';

  @override
  String get methodRequired => '등록된 수단을 선택해 주세요.';

  @override
  String get memberRequired => '구성원을 선택해 주세요.';

  @override
  String get paymentAdded => '결제 수단을 등록했어요.';

  @override
  String get paymentAddFailed => '결제 수단을 등록하지 못했어요. 다시 시도해 주세요.';

  @override
  String get archivePaymentTitle => '결제 수단을 보관할까요?';

  @override
  String archivePaymentBody(String name) {
    return '$name은(는) 새 거래 입력에서 숨겨져요.';
  }

  @override
  String get archivePaymentFailed => '결제 수단을 보관하지 못했어요. 다시 시도해 주세요.';

  @override
  String get voucherUse => '상품권 사용';

  @override
  String get voucherTopUp => '상품권 초기 잔액·충전';

  @override
  String get actualPaidAmount => '실제 결제 금액';

  @override
  String get useAmount => '사용 금액';

  @override
  String get voucherTopUpAmount => '상품권 충전액';

  @override
  String get voucherRecorded => '상품권 내역을 기록했어요.';

  @override
  String get voucherSaveFailed => '상품권 내역을 저장하지 못했어요.';

  @override
  String editTargetTitle(String name) {
    return '$name 실적 목표 수정';
  }

  @override
  String get monthlyTarget => '월 목표';

  @override
  String get targetSaveFailed => '실적 목표를 수정하지 못했어요.';

  @override
  String get performanceLoadFailed => '실적을 불러오지 못했어요.';

  @override
  String get balanceLoadFailed => '잔액을 불러오지 못했어요.';

  @override
  String get balanceLoading => '잔액을 불러오는 중…';

  @override
  String get kind => '종류';

  @override
  String get nameExample => '이름 (예: 국민 체크카드)';

  @override
  String get nameRequired => '이름을 입력해 주세요.';

  @override
  String get paidAmountRequired => '결제 금액을 입력해 주세요.';

  @override
  String get topUpAmountRequired => '충전액을 입력해 주세요.';

  @override
  String get targetAmountRequired => '목표 금액을 입력해 주세요.';

  @override
  String get monthlyPerformanceTarget => '월 실적 목표';

  @override
  String get ownerOptional => '소유자 (선택)';

  @override
  String get none => '선택 안 함';

  @override
  String usedBy(String name) {
    return ' · $name 사용';
  }

  @override
  String get backToEntry => '거래 입력으로 돌아가기';

  @override
  String get paymentLoadFailed => '결제 수단을 불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String transactionSaveFailedCode(String code) {
    return '거래를 저장하지 못했어요. ($code)';
  }

  @override
  String get receiptSaveFailed => '선택 항목을 저장하지 못했어요. 값을 확인하고 다시 시도해 주세요.';

  @override
  String get receiptAnalyzing => '분석 중…';

  @override
  String get receiptChooseImage => '이용내역 이미지 선택';

  @override
  String get receiptEmpty => '이미지를 선택하면 분석 결과가 여기에 표시됩니다.';

  @override
  String get receiptMerchantMissing => '사용처 미입력';

  @override
  String get receiptImageSize => '10MB 이하의 이미지를 선택해 주세요.';

  @override
  String get receiptProviderMissing => '이미지 분석 제공자가 설정되지 않았어요.';

  @override
  String get receiptRateLimited => '오늘 분석 한도를 초과했어요. 내일 다시 시도해 주세요.';

  @override
  String get receiptProviderUnauthorized => 'OpenRouter 인증 키가 유효하지 않아요.';

  @override
  String get receiptProviderModelUnavailable => '현재 분석 모델을 사용할 수 없어요.';

  @override
  String get receiptProviderRequestInvalid => '분석 요청 형식이 거부됐어요.';

  @override
  String get receiptTimeout => '분석 시간이 초과됐어요. 다시 시도해 주세요.';

  @override
  String get receiptInvalidImage => '유효한 JPEG 또는 PNG 이미지를 선택해 주세요.';

  @override
  String get receiptAnalysisFailed => '이미지 분석에 실패했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get receiptNetworkFailed => '네트워크 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get saving => '저장 중…';

  @override
  String get loginCancelled => '로그인을 취소했어요.';

  @override
  String get loginFailed => '카카오 로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get fixtureMarket => '예시 마트';

  @override
  String get fixtureCafe => '예시 카페';

  @override
  String get fixtureReason => '고정 데이터 분석 예시';

  @override
  String get configRequiredTitle => '인증 설정이 필요해요';

  @override
  String get configRequiredBody =>
      'Supabase와 카카오 로그인 설정 후 실행할 수 있어요.\n\nSUPABASE_URL\nSUPABASE_PUBLISHABLE_KEY\nAUTH_REDIRECT_URL\n\n세 값은 --dart-define으로 전달해 주세요.';

  @override
  String get themeForest => '숲과 크림';

  @override
  String get themeOcean => '바다와 모래';

  @override
  String get themeLavender => '라벤더 밀크';

  @override
  String get themeRose => '로즈 티';

  @override
  String get themeOlive => '모노 올리브';

  @override
  String get themeTerracotta => '살구빛 테라코타';

  @override
  String get themeLemon => '레몬 가든';

  @override
  String get themeMint => '민트 소다';

  @override
  String get themeCocoa => '코코아 라떼';

  @override
  String get themeIndigo => '인디고 구름';

  @override
  String get themePlum => '자두와 살구';

  @override
  String get themeSky => '맑은 하늘';
}
