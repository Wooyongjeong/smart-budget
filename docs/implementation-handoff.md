# 구현 인계: 작은 작업 단위로 진행하기

2026-09-14. 모델 이름과 관계없이 한 번에 아래 작업 하나만 맡긴다. 제품 요구는 inception.md, 상세 정책은 design.md, 현재 구현 증거는 construction.md를 따른다. 이 문서는 실행 계약을 보완한다. 새 제한값은 구현 기본안이며 출시 정책으로 확정된 값이 아니다.

## 현재 상태와 시작점

현재 코드의 문서 대비 수정·미완료 항목은 [code-review.md](code-review.md)를 먼저 확인한다. T01~T12의 기반 코드는 존재하지만, 코드 존재나 기본 테스트 통과만으로 전체 작업을 완료 처리하지 않는다.

- 네 탭, 12개 테마, 한국어·영어 설정과 macOS 실행을 지원한다.
- 카카오 로그인, 공동 가계부 DB, 일반 거래 저장, 월 조회, 결제 수단, 카드 목표와 상품권 잔액이 연결되어 있다.
- 이용내역 캡처 화면은 고정 fixture이며 실제 이미지 선택·AI 공급자 연결은 미완성이다.
- 초대·탈퇴는 DB RPC만 있고 앱 UI와 실시간 동기화가 없다.
- T06/T08/T09/T12의 남은 계약은 [code-review.md](code-review.md)의 목록을 따른다. 실제 이미지 분석·저장은 T13, 출시 점검은 T14로 진행한다.

## 실행 규칙

1. git status와 작업 브랜치 확인. 깨끗한 최신 main에서 feat/<task> 생성. 사용자 변경은 보존한다.
2. 이 문서의 해당 작업과 관련 파일만 먼저 읽는다. 필요한 상세 설계 절만 추가로 읽는다.
3. 이번 작업의 입력·출력·오류·검증 사례를 짧게 기록하고 구현한다. 다음 작업까지 확장하지 않는다.
4. 변경 관련 테스트와 flutter analyze를 실행한다. UI 변경은 macOS 빌드, iOS 플랫폼 변경은 iOS 검증도 별도로 기록한다.
5. 결과를 construction.md에 누적한다. 실패/미실행을 성공으로 적지 않는다. 사용자에게 요청할 외부 설정은 정확히 나열한다.
6. 브랜치 커밋·푸시 후 결과 보고. PR 작성 요청이 있으면 main 대상으로 올린다. 병합은 사용자가 한다.

기획 문서는 main, 구현은 기능 브랜치라는 사용자 규칙을 따른다. 구현 중 검증 기록은 해당 기능 PR에 포함해도 된다. 새 모델·새 세션에서도 이 규칙을 유지한다.

## 작은 공통 구조

화면은 DB 쿼리를 직접 만들지 않는다. features/<기능>/에 모델·화면·controller·repository를 필요할 때 추가한다. 로컬 폼 상태는 StatefulWidget, 공유 비동기 상태는 ChangeNotifier와 주입한 repository로 시작한다. 상태 관리 프레임워크 변경이나 전체 디렉터리 재구성은 이번 MVP의 선행조건이 아니다.

Repository는 인증·조회·저장 경계를 테스트용 구현으로 바꿀 수 있게 한다. SharedPreferences에는 테마 등 설정만 저장한다. 금융 데이터를 임시로 영구 저장한 뒤 Supabase 완성으로 보고하지 않는다.

## 작업 목록

