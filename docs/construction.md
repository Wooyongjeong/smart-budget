# Construction 진행

## T13 — OpenRouter 카드 이용내역 이미지 분석

브랜치: `feat/t13-openrouter-receipt-analysis`.

Flutter에 `file_picker`를 연결해 macOS/iOS에서 JPEG·PNG를 선택하고, 인증된 Supabase Edge Function으로 이미지 바이트를 전송하도록 했다. 함수는 활성 가계부 구성원을 확인한 뒤 OpenRouter 무료 멀티모달 모델에 이미지와 추출 지시를 보내고, 응답 JSON의 날짜·금액·사용처·결제 수단 힌트·분류를 검증한다. reasoning을 제외하고 30초 timeout, 10MB·50건 상한, 429와 공급자 오류 매핑을 적용한다. 검토 화면에서는 항목 선택·날짜·사용처·금액·결제 수단을 수정한 뒤 일반 지출만 기존 일괄 저장 RPC로 저장한다. 환불·불명확 항목은 선택할 수 없고, 연도 누락 날짜는 사용자가 보완해야 한다.

합성 테스트 이미지 2장으로 OpenRouter 호출을 확인했다. 토스 캡처에서 7건, 신한카드 캡처에서 8건을 읽었고 카드 힌트와 결제 취소 분류를 확인했다. 호출 비용은 0으로 반환됐다. 무료 모델의 구조화 출력 옵션이 지원되지 않아 함수가 JSON 텍스트를 직접 파싱·검증한다.

검증: `flutter analyze --fatal-infos`, `flutter test`, `supabase functions serve analyze-receipt --no-verify-jwt` 기동 확인 통과. 실제 인증 세션을 통한 배포 함수 호출과 iOS 실기기 파일 선택은 아직 미실행이다. 함수 배포 전 Supabase Secret `OPENROUTER_API_KEY`와 선택적 `OPENROUTER_MODEL` 설정이 필요하다.

## 최종 병합 전 리뷰와 README

브랜치: `fix/document-contract-review`.

선택한 캘린더 월에 맞춰 거래 조회 범위를 갱신하고, 수입/일반 지출의 결제 수단 종류를 DB 계약과 일치시켰다. 상품권 잔액 로딩·오류 표시를 분리하고 테마 선택 체크 아이콘을 제거했다. README는 현재 구현 범위, Supabase/Kakao 설정, 실행·테스트 절차, 금액 규칙과 미완료 기능을 기준으로 다시 작성했다.

검증: `dart fix --dry-run` 수정 없음, `flutter analyze`, 전체 Flutter 테스트, macOS debug build, pgTAP 53개 통과. 로컬·원격 migration 이력 일치 확인.

## 문서 계약 재검토

브랜치: fix/document-contract-review. 상세 발견 사항과 미완료 항목은 [code-review.md](code-review.md).
card_performance 중첩 집계 SQL 오류와 상품권 충전 지출 누락을 새 migration으로 수정했다.
authenticated 역할의 실제 카드 목표/충전/사용 RPC 테스트를 추가해 93,000원 지출, 80,000원 잔액, 93,000원 카드 인정액을 확인했다.
직접 입력 중복 제출 차단, AI 저장 후 갱신, 지갑 조회 실패 재시도, 내부 오류 원문 노출도 수정했다.
검증: flutter analyze 통과, Flutter 13개, SQL 46개 통과. 로컬 DB는 reset 없이 migration up으로 적용했다. 원격 DB는 아직 미적용이다.

## T12 — 상품권·초기 잔액·환불

구현 브랜치: `feat/t12-vouchers-refunds`.

`voucher_movements`와 거래의 상품권 연결 필드를 추가하고, `record_voucher_event` RPC로 상품권 충전·사용·환불 이벤트를 원자적으로 기록한다. 상품권 행 잠금 후 잔액 부족을 검사하며, 클라이언트의 직접 잔액 변경은 차단한다. 초기 잔액은 충전 이벤트로 기록할 수 있다.

