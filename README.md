# SorryBuddy

**Version:** 0.1.0

[한국어 README](README.ko.md)

<p align="center">
  <img src="Assets/brand/sorrybuddy-sketch.png" alt="SorryBuddy hand-drawn sketch" width="420">
</p>

SorryBuddy is a small macOS menu bar app for testing closed-lid work mode on a MacBook. It can keep the Mac awake after the lid closes, dim the built-in display to 0 when the lid is closed, and restore the previous brightness when the lid opens or the mode turns off.

This is an experimental personal utility. Use it only when the MacBook is on a desk with ventilation.

## Features

- Menu bar control via a visible sprout icon.
- Closed-lid sleep prevention through `pmset -a disablesleep`.
- Administrator approval before changing the power setting.
- Control window that can be closed while the app keeps running in the menu bar.
- Built-in display brightness goes to 0 when the lid is closed.
- Previous brightness is restored when the lid opens or the mode is disabled.
- Battery safety checks every 60 seconds.
- Automatic mode disable at 20% battery while running on battery power.
- Emergency recovery through a standard `pmset` command.

## Visual Identity

The first SorryBuddy sketch is kept as the project's README artwork. The app icon uses a minimal eyes-and-sprout mark derived from that sketch, with the colored face and enclosing circle removed.

## Requirements

- macOS 13 or newer.
- Apple Swift 6.1 or newer for building from source.
- Administrator password when enabling or disabling closed-lid mode.

## Build

```bash
cd /Users/han/Documents/sorrybuddy
./scripts/package-app.sh
```

The app bundle is created at:

```text
/Users/han/Documents/sorrybuddy/.build/release/SorryBuddy.app
```

## Run

```bash
open /Users/han/Documents/sorrybuddy/.build/release/SorryBuddy.app
```

## Usage

1. Open `SorryBuddy.app`.
2. Click `켜기` in the control window.
3. Read the safety warning and choose `켜기`.
4. Enter the macOS administrator password.
5. Keep the MacBook on a hard, ventilated desk surface.
6. Close the lid and verify the Mac remains reachable.
7. To reopen the control window, click the sprout icon in the menu bar and choose `제어 창 열기`.
8. To disable the mode, click the sprout icon and choose `닫힌 상태 작업 모드 끄기`.
9. To fully quit the app, click the sprout icon and choose `종료하기`.

## Menu Bar Icon Troubleshooting

SorryBuddy runs as a menu bar agent app. It does not need to stay in the Dock.

If the menu opens from an empty area or the sprout icon is not visible, a menu bar organizer such as Ice, Hidden Bar, or Bartender may have hidden the new item. Open that organizer, find `SorryBuddy`, and move it to the visible menu bar area.

## Verify State

```bash
pmset -g | grep -E 'SleepDisabled|sleep'
```

Expected while enabled:

```text
SleepDisabled        1
```

Expected after disabling:

```text
SleepDisabled        0
```

## Emergency Recovery

If the app is closed, stuck, or the power setting looks wrong:

```bash
sudo pmset -a disablesleep 0
pmset -g | grep -E 'SleepDisabled|sleep'
```

Restart the Mac if the power state still looks unusual.

## Safety

Do not use SorryBuddy:

- Inside a bag, sleeve, drawer, case, or closed storage.
- On a bed, blanket, sofa, cushion, or any soft surface.
- In direct sun, a hot room, a car, or near heaters.
- With suspicious chargers, hubs, docks, or cables.
- When the MacBook is already hot, noisy, damaged, wet, swollen, or unstable.
- For unattended overnight use.

SorryBuddy intentionally changes a power-management setting at the user's request. Hardware damage, data loss, battery wear, heat damage, or interrupted work remain the user's responsibility.

## Development

Run tests:

```bash
swift test
```

Build release app:

```bash
./scripts/package-app.sh
```

The code is split into:

- `Sources/SorryBuddy`: SwiftUI/AppKit app and menu bar UI.
- `Sources/SorryBuddyCore`: power-state parsing, `pmset` command wrapper, battery policy, lid/brightness coordinator.
- `Tests/SorryBuddyCoreTests`: parser, power policy, and brightness coordinator tests.
