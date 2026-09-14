# Smart Budget

부부가 함께 사용하는 Flutter 가계부 앱. Supabase 기반으로 수동 입력과 AI 이용내역 캡처 입력, 카드 실적, 상품권 잔액 관리를 계획한다.

현재는 AI-DLC Inception 검토 후 첫 화면을 구현 중이다. 네 탭과 기기별 테마 선택을 제공하며, 금융 화면은 데이터 미연결 안내 상태이다. Supabase 및 AI 서비스 연결과 거래 기능은 아직 구현하지 않았다.

## 기획

- [요구사항·사용자 흐름·검증 기준](docs/inception.md)
- [설계 결정·진행 기록](docs/decision-log.md)
- [화면·데이터·권한 상세 설계 초안](docs/design.md)

## 개발

기본 브랜치는 `main`이다. Flutter SDK 설치 후 다음 명령으로 기본 프로젝트를 실행한다.

기획·설계 문서는 검토 후 `main`에 반영한다. 실제 구현은 `feat/...` 등 별도 기능 브랜치를 생성해 진행하며, 검증과 리뷰를 거쳐 병합한다.

```sh
flutter pub get
flutter run
```

Mac에서 화면을 테스트하려면 `flutter run -d macos`를 실행한다. macOS 지원은 아이폰 연결 없이 탭과 테마를 확인하기 위한 개발용 실행 대상이다.

실제 이용내역 캡처, API 비밀 키, 서명 키는 저장소에 포함하지 않는다.