검증: `supabase/tests/t12_vouchers_refunds.sql`에 테이블·RPC·권한 회귀를 추가했다. Supabase CLI/pgTAP 실행은 커밋 전 확인한다.

## T11 — 결제 수단 등록·관리 UI

구현 브랜치: `feat/t11-payment-method-ui`.

지갑 탭에서 결제 수단 관리 화면으로 이동해 현금·계좌·체크카드·신용카드를 등록할 수 있다. 카드 포함 모든 수단은 구성원 소유자를 선택할 수 있고, 등록된 수단은 보관 처리해 거래 입력 목록에서 숨긴다. T03의 일반 등록 RPC와 T10의 카드 등록 RPC를 종류에 따라 호출하며, 보관은 `archive_payment_method` RPC로 처리한다. 직접 입력 화면에 등록된 수단이 없으면 등록 화면으로 이동하는 링크를 제공하고, 등록 뒤 거래 입력으로 돌아갈 수 있다.

가계부 생성 시 공유 현금 수단을 자동 생성하고, 기존 가계부에는 `현금` 수단이 없을 때만 보정한다. 따라서 공동 가계부 구성원 모두가 기본 현금을 함께 사용할 수 있다.

검증: `flutter analyze` 문제 없음, `flutter test` 전체 통과(11개). `supabase/tests/t11_payment_methods.sql`에 등록·보관 함수 실행 권한과 직접 insert 차단 회귀를 추가했다. Supabase CLI/psql이 없어 실제 migration 적용과 원격 RPC 호출은 미실행이다.

## T10 — 카드 등록과 월별 실적 목표

구현 브랜치: `feat/t10-card-performance`.

`card_targets`와 거래의 `performance_included` 플래그를 추가하고 카드 등록, 월별 목표 upsert, 거래별 실적 포함/제외, 카드별 월 실적 조회 RPC를 구현했다. 카드+월을 기본 키로 중복 목표를 막고, 활성 구성원만 호출할 수 있게 했다. 상품권과 환불에 따른 실적 조정은 T12 범위로 남긴다.

검증: `supabase/tests/t10_card_targets.sql`에 함수·권한·카드+월 유일성 회귀를 추가했다. Supabase CLI/psql이 없어 실제 migration과 카드 실적 데이터 시나리오는 미실행이다.

## T09 — 초대·탈퇴·접근 회수

DB 구현 브랜치: `feat/t09-household-invitations`. 앱 연결 브랜치: `feat/couple-household-connection`. 링크·가입 연결 브랜치: `feat/invitation-deep-link-onboarding`.

`invitations`에 원문이 아닌 SHA-256 토큰 해시만 저장하고, `create_invitation`/`accept_invitation`에서 만료·일회성·활성 구성원 2명 정원과 가계부 잠금을 함께 검사한다. `leave_household`는 구성원을 즉시 비활성화하고 마지막 구성원이 나가면 가계부를 archived 처리한다. 초대 테이블 직접 읽기와 구성원 직접 변경은 차단하고 RPC만 실행 가능하게 했다.

설정의 공동 가계부 화면에서 현재 구성원을 확인하고, 7일 유효 초대 코드를 생성·복사하거나 받은 48자리 코드를 수락할 수 있다. 서버 오류를 만료/재사용·이미 참여·정원 초과·접근 불가 안내로 구분한다. 탈퇴는 영향 확인 뒤 RPC를 실행하며 성공 시 공동 데이터 참조를 비우고 Supabase 세션을 종료한다. 초대 코드는 앱에 영구 저장하지 않는다.

