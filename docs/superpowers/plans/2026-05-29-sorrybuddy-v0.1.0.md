# SorryBuddy v0.1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build SorryBuddy v0.1.0, a local macOS menu bar app that lets Han enable and disable closed-lid work mode for testing.

**Architecture:** SwiftPM builds a small SwiftUI `MenuBarExtra` app and a testable `SorryBuddyCore` library. The app uses administrator-authorized `pmset disablesleep` commands, reads status through `pmset -g`, and disables the mode when battery safety rules say it should stop.

**Tech Stack:** Swift 6.1, SwiftUI, AppKit, SwiftPM, Swift Testing, `/usr/bin/pmset`, `/usr/bin/osascript`.

---

### Task 1: Core Parser

**Files:**
- Modify: `Package.swift`
- Create: `Sources/SorryBuddyCore/PowerStatus.swift`
- Create: `Sources/SorryBuddyCore/PMSetParser.swift`
- Test: `Tests/SorryBuddyCoreTests/PowerStatusParserTests.swift`

- [ ] Write failing parser tests for `SleepDisabled`, AC/battery source, battery percentage, and charging state.
- [ ] Run `swift test` and confirm parser symbols are missing.
- [ ] Implement the minimum parser and status types.
- [ ] Run `swift test` and confirm parser tests pass.

### Task 2: Power Policy Service

**Files:**
- Create: `Sources/SorryBuddyCore/ShellClient.swift`
- Create: `Sources/SorryBuddyCore/PowerPolicyService.swift`
- Test: `Tests/SorryBuddyCoreTests/PowerPolicyServiceTests.swift`

- [ ] Write tests proving enable/disable call the exact administrator command wrappers.
- [ ] Implement a shell client protocol and a service that runs `pmset -a disablesleep 1` or `0` through AppleScript administrator privileges.
- [ ] Add a battery safety helper that returns `.disableSoon` at 22% and `.disableNow` at 20% while on battery.
- [ ] Run `swift test`.

### Task 3: Menu Bar App

**Files:**
- Create: `Sources/SorryBuddy/SorryBuddyApp.swift`
- Create: `Sources/SorryBuddy/AppState.swift`

- [ ] Add a SwiftUI `MenuBarExtra` with current mode, battery status, enable, disable, refresh, and quit controls.
- [ ] Show a Korean safety warning before enabling closed-lid mode.
- [ ] Disable closed-lid mode on quit if the app enabled it during this run.
- [ ] Poll status every 60 seconds.

### Task 4: Packaging and Manual

**Files:**
- Create: `scripts/package-app.sh`
- Create: `docs/MANUAL.md`

- [ ] Build the executable with `swift build`.
- [ ] Package `.build/release/SorryBuddy.app` manually with `Info.plist`.
- [ ] Add a Korean manual warning against use in bags, hot places, beds, and low-battery conditions.
- [ ] Verify `swift test`, `swift build -c release`, and package script.
