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

이용내역 캡처는 이미지 선택 → 멀티모달 모델 분석 → 사용자 확인·수정 → 일괄 저장 흐름을 제공합니다. 현재 OpenRouter 기본 무료 모델은 404를 반환하며, 대체 무료 모델도 429 제한을 확인했으므로 운영 가능한 공급자 선택과 품질·개인정보 정책 검증이 남았습니다. 개발 중에는 별도 Mac의 Ollama 비전 모델에 직접 연결할 수 있습니다. 배우자 초대 UI는 구현했지만, HTTPS 원탭 링크는 도메인 확보 후 검증해야 합니다.

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

이미지 분석을 사용하려면 Supabase Edge Function Secret에 OpenRouter 키를 등록합니다. OpenRouter 키는 `.env.json`이나 Flutter `--dart-define`에 넣지 않습니다.

```sh
supabase secrets set OPENROUTER_API_KEY=your-openrouter-key
supabase secrets set OPENROUTER_MODEL=inclusionai/ling-3.0-flash-vl:free
supabase functions deploy analyze-receipt
```

무료 모델은 가용성·호출 제한이 바뀔 수 있습니다. 함수는 `OPENROUTER_MODEL`을 지정하지 않으면 위 무료 모델을 기본값으로 사용합니다. 개발·시연에는 개인정보 없는 합성 또는 비식별 이미지를 사용하세요.

같은 LAN의 Ollama를 Android 디버그 앱에서 시험하려면 다른 Mac의 Ollama를 LAN에 바인딩하고 다음처럼 실행합니다. 이 경로는 개발용이며 인증·서버 일일 사용량 제한을 우회하고 이미지가 암호화되지 않은 LAN HTTP로 전송됩니다. 신뢰할 수 있는 사설 Wi-Fi에서 합성 이미지로만 시험하고 인터넷에 11434 포트를 공개하지 마세요.

```sh
# Ollama가 실행 중인 다른 Mac에서 (macOS 앱은 완전히 재시작)
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
# 이 저장소의 Mac에서 연결 확인
curl http://10.55.251.29:11434/api/tags
# 연결된 Android에서 디버그 실행
bash tool/run_configured.sh DEVICE_ID --dart-define=OLLAMA_BASE_URL=http://10.55.251.29:11434 --dart-define=OLLAMA_MODEL=qwen3-vl:2b-instruct-q4_K_M
```

Ollama 앱을 사용하지 않고 터미널에서 직접 서버를 실행한다면 `OLLAMA_HOST=0.0.0.0:11434 ollama serve`를 사용합니다. 연결이 안 되면 Mac 방화벽과 Wi-Fi의 클라이언트 격리 여부를 확인하세요. 상세 경계는 [AI 연결 기록](docs/construction.md)을 참고하세요.

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
bash tool/run_configured.sh macos
```

iPhone simulator 또는 연결된 기기:

```sh
flutter devices
bash tool/run_configured.sh DEVICE_ID
```

설정이 없거나 올바르지 않으면 앱은 인증 설정 안내 화면을 표시합니다.
실행 스크립트는 `jq`가 필요하며 `.env.json`에서 공개 앱 설정 세 값만 전달합니다. 추가 `--dart-define` 인자를 뒤에 넘길 수 있습니다. 로컬 파일에 AI 공급자 키가 있어도 `--dart-define-from-file=.env.json`으로 전체를 앱에 넣지 마세요. AI 키는 Supabase Edge Function Secret에만 둡니다.

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
- [제품 완성도 개선 백로그](docs/product-improvement-backlog.md)

기본 브랜치는 `main`입니다. 기능은 별도 브랜치에서 구현하고 테스트와 리뷰를 거쳐 PR로 병합합니다.
