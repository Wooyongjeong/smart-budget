# 구현 인계: 작은 작업 단위로 진행하기

2026-09-14. 모델 이름과 관계없이 한 번에 아래 작업 하나만 맡긴다. 제품 요구는 inception.md, 상세 정책은 design.md, 현재 구현 증거는 construction.md를 따른다. 이 문서는 실행 계약을 보완한다. 새 제한값은 구현 기본안이며 출시 정책으로 확정된 값이 아니다.

## 현재 상태와 시작점

- PR #1 병합: 네 탭, 테마 10종, macOS 실행 지원.
- PR #2: feat/manual-entry-form → main. 직접 입력은 **확인 미리보기**이며 실제 저장되지 않는다. 병합 여부는 시작할 때 GitHub에서 확인한다.
- 카카오 로그인, DB, 캘린더 집계, 카드 실적, 상품권, AI는 아직 없다. 화면 문구와 테스트 통과를 기능 완성으로 오인하지 않는다.
- 기존 저장소: lib/main.dart, lib/themes.dart. PR #2에는 lib/entry_form.dart와 test/entry_form_test.dart가 추가된다.
- 다음 작업은 T01. PR #2에 의존하는 작업은 병합 후 시작한다. 다른 브랜치의 미커밋 내용을 섞지 않는다.

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
| T10 | 카드 등록과 목표·예상 실적 | T03,T04,T06 | 카드별·월별 목표, 포함/제외, 소유자, 보관 |
| T11 | 상품권·초기 잔액·환불 | T04,T10 | 아래 금액 불변식과 동시 사용·소급 수정 테스트 |
| T12 | 출시 점검 | 모두 | 실기기, 계정 삭제/보존, AI 비용/품질, 운영 오류 확인 |

T03/T04/T08/T09/T11은 권한·금액·외부 AI 경계라서 구현 후 별도 검토를 권장한다. 검토 모델을 매번 쓰기보다 관련 변경을 묶어 검토한다. 테스트만으로 안전성이 보장된다고 간주하지 않는다.

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

## T10–T11: 금액 불변식

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

## 토큰 절약용 시작 프롬프트

> docs/implementation-handoff.md를 읽고 T01만 구현해줘. PR #2 병합 여부를 먼저 확인하고 미병합이면 그 사실을 알려줘. 최신 main에서 기능 브랜치를 만들고 관련 코드만 읽어. 이번 작업의 완료 기준을 충족하고 필요한 테스트를 실행한 뒤 커밋·푸시해줘. 다음 작업은 시작하지 말고 변경 요약/검증/남은 항목을 짧게 보고해줘.

이후 T번호만 바꾼다. 긴 이전 대화를 매번 붙이지 않는다. 결과마다 작업 ID/커밋/검증/다음 ID를 기록해 새 세션에서 이어갈 수 있게 한다. 모델 선택이나 화면의 사용량 수치만으로 작업 가능 여부를 확정하지 않는다.
