# 초대 링크 배포 설정

앱은 다음 두 형식을 수신한다.

- 개발 기본값: `smartbudget://invite/<48자리 토큰>`
- 향후 운영 링크: `https://<host>/invite/<48자리 토큰>`

현재 소유한 HTTPS 도메인이 없으므로 기본값은 커스텀 스킴이다. `INVITATION_LINK_BASE_URL`은 도메인과 검증 파일을 준비한 뒤 `--dart-define`으로 `https://<host>/invite`를 전달한다. 종전 예시 `smart-budget.app`은 DNS가 없어 운영 링크로 사용할 수 없다. Android에서 커스텀 스킴의 앱 인텐트 해석은 확인했으나 카카오톡에서 원탭 링크로 인식되는지는 별도 실기기 검증이 필요하다. 공유 메시지에는 복사용 초대 코드도 포함한다.

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