| ID | 산출물 | 선행 | 완료 조건 |
| --- | --- | --- | --- |
| T01 | TransactionDraft와 공통 입력 계약 분리 | PR #2 병합 | 기존 폼 결과를 타입으로 반환, 초안 주입/수정 가능, 기존 검증 유지 |
| T02 | Supabase 설정·세션·카카오 로그인 | 없음 | 설정 없는 경우 안내, 취소/실패 처리, 실제 OAuth 성공은 외부 설정 후 검증 |
| T03 | 가계부·구성원·수단 DB와 접근 권한 | 없음 | 로컬 migration 재현, 다른 가계부 접근 및 직접 쓰기 차단 |
| T04 | 일반 거래 DB 저장/수정/삭제 RPC | T03 | 원자적 저장·요청 중복·버전 충돌·권한 회귀 테스트 |
| T05 | 직접 입력을 실제 저장에 연결 | T01,T02,T04 | 예시 수단/구성원 제거, 실패 시 초안 유지, 성공 후 조회 갱신 |
| T06 | 캘린더·기간별 내역 | T04,T05 | 동일 필터와 동일 집계, 날짜 경계, 빈 상태/오류/페이지 이동 |
| T07 | AI 확인 UI와 가짜 분석 응답 | T01,T05 | 한 장 여러 거래 선택/수정, 일괄 저장, 취소 시 무변경 |
| T08 | 실제 이미지 분석 함수 | T02,T03,T07 | 인증·상한·출력 검증·평가 자료, 실제 공급자 검증 전에는 미완료 |
| T09 | 초대·동시 편집·탈퇴 | T02,T03,T04 | 초대 정원/재사용/만료·다른 사람 변경·접근 회수 검증 |
| T10 | 카드 실적·목표 DB 계약 | T03,T04,T06 | 카드별·월별 목표, 포함/제외 계산, 소유자, 보관 |
| T11 | 결제 수단 등록·관리 UI | T03,T10 | 현금/계좌/체크카드/신용카드 등록, 소유자, 보관, 등록 후 거래 입력 복귀 |
| T12 | 상품권·초기 잔액·환불 | T04,T10,T11 | 아래 금액 불변식과 동시 사용·소급 수정 테스트 |
| T13 | 카드 이용내역 이미지 → AI 추출 → 사용자 확인 → 저장 | T02,T04,T05,T07,T08 기반,T11 | 실제 이미지·실제 공급자로 추출/수정/일괄 저장/조회 갱신 검증, 아래 상세 계약 충족 |
| T14 | 출시 점검 | T01~T13 | 실기기, 계정 삭제/보존, AI 비용/품질, 운영 오류 확인 |

T03/T04/T08/T09/T10/T12는 권한·금액·외부 AI 경계라서 구현 후 별도 검토를 권장한다. 검토 모델을 매번 쓰기보다 관련 변경을 묶어 검토한다. 테스트만으로 안전성이 보장된다고 간주하지 않는다.

## T01: 바로 실행할 수 있는 계약

추가 파일: lib/features/transactions/transaction_draft.dart. 기존 폼은 가능한 적게 수정한다.

TransactionDraft: kind(income/expense), occurredOn(DateTime의 날짜 부분), amountWon(int?), merchant(String), category(String?), paymentMethodId(String?), memberId(String?), memo(String). AI 추출 누락을 표현하도록 초안의 미완성 필드는 null 허용. DB 확정 거래 타입과 구분한다.

EntryForm은 initialDraft, 결제 수단 목록, 구성원 목록, onConfirm 콜백을 받도록 한다. 현재 앱에서는 콜백이 미리보기만 수행한다. 미래 서버 저장을 가짜로 성공시키지 않는다. 부모가 제공한 초안 객체는 직접 변경하지 않고 편집 복사본을 쓴다.

필수: 유효한 날짜, 양수 정수 금액, trim 후 내용, 유형에 맞는 카테고리, 유효한 수단/구성원. 임시 제한은 현 구현과 동일: 금액 1~999,999,999, 연도 2000~2100, 내용 100자, 메모 500자. DB 저장 전 검증도 동일하게 둔다. 예시 ID는 실제 연결 단계에서 허용하지 않는다.

검증 사례: 초기 초안의 날짜/금액/내용 표시, AI 초안의 null 금액 보완, 취소해도 원본 불변, 수입 전환 시 카테고리 정합성, onConfirm 중 중복 클릭 방지 및 실패 시 값 유지. 실제 저장이 없는 현재 단계에 '저장 완료'를 추가하지 않는다.