검증: `supabase/tests/t09_invitations.sql`에 함수·권한·활성 구성원 유일성 회귀가 있다. 앱 연결은 초대 링크/자동 입력 테스트를 포함한 `flutter test` 전체 35건, `flutter analyze`, `flutter build macos --debug`, `flutter build ios --no-codesign`, `git diff --check`로 검증했다. `flutter build apk --debug`는 Gradle이 70초 이상 출력 없이 대기해 중단했으며 Android APK 빌드는 미검증이다. Supabase CLI/psql이 없어 실제 migration/원격 두 계정/병렬 세션 검증은 미실행이며, Realtime 구독은 남아 있다. 실제 HTTPS 도메인 연결, iOS Associated Domains 파일 배포, Android `assetlinks.json`, 카카오톡 공유 화면은 운영 설정 후 실기기에서 확인해야 한다.

## T08 — 영수증 이미지 분석 함수 경계

구현 브랜치: `feat/t08-receipt-analysis-function`.

`supabase/functions/analyze-receipt/index.ts`에 인증된 사용자만 호출할 수 있는 Edge Function을 추가했다. 원본은 서버 메모리에서만 처리하며 JPEG/PNG·10MB·최대 50건을 제한하고, 공급자 응답의 날짜·금액·유형·문자열 길이를 검증한 뒤 `draft_id`와 검토용 항목만 반환한다. 공급자 endpoint/key는 환경변수로만 주입하며 미설정 시 운영 호출을 거부한다. 개인정보 없는 평가 fixture도 추가했다. 실제 모델 품질·비용 승인은 공급자 선택 후 별도 검증이 필요하다.

검증: `flutter analyze` 문제 없음, `flutter test` 10개 통과, `git diff --check` 통과. 이 환경에는 Deno/Supabase CLI가 없어 Edge Function의 실제 배포·호출은 미검증이다.

## T07 — AI 이용내역 검토 fixture

구현 브랜치: `feat/t07-ai-review-fixture`.

실제 이미지/모델 호출 없이 고정 fixture 2건을 분석 예시로 제공한다. 사용자는 각 항목을 선택 해제하거나 날짜·사용처·금액을 수정한 뒤 선택 항목을 T04 `save_transactions` RPC로 일괄 저장할 수 있다. 선택 항목이 없으면 저장 버튼이 비활성이고, 취소하면 저장 변경이 없다. T08에서 이미지 입력과 실제 공급자 adapter를 연결한다.

검증: `flutter analyze` 문제 없음, `flutter test` 10개 통과, fixture 선택 해제 후 1건 일괄 저장 위젯 테스트 통과. 실제 이미지 분석은 의도적으로 미구현이다.

## T06 — 캘린더·기간별 내역 조회

구현 브랜치: `feat/t06-period-queries`.

`query_transactions` RPC를 추가했다. 기간은 `[start_date, end_date)`로 검증하고, 구성원·결제 수단·카테고리 필터를 목록과 합계에 동일하게 적용한다. 무효화 거래는 제외하며 occurred_on/created_at/id 내림차순과 커서 조건을 사용한다. 활성 구성원만 호출할 수 있고 authenticated 외 실행 권한은 없다.

검증: `supabase/tests/t06_transaction_queries.sql`에 RPC 존재·권한·기존 기간 인덱스 회귀를 추가했다. Supabase CLI/psql이 없는 환경이라 실제 SQL 실행은 미검증이다.

## T05 — 직접 입력 실제 저장 연결

구현 브랜치: `feat/t05-persist-manual-entry`.

인증된 사용자의 가계부·활성 수단·구성원 목록을 Supabase에서 읽고, 예시 수단/구성원 없이 실제 ID를 `save_transactions` RPC에 전달하도록 직접 입력을 연결했다. 가계부가 없으면 `create_household`로 최초 가계부를 만든다. 저장 성공 시 입력 화면을 닫고 완료 안내를 보여주며, RPC 오류는 화면에 남겨 입력 초안을 유지한다. 요청마다 UUID를 생성해 T04 멱등성 계약을 사용한다.

검증: `flutter analyze` 문제 없음, `flutter test` 9개 통과, `git diff --check` 통과. Supabase 실제 앱 저장은 사용자가 적용한 원격 T03/T04 migration과 인증 세션을 전제로 하며, 수단이 등록되지 않은 경우 폼에서 선택을 요구한다.

