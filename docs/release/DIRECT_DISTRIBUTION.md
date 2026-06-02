# SorryBuddy 직접 배포 메모

SorryBuddy는 당분간 Mac App Store가 아니라 DMG/PKG로 직접 배포한다.

## 결론

macOS 앱 번들은 사용자가 열어볼 수 있는 구조라서 앱 내부를 완전히 못 뜯게 막는 방식은 현실적이지 않다. 대신 배포 보안의 목표는 아래 세 가지다.

1. 배포 파일이 만든 사람의 파일인지 확인할 수 있게 서명한다.
2. 다운로드 뒤 변조되지 않았는지 Gatekeeper와 공증으로 확인한다.
3. 앱 안에 토큰, 비밀번호, 비공개 키 같은 비밀을 넣지 않는다.

## 현재 로컬 빌드

이 Mac에는 유효한 Developer ID 코드 서명 인증서가 없다. 그래서 현재 스크립트는 로컬 테스트용 ad-hoc 서명으로 앱을 만든다.

현재도 적용되는 보호:

- release 바이너리 빌드
- 로컬 심볼 일부 제거
- 앱 번들 권한 정리
- hardened runtime 옵션으로 코드 서명
- 앱 서명 검증
- 비밀번호 없는 일반 DMG 검증
- PKG payload 검증
- SHA-256 체크섬 출력

Developer ID 인증서를 준비하기 전까지는 사용자가 처음 실행할 때 macOS 경고를 볼 수 있다.

## 공개 배포 DMG

현재 공개 릴리즈는 비밀번호 없는 일반 DMG를 사용한다. 사용자는 DMG를 열 때 별도 비밀번호를 입력하지 않고 `SorryBuddy.app`을 `Applications`로 드래그한다.

앱은 실행되어야 하므로 앱 내부를 절대 볼 수 없게 만드는 것은 불가능하다. 공개 배포 보안은 DMG 암호화보다 Developer ID 서명, 공증, stapling, 업데이트 서명에 기대야 한다.

검증:

```bash
hdiutil isencrypted dist/SorryBuddy-0.1.8.dmg
./scripts/verify-distribution.sh
```

## Developer ID 배포 준비

Apple Developer Program 계정과 인증서가 준비되면 아래 환경 변수를 설정한다.

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export INSTALLER_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)"
```

그 다음 바탕화면용 패키지를 만든다.

```bash
./scripts/package-desktop.sh
```

서명/공증 준비가 끝난 뒤 한 번에 릴리즈 산출물을 만들려면:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE=sorrybuddy-notary \
./scripts/secure-release.sh
```

배포 엄격 검증:

```bash
REQUIRE_DEVELOPER_ID=1 ./scripts/verify-distribution.sh
```

체크섬 생성:

```bash
./scripts/checksums.sh
```

## 공증 흐름

Apple notarytool 프로필이 준비되어 있으면 DMG와 PKG를 각각 제출한다.

```bash
xcrun notarytool submit ~/Desktop/SorryBuddy-0.1.8.dmg --keychain-profile sorrybuddy-notary --wait
xcrun stapler staple ~/Desktop/SorryBuddy-0.1.8.dmg
xcrun notarytool submit ~/Desktop/SorryBuddy-0.1.8.pkg --keychain-profile sorrybuddy-notary --wait
xcrun stapler staple ~/Desktop/SorryBuddy-0.1.8.pkg
```

검증:

```bash
spctl -a -vv --type open ~/Desktop/SorryBuddy-0.1.8.dmg
spctl -a -vv --type install ~/Desktop/SorryBuddy-0.1.8.pkg
```

공증 자동화:

```bash
NOTARY_KEYCHAIN_PROFILE=sorrybuddy-notary ./scripts/notarize-app.sh
NOTARY_KEYCHAIN_PROFILE=sorrybuddy-notary ./scripts/notarize-dmg.sh
```

## 업데이트 방식

현재는 GitHub Releases에서 수동 DMG 다운로드를 여는 방식이다. 자동 업데이트가 필요해지면 Sparkle을 붙인다. Sparkle을 붙일 때는 앱캐스트와 업데이트 파일 서명 키를 별도로 관리하고, 개인 키는 repo에 넣지 않는다.

## 참고한 기준

- Apple: [Signing Mac Software with Developer ID](https://developer.apple.com/developer-id/)
- Apple: [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- Apple: [Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime)
- Sparkle: [Documentation](https://sparkle-project.org/documentation/)