## T02: 인증 설정 경계

앱 환경 값: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, AUTH_REDIRECT_URL. 값은 실행 설정으로 주입하고 .env.example 또는 실행 예시에는 가짜 값만 넣는다. Supabase service-role 및 Kakao client secret은 앱에 넣지 않는다.

사용자가 준비할 것: Supabase 개발 프로젝트, Kakao Developers 앱, Kakao 공급자 설정, 정확한 앱 ID/복귀 URI. 비밀 값은 채팅이나 커밋으로 요청하지 않고 각 서비스 설정 화면에서 입력하도록 안내한다.

OAuth는 Supabase Kakao 연동으로 시작한다. 앱 복귀 URI 수신만으로 로그인 성공을 판단하지 않고 Supabase 세션을 확인한다. macOS/iOS/Android 각각 콜백 등록을 검증한다. 설정이 없으면 안내 화면을 제공하며 다른 독립 작업은 진행할 수 있다. 공급자 설정 부재를 모의 로그인으로 숨기지 않는다.

## T03–T04: DB 계약

기본 ID는 uuid, 원화는 bigint, 업무 날짜는 date, 기록 시각은 timestamptz. 한국 날짜와 UTC 기록 시각을 섞지 않는다. 현재 앱의 날짜 기본값은 기기 시간에 의존하므로 실제 저장 연결 시 한국 기준으로 통일한다.

profiles(user_id PK), households(id PK), household_members(id PK, household_id, user_id, left_at), payment_methods(id PK, household_id, kind, name, owner_member_id, archived_at)를 먼저 만든다. kind는 cash/bank/debit_card/credit_card/voucher. 수입은 cash/bank만 우선 허용한다. 활성 가계부 정원 2명. 초기 생성은 household와 creator membership을 한 함수에서 저장한다.

모든 하위 참조는 household_id를 포함하는 복합 FK로 다른 가계부 수단·구성원 혼입을 막는다. 가계부 데이터는 활성 구성원만 조회. 직접 테이블 쓰기는 차단하고 검증된 함수 실행만 허용한다. profiles도 본인 또는 같은 활성 가계부 구성원만 표시 이름을 읽게 한다. 탈퇴자 표시용 이름 보존/익명화는 출시 정책과 연결한다.

transactions 기본 열: id, household_id, kind, occurred_on, amount_won, merchant, category, payment_method_id, member_id, memo, created_by, updated_by, created_at, updated_at, version(1부터), voided_at. T04는 income/expense만 허용한다. 상품권 선택은 T11 전까지 막는다.

save_transactions(p_household_id uuid, p_request_id uuid, p_entries jsonb) → {transaction_ids:[uuid]}.
entries의 필드명은 위 열 이름을 사용하며 created_by 등 서버 열은 입력받지 않는다. 배열 1~50개를 초기 상한으로 제안한다. 1개라도 잘못되면 전체 실패. request_id는 첫 전송 전에 생성하고 재시도 시 유지한다. (household_id, actor_id, request_id) 유일, canonical jsonb payload hash와 결과 ID 저장. 같은 키/같은 본문은 기존 결과 반환, 다른 본문은 idempotency_conflict.

edit_transaction(p_id, p_expected_version, p_request_id, p_values), void_transaction(p_id, p_expected_version, p_request_id)도 같은 중복 방지 원칙을 따른다. 작업 종류까지 hash에 포함한다. void는 물리 삭제가 아니라 집계 제외이다. 서버가 사용자·구성원·version을 검사한다.

예상 오류는 code와 fieldErrors로 앱에서 매핑한다: validation_failed, forbidden, version_conflict, idempotency_conflict, insufficient_balance. unexpected는 일반 오류 안내와 요청 ID만 노출한다. SQLSTATE/오류 응답 포맷은 migration 작성 시 하나로 정하고 adapter 테스트에 고정한다.

