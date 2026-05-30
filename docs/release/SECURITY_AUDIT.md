# SorryBuddy 보안 감사

이 문서는 직접 배포용 SorryBuddy 빌드의 보안 체크리스트다.

## 현재 보안 상태

- 앱 번들은 release 모드로 빌드한다.
- 앱 번들에는 `.DS_Store`와 `._*` AppleDouble 파일을 넣지 않는다.
- 앱 바이너리는 `strip -x`를 시도해 로컬 심볼 일부를 제거한다.
- 앱은 hardened runtime 옵션으로 코드 서명한다.
- 현재 이 Mac에는 Developer ID 인증서가 없어서 ad-hoc 서명이다.
- 일반 DMG는 체크섬 검증이 가능하다.
- 암호화 DMG는 AES-256과 비밀번호로 보호한다.
- 암호화 DMG는 비밀번호 없이는 마운트되지 않는 것을 확인한다.
- 앱은 토큰, 비밀번호, 비공개 키를 포함하지 않아야 한다.

## 원리상 불가능한 것

사용자가 비밀번호로 DMG를 열고 앱을 실행할 수 있다면, macOS 앱 번들은 Finder의 패키지 내용 보기나 터미널로 열람할 수 있다. 암호화 DMG는 배포 컨테이너 보호이지, 실행 가능한 앱 내부의 영구 은닉이 아니다.

## 공개 배포 전 필수 조건

1. Apple Developer Program 계정 준비.
2. Developer ID Application 인증서 준비.
3. 필요하면 Developer ID Installer 인증서 준비.
4. `CODESIGN_IDENTITY`로 Developer ID 서명.
5. `notarytool`로 DMG 제출.
6. `stapler`로 공증 티켓 stapling.
7. `REQUIRE_DEVELOPER_ID=1 ./scripts/verify-distribution.sh` 통과.

Developer ID와 notary profile이 준비된 뒤 전체 릴리즈를 만들 때:

```bash
./scripts/secure-release.sh
```

`secure-release.sh`는 같은 앱 번들을 기준으로 일반 DMG, AES-256 암호화 DMG, PKG, 체크섬 파일을 만든다. `NOTARY_KEYCHAIN_PROFILE`이 있으면 앱 번들을 먼저 공증하고 stapling한 뒤 그 앱을 DMG들에 넣는다.

## 로컬 감사 명령

```bash
./scripts/verify-distribution.sh
```

Developer ID까지 요구하는 공개 배포 엄격 감사:

```bash
REQUIRE_DEVELOPER_ID=1 ./scripts/verify-distribution.sh
```
