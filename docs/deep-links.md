# 초대 링크 배포 설정

앱은 다음 두 형식을 수신한다.

- 운영 링크: `https://<INVITATION_LINK_BASE_URL>/invite/<48자리 토큰>`
- 개발 링크: `smartbudget://invite/<48자리 토큰>`

`INVITATION_LINK_BASE_URL`은 `--dart-define`으로 실제 HTTPS 도메인을 전달한다. 기본값 `https://smart-budget.app/invite`는 예시 도메인이다.

## iOS

실제 도메인의 `https://<host>/.well-known/apple-app-site-association`에 아래 구조를 배포한다. `<TEAM_ID>`와 bundle ID는 Apple Developer 설정값으로 교체한다.

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["<TEAM_ID>.com.example.smartBudget"],
        "components": [{"/": "/invite/*"}]
      }
    ]
  }
}
```

앱에는 `applinks:<host>` Associated Domain entitlement이 포함되어 있다. Apple Developer에서 capability를 활성화하고 배포 프로비저닝 프로파일을 다시 생성해야 한다.

## Android

실제 도메인의 `https://<host>/.well-known/assetlinks.json`에 서명 인증서 지문을 포함한다.

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.smart_budget",
      "sha256_cert_fingerprints": ["<SHA256_CERTIFICATE_FINGERPRINT>"]
    }
  }
]
```

Android intent filter와 iOS entitlement만으로는 HTTPS 링크가 앱으로 검증되지 않는다. 두 파일을 HTTPS로 제공한 뒤 실기기에서 카카오톡 링크 클릭, 앱 미설치 시 웹 fallback, 앱 설치 시 cold start/warm start를 각각 확인한다. 카카오톡 자체 공유 템플릿을 사용하려면 Kakao Developers의 앱 키·메시지 템플릿·검수 설정이 추가로 필요하며, 현재 앱은 OS 공유 시트에서 카카오톡을 선택하는 방식이다.
