# SorryBuddy v0.1.6 Manual

SorryBuddy v0.1.6 is a personal test build for keeping a MacBook awake while the lid is closed.

## What It Does

- Opens a small control window and also adds a SorryBuddy sprout icon to the menu bar.
- Keeps running as a visible sprout icon in the menu bar if the control window is closed.
- Uses a minimal eyes-and-sprout icon derived from the first hand-drawn sketch.
- Turns closed-lid sleep prevention on with administrator approval.
- Turns it off from the same menu.
- Watches lid state every 2 seconds and sets the built-in display brightness to 0 when the lid is closed.
- Restores the previous brightness when the lid opens or the mode is turned off.
- Checks battery state every 60 seconds.
- Turns the mode off automatically at 10% battery while running on battery power.
- Restores the mode on app quit if this app enabled it during the same run.
- Checks GitHub Releases for newer DMG builds from the menu bar.

## Safety Rules

Use only on a desk, with ventilation, while you can physically check the MacBook.

Do not use this mode:

- Inside a bag, sleeve, drawer, case, or closed storage.
- On a bed, blanket, sofa, cushion, or any soft surface.
- In direct sun, a hot room, a car, or near heaters.
- While charging with a suspicious cable, adapter, hub, or dock.
- When the MacBook is already hot, noisy, swollen, damaged, wet, or unstable.
- For unattended overnight use.

This test build changes a power-management setting at the user's request. Hardware damage, data loss, battery wear, heat damage, or interrupted work remain the user's responsibility.

## Build

```bash
cd /Users/han/Documents/sorrybuddy
./scripts/package-app.sh
```

The packaged app is created at:

```text
/Users/han/Documents/sorrybuddy/.build/release/SorryBuddy.app
```

## First Test

1. Open `.build/release/SorryBuddy.app`.
2. The SorryBuddy control window should appear.
3. Toggle the main switch to `켜짐`.
4. Read the warning and choose `켜기`.
5. Enter the macOS administrator password when prompted.
6. Keep the MacBook on a desk and verify it remains reachable while closed.

If no window appears, click the sprout menu bar icon and choose `제어 창 열기`, or run:

```bash
open -n /Users/han/Documents/sorrybuddy/.build/release/SorryBuddy.app
```

If the window was closed with the red X button, click the sprout menu bar icon and choose `제어 창 열기`.

To fully quit SorryBuddy, click the sprout icon in the menu bar and choose `종료하기`.

If the menu opens from an empty menu bar area or the sprout icon is missing, check any menu bar organizer app such as Ice, Hidden Bar, or Bartender and move SorryBuddy into the visible area.

To check for a newer build, click the sprout icon in the menu bar and choose `업데이트 확인...`.

## Verify Current State

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

Some macOS versions hide `SleepDisabled` when it is off. In that case, absence usually means the mode is not active.

## Emergency Recovery

If the app is closed, stuck, or the setting looks wrong:

```bash
sudo pmset -a disablesleep 0
pmset -g | grep -E 'SleepDisabled|sleep'
```

Then restart the Mac if the power state still looks unusual.

## AI CLI Work Notes

The next product layer should add a CLI companion that watches battery state and asks active LLM coding sessions to checkpoint before 10%. The v0 app does not yet checkpoint Codex, Claude, Gemini, or other CLI agents.
