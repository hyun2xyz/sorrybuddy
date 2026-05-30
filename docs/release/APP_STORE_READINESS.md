# SorryBuddy App Store Readiness

Date: 2026-05-30
Current version: 0.1.1
Target: Mac App Store release preparation

## Current Verdict

SorryBuddy is not ready for Mac App Store submission in its current form.

The current product goal is to keep a MacBook working while the lid is closed. The implementation does this with system-level behavior that is appropriate for a direct-distribution utility, but conflicts with the likely Mac App Store path.

## Confirmed Current Implementation

- Uses `/usr/bin/pmset -a disablesleep 1` and `0`.
- Requests administrator privileges through `/usr/bin/osascript`.
- Links `DisplayServices` from `/System/Library/PrivateFrameworks`.
- Calls `DisplayServicesGetBrightness` and `DisplayServicesSetBrightness`.
- Ships a GitHub Releases based update checker.
- Ships as a SwiftPM-built ad-hoc signed `.app` and `.dmg`.
- Has no App Sandbox entitlement file yet.
- Has no Xcode archive/export workflow yet.

## App Store Blockers

### 1. Private DisplayServices API

The app currently links a private framework and calls private brightness symbols. This is a hard blocker for App Store review.

Required change:

- Remove `DisplayServices` private framework linkage.
- Remove `DisplayServicesGetBrightness` and `DisplayServicesSetBrightness`.
- Replace with an App Store acceptable public API, or remove automatic brightness control from the App Store build.

Affected files:

- `Package.swift`
- `Sources/SorryBuddyCore/LidBrightnessCoordinator.swift`

### 2. Administrator Power Setting Changes

The app changes a global macOS power setting using `pmset` with administrator privileges. This is high-risk for App Store review and incompatible with a sandbox-first design.

Required change:

- Create an App Store build path that does not run `pmset`.
- Investigate whether a public, sandbox-compatible API can satisfy the core product promise.
- If no acceptable API exists, keep closed-lid prevention as a direct-distribution-only feature.

Affected files:

- `Sources/SorryBuddyCore/PowerPolicyService.swift`
- `Tests/SorryBuddyCoreTests/PowerPolicyServiceTests.swift`

### 3. External Update Mechanism

Mac App Store apps are updated through the App Store. The current GitHub Releases update checker is useful for direct distribution, but should not be in the App Store build.

Required change:

- Gate the GitHub updater behind a direct-distribution build flag, or remove it from the App Store target.
- Do not show `업데이트 확인...` in the App Store build.

Affected files:

- `Sources/SorryBuddy/AppDelegate.swift`
- `Sources/SorryBuddyCore/UpdateChecker.swift`
- `Tests/SorryBuddyCoreTests/UpdateCheckerTests.swift`

### 4. App Sandbox Missing

Mac App Store preparation needs an explicit sandbox entitlement plan.

Expected App Store build entitlements:

- `com.apple.security.app-sandbox`: `true`
- `com.apple.security.network.client`: only if network access remains necessary

For the App Store variant, network access should probably be removed unless a support or release lookup is still required.

### 5. Build and Signing Workflow Missing

The repo currently packages a `.app` manually through SwiftPM. App Store submission needs an Xcode archive/export path with Apple Distribution signing and App Store Connect upload.

Required change:

- Add an Xcode project or a reproducible XcodeGen/Tuist generation path.
- Add App Store entitlements.
- Add archive/export documentation.
- Create an App Store Connect app record.

## Recommended Product Split

### Direct Distribution Build

Purpose: preserve the current power-user utility.

Keep:

- Closed-lid `pmset disablesleep`.
- Administrator authorization.
- Brightness-to-zero behavior if it remains reliable.
- GitHub Releases update checks.
- DMG drag-to-Applications install flow.

Next release path:

- Sign with Developer ID Application.
- Notarize the app and DMG.
- Add Sparkle later if direct distribution becomes a real channel.

### App Store Build

Purpose: create a review-safe Mac App Store variant.

Likely changes:

- Remove private DisplayServices brightness control.
- Remove `pmset` administrator setting changes.
- Remove GitHub update checking.
- Enable sandbox.
- Reframe the product if closed-lid prevention cannot be implemented through public APIs.

Candidate positioning:

- "A menu bar safety assistant for long-running local work."
- Battery and heat warnings.
- Manual checklist before closing lid.
- Optional idle sleep assertion only if public API behavior is acceptable and review-safe.

The App Store version may not be able to promise "keeps working after closing the lid" unless a public, sandbox-compatible implementation is confirmed.

## Required Research Before Implementation

1. Confirm whether a public API can prevent lid-close sleep on MacBooks.
2. Confirm whether App Sandbox allows the chosen power-management API.
3. Confirm whether automatic internal display dimming can be implemented with public APIs.
4. Confirm whether `LSUIElement` menu bar agent apps are acceptable for the intended App Store UX.
5. Confirm App Store Connect metadata requirements for this category.

## App Store Preparation Tasks

### Phase 1: Compliance Decision

- Decide whether SorryBuddy will ship to the Mac App Store with reduced functionality.
- Decide whether the current full-power app remains direct-distribution only.
- Choose App Store name and bundle ID. Recommended bundle ID: `xyz.hyun2.sorrybuddy`.

### Phase 2: Build Split

- Add build configuration markers:
  - `DIRECT_DISTRIBUTION`
  - `APP_STORE`
- Hide updater in `APP_STORE`.
- Hide or replace `pmset` functions in `APP_STORE`.
- Hide or replace brightness functions in `APP_STORE`.

### Phase 3: Signing and Packaging

- Create Xcode archive workflow.
- Add entitlements.
- Add App Store export options.
- Add Developer ID notarization workflow for direct distribution.

### Phase 4: Metadata

- Prepare Korean and English App Store copy.
- Prepare privacy policy.
- Prepare support URL.
- Prepare screenshots.
- Prepare reviewer notes explaining exactly what the app does and does not do.

### Phase 5: Review Build

- Run tests.
- Archive the App Store build.
- Validate archive in Xcode Organizer.
- Upload to App Store Connect.
- Submit first TestFlight or direct review build.

## Open Decisions

- Should the App Store version keep the same name if functionality is reduced?
- Should direct distribution remain the primary product and App Store be a lighter companion?
- Should the app be localized Korean-first or English-first for the first public listing?
- Should the first public release target Mac App Store, direct notarized DMG, or both?

## Official References

- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Sandbox entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_app-sandbox
- App Store Connect Help: https://developer.apple.com/help/app-store-connect/
- Notarizing macOS software before distribution: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- Sparkle documentation: https://sparkle-project.org/documentation/
- GitHub Releases latest release API: https://docs.github.com/en/rest/releases/releases