DB 테스트는 anon, 부부 A/B, 다른 가계부 C, 탈퇴 A를 실제 인증 문맥으로 실행한다. postgres 관리자 계정 테스트만으로 RLS 검증을 대신하지 않는다. 잠금 순서는 가계부/구성원 → 요청 → 수단 ID순 → 거래 ID순으로 통일하고 초대/탈퇴/환불 함수도 같은 규칙을 따른다. 병렬 두 세션으로 충돌 시나리오를 확인한다.

## T06: 조회 계약

기간은 [startDate, endDate)이며 주는 월요일 시작. 필터: member_id, payment_method_id, category. 목록과 합계에 같은 조건 적용, void 제외. 정렬은 occurred_on DESC, created_at DESC, id DESC. 페이지네이션은 이 세 값의 커서 사용. 합계는 현재 페이지의 합이 아니라 전체 필터 기간의 합이다.

캘린더는 월 전체의 일별 수입/지출과 월 합계, 선택 날짜 목록을 제공한다. 일/주/월 이동 시 같은 조회 함수를 사용한다. 검증: 12월→1월, 윤년 2/29, 월 경계를 넘는 주, 한국 자정 근처, 거래 없는 기간, 필터 적용 후 합계.

## T07–T08: AI 계약

T07에서는 고정 fixture만 사용하고 '분석 예시'임을 표시한다. T08에서 공급자 adapter를 연결한다. 모델명과 가격을 추측해서 고정하지 않는다. 공급자 선택/비용 상한/보존 조건은 사용자가 정해야 한다.

초기 기술 상한 제안: 이미지 1장, JPEG/PNG, 10MB, 디코딩 20메가픽셀, 최대 거래 50건, 처리 타임아웃 30초. HEIC는 앱에서 변환하거나 지원하지 않는다고 명확히 안내한다. 크기/해상도/형식은 서버에서도 검사한다. 실제 공급자 제한이 더 작으면 작은 값을 적용하고 문서 갱신한다.

분석 응답: {draft_id, items:[{date:null|YYYY-MM-DD, merchant:null|string, amount:null|integer, suggested_type, payment_hint:null|string, category_hint:null|string, review_reasons:string[]}]}.
suggested_type은 income/expense/refund/voucher_topup/voucher_use/unknown. 지원 전 유형을 일반 지출로 묵시 저장하지 않는다. 연도 없는 날짜는 null+사유. 헤더 합계는 거래가 아니다. 이미지 지시문은 실행하지 않는다. 모델에 DB 쓰기 도구를 주지 않는다.

검토 화면에서 모든 항목의 선택을 해제하면 저장 버튼 비활성. 저장 전 필수값을 모두 확인하고 T04의 일괄 RPC 사용. 중복 후보는 날짜+금액+trim한 사용처로 조회하되 사용자가 최종 선택한다. 후보 탐지와 동일 요청 중복 방지는 별개다.

초안/원본은 세션 내에서만 사용. 완료/취소 후 임시 파일 정리, 재시작 때 잔여 임시 파일 정리. 갤러리 원본은 건드리지 않는다. 로그에 원본·거래 내용·비밀 키를 기록하지 않는다. 호출량 제한은 서버 DB 기준으로 원자적 차감하고, 초기 한도는 설정값으로 둔다. 승인된 비용 상한 없이는 운영 공개를 완료 처리하지 않는다.

평가 fixture는 개인정보 없는 단건/복수/누락 연도/취소/합계/저화질/중복/상품권/지시문 사례로 구성한다. 개발용 회귀 검증은 정답과 날짜·금액·사용처 및 누락/추가 건수를 비교한다. 실제 모델 품질 평가는 별도 held-out 자료와 비용/시간을 기록하고, 출시 통과 수치는 관측 후 검토한다.

## T10–T12: 금액 불변식

| 사건 | 수입 합계 | 지출 합계 | 상품권 변동 |
| --- | ---: | ---: | ---: |
| 수입 A | +A | 0 | 0 |
| 일반 지출 A | 0 | +A | 0 |
| 현금 C로 상품권 V 충전 | 0 | +C | +V |
| 상품권 V 사용 | 0 | 0 | -V |
| 일반 지출 환불 R | 0 | -R | 0 |
| 상품권 사용 취소 R | 0 | 0 | +R |
| 상품권 V 반환, 현금 C 환급 | 0 | -C | -V |
| 초기 상품권 V 등록 | 0 | 0 | +V |

