# Smart Budget

신혼부부가 함께 수입과 지출을 기록하고 카드 실적과 상품권 잔액을 관리하는 Flutter 가계부입니다. 별도 애플리케이션 서버 대신 Supabase Auth, PostgreSQL, RPC, RLS와 Edge Functions를 사용합니다.

이 저장소는 문서 기반 AI-DLC 방식으로 개발하고 있습니다. 요구사항과 의사결정, 구현 계약, 검증 결과를 코드와 함께 남겨 다음 작업자가 현재 상태와 미완료 범위를 구분할 수 있도록 했습니다.

## 현재 제공하는 기능

- 카카오 OAuth와 Supabase 세션
- 공동 가계부 데이터의 RLS 기반 접근 제어
- 캘린더 날짜 선택과 월별 거래 조회
- 수입·지출 직접 입력, 확인 후 저장
- 현금·계좌·체크카드·신용카드·상품권 관리
- 카드별 월 목표와 사용 실적 조회
- 할인 상품권의 실제 결제액과 충전액 분리, 잔액 관리
- 한국어·영어 전환 및 12개 앱 테마
- macOS, iOS, Android Flutter 실행 대상

이용내역 캡처 화면은 현재 고정 예시 데이터를 검토하는 단계입니다. Edge Function의 입력·출력 검증 경계는 있지만 실제 AI 공급자 연결, 이미지 선택 UI, 운영 비용·품질 검증은 완료되지 않았습니다. 배우자 초대 RPC는 있으나 앱 UI와 실시간 동기화도 후속 범위입니다. 자세한 차이는 [코드 리뷰](docs/code-review.md)에서 확인할 수 있습니다.

## 기술 구성

- Flutter / Dart
- Supabase Auth + Kakao OAuth
- Supabase PostgreSQL, RLS, security-definer RPC
- Supabase Edge Functions
- pgTAP과 Flutter widget/unit tests
- Flutter `gen-l10n` 기반 한국어·영어 지원

```text
lib/                         Flutter 앱
  auth/                      인증 설정과 카카오 로그인
  features/transactions/     거래 모델·저장소·AI 검토 화면
  features/payment_methods/  결제 수단과 지갑 화면
  l10n/                      한국어·영어 리소스
supabase/
  migrations/                스키마·RLS·RPC migration
  tests/                     pgTAP 권한·금액 회귀 테스트
  functions/analyze-receipt/ 이미지 분석 함수 경계
docs/                        기획·설계·결정·구현 인계 문서
```

## 실행 준비

Flutter SDK와 Supabase CLI, Docker가 필요합니다. 저장소를 받은 뒤 의존성과 현지화 코드를 생성합니다.

```sh
flutter pub get
flutter gen-l10n
```

`.env.example.json`을 `.env.json`으로 복사하고 본인의 공개 클라이언트 설정을 입력합니다.

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "your-publishable-key",
  "AUTH_REDIRECT_URL": "smartbudget://login-callback"
}
```

`service_role` 키, Kakao client secret, AI 공급자 키는 앱의 환경 파일이나 Git에 넣지 않습니다.

## Supabase와 카카오 설정

1. Supabase 프로젝트에서 Kakao 공급자를 활성화하고 Kakao REST API 키와 client secret을 등록합니다.
2. Kakao Developers의 Redirect URI에는 Supabase가 안내하는 callback URL을 등록합니다.
3. Supabase Auth의 허용 Redirect URL에는 `smartbudget://login-callback`을 등록합니다.
4. 로컬 프로젝트를 연결하고 migration을 적용합니다.

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

OAuth callback scheme은 macOS, iOS, Android 프로젝트에 포함되어 있습니다. 플랫폼별 bundle/application ID와 Kakao 콘솔 설정은 실제 배포 ID에 맞게 다시 확인해야 합니다.

## 앱 실행

macOS 개발 실행:

```sh
flutter run -d macos --dart-define-from-file=.env.json
```

iPhone simulator 또는 연결된 기기:

```sh
flutter devices
flutter run -d DEVICE_ID --dart-define-from-file=.env.json
```

설정이 없거나 올바르지 않으면 앱은 인증 설정 안내 화면을 표시합니다.

## 검증

Flutter 코드:

```sh
flutter analyze
flutter test
flutter build macos --debug
```

로컬 DB migration과 pgTAP:

```sh
supabase start
supabase migration up --local
supabase test db
```

전체 DB를 초기화하는 `supabase db reset`은 로컬 데이터를 삭제하므로 초기 상태 재현이 필요한 경우에만 사용합니다.

## 금액 규칙

- 원화는 정수 `bigint`로 저장합니다.
- 일반 지출은 결제 금액만 지출 합계에 반영합니다.
- 상품권 100,000원을 93,000원에 충전하면 지출은 93,000원, 상품권 잔액 증가는 100,000원입니다.
- 상품권 사용은 잔액만 차감하고 지출을 다시 합산하지 않습니다.
- 상품권 사용 환불은 원거래와 누적 환불 한도를 검증합니다.

## AI-DLC 문서

- [요구사항과 MVP 범위](docs/inception.md)
- [상세 설계](docs/design.md)
- [의사결정 기록](docs/decision-log.md)
- [작업별 구현 계약](docs/implementation-handoff.md)
- [구현 및 검증 기록](docs/construction.md)
- [문서 대비 코드 리뷰](docs/code-review.md)

기본 브랜치는 `main`입니다. 기능은 별도 브랜치에서 구현하고 테스트와 리뷰를 거쳐 PR로 병합합니다.