후속 확인: 현재 앱에는 결제 수단 등록 화면이 없어 신규 계정에서 직접 입력 저장을 끝까지 수동 검증할 수 없다. T03의 `add_payment_method` RPC는 준비되어 있지만, 현금·계좌·카드 등록 UI와 등록 후 복귀 흐름은 T10에서 추가해야 한다. 수단이 없는 경우 예시 값으로 우회하지 않고 선택 오류를 표시한다.

## T04 — 거래 저장·수정·무효화 RPC

구현 브랜치: `feat/t04-transaction-rpcs`.

T03 스키마에 `transactions`와 `write_requests`를 추가하고 `save_transactions`, `edit_transaction`, `void_transaction` security-definer RPC를 구현했다. 저장은 1~50건 원자 처리, 인증 사용자·활성 구성원·가계부/수단/구성원 소속·수입 수단 규칙을 서버에서 검증한다. 요청 키와 canonical JSON payload hash로 동일 재시도는 기존 결과를 반환하고 본문이 다르면 `idempotency_conflict`를 반환한다. 수정/무효화는 행 잠금과 expected version 검증으로 `version_conflict`를 차단하며 무효화는 물리 삭제 대신 `voided_at`을 기록한다. authenticated의 transactions/write_requests 직접 쓰기는 차단했다.

검증: `supabase/tests/t04_transaction_rpcs.sql`에 migration 재현 후 확인할 테이블·함수·권한·제약 회귀 사례를 기록한다. 이 환경에는 Supabase CLI/psql이 없어 실제 SQL 실행은 미검증이다. Flutter 코드는 변경하지 않았으므로 T04 관련 Flutter 테스트/분석은 다음 실행에서 확인한다.

## T03 — 가계부·구성원·결제 수단 DB와 접근 권한

구현 브랜치: `feat/t03-database-access`.

`supabase/migrations/20260914000000_t03_households_and_payment_methods.sql`에 profiles, households, household_members, payment_methods 스키마와 활성 구성원 기반 RLS를 추가했다. 가계부 생성과 결제 수단 등록은 security-definer 함수로만 수행하며 authenticated의 직접 insert/update/delete 권한은 부여하지 않는다. 다른 가계부 사용자는 RLS 조회에서 제외된다. `supabase/tests/t03_household_access.sql`은 로컬 Supabase의 pgTAP 실행 계약과 권한 회귀 사례를 고정한다.

검증: `flutter analyze` 통과, `flutter test` 9개 통과, `git diff --check` 통과. 현재 실행 환경에 Supabase CLI와 psql이 없어 migration/pgTAP의 실제 로컬 DB 실행은 미검증이며, 로컬 검증 시 `supabase start` 후 `supabase db reset` 및 `supabase db test`를 실행해야 한다.

## C02 — 공통 입력 폼

## T02 — Supabase 설정·세션·카카오 로그인

브랜치: feat/supabase-kakao-auth. 앱 환경값이 없으면 설정 안내 화면을 표시하고, 값이 모두 있을 때만 Supabase를 초기화한다. 카카오 OAuth 서비스와 로그인 UI를 주입 가능한 경계로 분리했다. 실제 공급자 설정 및 OAuth 성공은 외부 프로젝트 설정 후 검증한다.

검증 결과: `flutter analyze` 문제 없음, 전체 테스트 9개 통과. 완전하지 않은 환경값·HTTP URL 차단, 로그인 취소·실패 메시지, 미구성 실행 경로를 테스트했다. 실제 Supabase/Kakao 호출·iOS/Android 딥링크는 외부 설정 전이라 미실행이다.