모든 합계는 하나의 DB 집계 계약을 사용한다. 상품권 이동은 연결 거래의 종류에서 서버가 계산하며 클라이언트가 집계 부호를 결정하지 않는다. 일반 카드 결제는 구매일 지출이며 카드 대금 납부를 재집계하지 않는다.

카드 실적은 포함된 일반 카드 결제/카드 충전의 실제 결제액 합계에서 포함된 원거래의 환불 인정액을 차감한다. 월 목표는 카드+월 유일. 부분 환불은 원거래의 실적 포함 여부를 따른다. 기본 실적 귀속은 원거래 월, 수정 가능. 이미 환불이 연결된 원거래의 실적 설정 변경은 연결 항목까지 일관되게 갱신하거나 명확히 차단한다.

잔액·원거래의 환불 누적 한도는 해당 행 잠금 후 검사한다. 같은 날짜 변동 순서는 occurred_on, created_at, id. 소급 수정/삭제가 과거 어느 시점의 잔액을 음수로 만들면 거절. 93,000/100,000 충전 후 20,000 사용 → 지출 93,000, 잔액 80,000. 현재 80,000에서 동시에 50,000 사용 2개 요청 → 하나만 성공. 서로 다른 요청 ID로 같은 원거래를 두 번 전액 환불 → 하나만 성공.

## T13: 실제 카드 이용내역 이미지 분석과 저장

2026-09-16 추가. 상태: 계획, 구현 미착수. 기존 T13 출시 점검은 T14로 이동한다. T07의 예시 검토 UI와 T08의 함수 기반을 재사용하고 미완료 계약을 이 작업에서 연결한다. 기존 T08을 완료 처리하거나 동일 기능을 새로 중복 구현하지 않는다.

### 사용자 흐름과 범위

1. 기록하기에서 이용내역 이미지 선택 → 미리보기 → 분석. 카드사 앱·토스 등의 캡처 1장에 여러 거래가 있는 경우를 지원한다. macOS 파일 선택과 iOS 사진 선택을 검증한다.
2. 분석 중 진행 상태와 취소를 제공한다. 선택 취소, 지원하지 않는 파일, 거래 없음, 네트워크 실패, 시간 초과, 공급자 미설정, 한도 초과를 구분한다. 실패 시 예시 거래로 대체하지 않는다.
3. 추출한 날짜·사용처·금액을 항목별로 보여준다. 사용자가 선택/제외하고 날짜·금액·사용처·카테고리·결제 수단·실제 사용자를 수정한다. 카드 이름은 힌트이며 실제 가계부 수단 ID로 자동 확정하지 않는다. 공통 카드/사용자 지정 후 항목별 수정이 가능해야 한다.
4. 누락값은 미입력으로 표시하고 보완 전 저장을 막는다. 현재 TransactionDraft의 날짜는 non-null이므로 별도 분석 DTO에서 누락 날짜를 유지하고 검증 후 변환한다. 연도를 임의로 채우지 않는다. 합계·잔액·카드 대금 납부를 일반 구매로 오인하지 않는다.
5. T13의 저장 대상은 확인된 일반 지출이다. 환불·상품권 충전/사용·수입·불명확 항목은 사유를 표시해 제외하거나 해당 별도 입력 흐름을 안내한다. 일반 지출로 변환하여 저장하지 않는다.
6. 날짜+금액+정규화한 사용처의 기존 거래 후보를 표시하고 사용자가 중복 여부를 판단한다. 선택 항목을 기존 원자적 일괄 저장 RPC로 저장한다. 실패 시 편집 내용을 유지하고 같은 요청/본문 재시도에는 같은 request_id를 사용한다. 본문 수정 후에는 새 요청으로 취급한다.
7. 저장 성공 후 캘린더·내역·지갑의 관련 조회를 갱신한다. 확인 전과 취소 시 DB 거래를 생성하지 않는다. 원본과 분석 초안은 세션 임시 자료이며 T07–T08의 정리·로그 계약을 따른다.