실제 설정 테스트에서 Supabase 초기화는 성공했으나 macOS 앱 복귀 직후 `Directionality` 오류를 확인했다. AuthRoot에 MaterialApp을 추가하고 macOS/iOS custom URL scheme과 Android intent-filter를 등록했다. 수정 후 재빌드·세션 복귀를 다시 확인해야 한다.

T01은 별도 `feat/transaction-draft` 브랜치에서 진행한다. `TransactionDraft` 타입으로 폼의 확정 전 값을 전달하고 AI 초안 주입을 위한 `initialDraft`, 수단·구성원 목록, `onConfirm` 콜백 경계를 추가한다. 현재 기본 앱은 콜백 미지정으로 미리보기만 표시한다.

브랜치: feat/manual-entry-form. PR #1 병합 확인 후 최신 main에서 생성.

범위: 캘린더/내역의 기록하기 → 직접 입력, 수입/지출·날짜·금액·내용·카테고리·예시 수단·예시 구성원·메모, 확인 미리보기, 이탈 시 폐기 확인. 실제 저장은 C03의 인증/DB 연결 후 구현. 카드 등록과 상품권 입력은 해당 도메인 단위에서 연결한다.

금액은 1~999,999,999원, 날짜는 2000~2100년을 이번 입력 폼의 임시 제한으로 사용한다. 최종 DB 계약과 일치시키는 작업이 남아 있다. 검증 계획: 필수값·음수·소수·없는 날짜 차단, 확인 후 수정값 유지, 수입 전환, 이탈 확인, 작은 화면/큰 글자에서 스크롤.

검증 결과: 기존 3개 및 신규 입력 흐름 3개, 총 6개 위젯 테스트 통과. 화면 밖 필드도 검증에 참여하도록 폼을 단일 스크롤 컨테이너로 구성했다. 실제 저장·카드·상품권·AI 초안 주입은 아직 미구현이며 iOS 실기기 확인은 남아 있다.

## C01 — 네 탭과 개인 테마

추가 요청: 프리셋을 총 10개로 확대. 살구빛 테라코타, 레몬 가든, 민트 소다, 코코아 라떼, 인디고 구름 추가. 기존 5개 선택 ID와 저장 방식 유지.

범위: 기본 네 탭, 데이터 미연결 상태 안내, 설정의 5개 프리셋 선택, 앱 전체 즉시 적용, 기기 저장 및 복구. 금융 데이터 저장은 포함하지 않는다.

검증: 탭 이동, 선택 테마 색상 반영, 저장 실패 시 이전 테마 유지 및 오류 안내, 저장된 선택으로 재생성, 미지원 ID 기본값 복구, 작은 화면과 큰 글자에서 오류 없음.

진행: 구현 시작. 사용자 수용된 상세 설계의 첫 단위를 C01(탭/테마)과 C02(공통 입력 폼)로 나누어 검증한다. C02 이후 카카오/Supabase 연결로 진행한다.

### C01 구현 결과

- 브랜치: feat/app-shell-theme. 네 탭과 데이터 미연결 안내, 5개 테마 즉시 적용, 기기 설정 저장/복구 구현.
- flutter analyze: 문제 없음.
- flutter test: 3개 통과. 탭 전환·선택 콜백과 재생성, 미지원 ID와 저장 실패 복구, 375×667/글자 2배 설정 검증.
- 테스트의 저장 경로는 주입한 콜백을 사용한다. 실제 기기 저장소 재실행·아이폰 시각 검증은 아직 수행하지 않았으며 사용자 화면 리뷰도 남아 있다.
- flutter-add-widget-test 스킬의 초기 상태 → 동작 → 결과 검증 흐름을 적용했다. 금융 기능과 로그인은 아직 미구현이다.
- 사용자 요청으로 macOS 실행 대상을 추가했다. `flutter build macos --debug` 성공. 아이폰 실기기 검증을 대체하지는 않는다.

위젯 테스트 절차: 초기 화면 구성 → 초기 상태 확인 → 탭/테마 선택 → 프레임 갱신 → 결과 확인 → 실행 결과 검토.