### 공급자 결정과 연결 방식

2026-09-17 결정: Gemini API의 계정·결제 제약으로 T13은 OpenRouter 무료 멀티모달 모델을 1차 공급자로 시험한다. Flutter 앱이 직접 API 키를 갖지 않고 Supabase Edge Function을 통해 호출한다. 기본 모델은 `openrouter/free` 라우터로 두고, 실제 이미지 입력을 지원하는 무료 모델을 요청 시 선택·기록한다. 개발·시연에는 개인정보 없는 합성 캡처를 사용하며 실제 개인 금융 캡처의 무료 서비스 전송은 별도 개인정보 정책을 결정하기 전까지 허용하지 않는다. 이번 문서 변경은 설치·배포·API 호출을 포함하지 않는다.

분석 repository와 공급자 adapter를 분리해 검증된 공통 응답 계약을 사용한다. OpenRouter 연결이 완료 기준을 충족하면 T13을 완료할 수 있다. Gemini와 로컬 MLX 모델은 후순위 대안이며, 여러 공급자 동시 구현은 필수가 아니다.

| 공급자 | 연결 | 비용·제약 | T13에서의 위치 |
| --- | --- | --- | --- |
| OpenRouter 무료 멀티모달 모델 | Flutter 앱 → Supabase Edge Function → OpenRouter API | 모델별 무료 rate limit·가용성 변동. `OPENROUTER_API_KEY`는 함수 secret에 보관 | 기본 공급자, 합성 캡처로 spike 및 구현 |
| Gemini Developer API 무료 티어 | 앱 → Supabase Edge Function → Gemini API | 지원 모델별 무료 한도와 계정·결제 조건 확인 필요 | 후순위 대안 |
| 로컬 MLX-VLM | macOS 개발 앱 → 로컬 분석 adapter → MLX 모델 | API 호출료 없음. Python·모델 다운로드와 메모리·전력·처리 시간 필요 | 회사 제한이 없는 환경에서 비교할 후순위 대안 |

Gemini 앱/Antigravity의 무료 이용권을 앱용 Gemini API 무료 할당량과 동일시하지 않는다. 앱 통합은 공식 Gemini Developer API의 인증·가격·한도를 기준으로 검토한다. Antigravity 로그인 토큰이나 IDE 세션을 추출해 비공식 API로 재사용하는 방식은 계획하지 않는다.

무료 OpenRouter 모델도 실제 요청이 외부 모델 제공자에게 전달되며 모델별 데이터 보존 조건과 rate limit이 다르다. 합성·비식별 자료에 한정하고, 사용 모델·제공자·정책 버전을 기록한다. 유료 자동 전환이나 다른 공급자로 자동 전송은 하지 않는다. Gemini 무료 서비스에도 제출 내용의 제품 개선 활용 및 인적 검토 가능성이 있으므로 같은 제한을 적용한다.

이 컴퓨터 확인 결과: ARM64, 메모리 48GiB. MLX-VLM 패키지는 설치됐지만 회사 네트워크에서 Hugging Face 모델 다운로드가 차단되어 로컬 추론은 검증하지 못했다. 후순위 로컬 후보는 이미지 입력을 지원하는 Qwen2.5-VL 7B 등이며, 텍스트 전용 LLM만으로 이미지를 바로 처리할 수 있다고 가정하지 않는다. 메모리 사양은 성능 보장이 아니다.

로컬 모드는 개발 전용 설정으로 시작한다. macOS 앱의 localhost는 이 Mac이지만 iPhone의 localhost는 iPhone이고, 클라우드 Edge Function의 localhost도 이 Mac이 아니다. iPhone 연결은 같은 네트워크에서 Mac으로 도달 가능한 주소와 인증된 연결이 필요하다. Ollama를 인증 없이 외부에 공개하지 않는다. 로컬 Supabase 함수에서 접근하는 경우 컨테이너→호스트 주소도 별도로 검증한다. 공개 서비스에서 개인 Mac을 상시 서버로 사용하는 것은 T13의 완료 조건이 아니다.

### 구현 순서와 완료 기준

- 관련 시작 파일: lib/features/transactions/ai_review_screen.dart, transaction_draft.dart, transaction_repository.dart, lib/main.dart, supabase/functions/analyze-receipt/index.ts 및 fixtures/evaluation.json. 플랫폼 파일은 이미지 선택/네트워크 설정에 필요한 것만 읽는다.
- 먼저 합성 카드 이용내역 샘플로 OpenRouter의 `openrouter/free` 멀티모달 입력과 JSON 출력 spike를 수행한다. 공급자 호출은 Supabase Edge Function에서만 하고 `OPENROUTER_API_KEY`를 클라이언트에 포함하지 않는다. 날짜·금액·사용처 인식률, 지연, 무료 rate limit과 429 응답을 기록한다. 기준을 충족하면 이미지 선택 → 분석 DTO/검증 → 검토 화면 → 저장/조회 갱신 순으로 연결한다.
- T07–T08의 이미지 바이트·디코딩 해상도·50건 상한·출력 검증을 적용한다. 기존 함수의 MIME 헤더만 믿는 검사와 무제한 응답 대기를 보완한다. 클라우드 경로에는 인증·활성 가계부 소속·원자적 호출량 제한을 적용한다. 기본 분석 제한은 30초이며 로컬 모델 측정에 따라 변경하면 설정값과 근거를 기록한다.
- 단건/복수/누락 연도/합계/취소/저화질/중복/상품권/이미지 내 지시문 사례를 검증한다. 추출 오류를 수정한 값이 저장되는지, 전체 선택 해제·취소 시 미저장, 실패 후 재시도 중복 방지, 저장 후 월/일 합계 반영을 확인한다.
- 실제 공급자와 개인정보 없는 별도 평가 이미지로 필드 정확도·누락/추가 건수·실패율·처리 시간·사용량을 기록한다. fixture 테스트만으로 완료 처리하지 않는다. 실제 공급자 미설정 또는 미검증이면 T13은 미완료다.
- flutter analyze 및 관련 테스트, macOS 실제 선택→분석→저장 검증을 수행한다. iOS 사진 권한/선택/네트워크 검증을 별도로 기록하고 미실행이면 명시한다. 포트폴리오 자료에는 비식별 샘플과 평가 결과만 사용한다.

공식 참고 자료(확인일 2026-09-16, 구현 시 조건 재확인):

- [Gemini API 가격과 무료 티어](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini API 데이터 처리 약관](https://ai.google.dev/gemini-api/terms)
- [Antigravity 플랜](https://antigravity.google/docs/plans)
- [Ollama 이미지 입력](https://docs.ollama.com/capabilities/vision), [구조화 출력](https://docs.ollama.com/capabilities/structured-outputs)
- [Qwen2.5-VL 모델](https://ollama.com/library/qwen2.5vl)

## 토큰 절약용 시작 프롬프트

> docs/implementation-handoff.md를 읽고 T01만 구현해줘. PR #2 병합 여부를 먼저 확인하고 미병합이면 그 사실을 알려줘. 최신 main에서 기능 브랜치를 만들고 관련 코드만 읽어. 이번 작업의 완료 기준을 충족하고 필요한 테스트를 실행한 뒤 커밋·푸시해줘. 다음 작업은 시작하지 말고 변경 요약/검증/남은 항목을 짧게 보고해줘.

이후 T번호만 바꾼다. 긴 이전 대화를 매번 붙이지 않는다. 결과마다 작업 ID/커밋/검증/다음 ID를 기록해 새 세션에서 이어갈 수 있게 한다. 모델 선택이나 화면의 사용량 수치만으로 작업 가능 여부를 확정하지 않는다.
