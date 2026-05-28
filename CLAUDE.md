# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & run

Open `Tactl.xcodeproj` in Xcode 15+. Build and run on a real iPhone (not simulator) — haptics, Full Access, and pasteboard behave differently in the simulator.

```bash
# Build from CLI (requires xcode-select pointing to Xcode 15+)
xcodebuild -project Tactl.xcodeproj -scheme Tactl -destination 'platform=iOS,name=<YOUR_DEVICE>' build
```

Tests:
```bash
xcodebuild test -project Tactl.xcodeproj -scheme TactlTests -destination 'platform=iOS,name=<YOUR_DEVICE>'
```

## Architecture

Two targets share source files from a `TactlShared/` directory (added to both target memberships — no separate framework):

- **Tactl** (containing app) — SwiftUI only. Settings UI, onboarding card. Writes settings to App Group `UserDefaults`.
- **TactlKeyboard** (extension) — UIKit only. Never use SwiftUI inside the keyboard extension; it is unreliable in input extensions.
- **TactlShared/** — `AppGroup.swift`, `Settings.swift`, `HapticEngine.swift`, `ClipboardEntry.swift`. Both targets compile these directly.

**App Group:** `group.com.uves.tactl`
**Bundle IDs:** App `com.uves.tactl`, Extension `com.uves.tactl.keyboard`
**Min iOS:** 16.0
**No third-party SPM packages** — keep fully self-contained.

### Shared state flow

Settings are written as a single JSON blob to App Group `UserDefaults` under key `"tactl.settings.v1"`. The extension reads on `viewWillAppear` (snapshot, no live observation). The containing app uses a `SettingsStore: ObservableObject` with `@Published var current: TactlSettings`.

Clipboard history is stored as `clipboard.json` in the App Group file container.

### Keyboard extension structure (target layout from PRD)

```
TactlKeyboard/
  KeyboardViewController.swift   # UIInputViewController root; wires all controllers
  Views/
    KeyboardView.swift           # Root container; manual frame layout (not Auto Layout)
    KeyView.swift                # Custom UIView (not UIButton) — precise touch lifecycle
    NumberRowView.swift          # 1–0 row + clipboard key
    ClipboardPanelView.swift     # Overlay replaces keyboard when clipboard opened
    KeyPopupView.swift           # Long-press variant popup via UIWindow overlay
  Controllers/
    LayoutManager.swift          # Page state (letters/symbols1/symbols2) + shift state
    InputHandler.swift           # Tap dispatch → textDocumentProxy
    CursorDragController.swift   # Space-drag cursor nav (hero feature)
    LongPressController.swift    # Per-key timer, popup trigger
    ClipboardManager.swift       # Read/write clipboard.json
  Models/
    Key.swift
    KeyboardLayout.swift         # Static QWERTY, shifted, symbols1, symbols2 layouts
    ClipboardEntry.swift         # (shared with app via TactlShared/)
```

## Critical implementation rules

**Spacebar cursor drag (hero feature):**
- Attach touch handling only to the spacebar hit area — NOT a `UIPanGestureRecognizer` on the whole keyboard view (conflicts with key tap detection).
- Use `textDocumentProxy.adjustTextPosition(byCharacterOffset:)`. It silently no-ops at text boundaries — never accumulate phantom state.
- Default `pointsPerCharacter = 8.0`; tune on real device.

**Key views:**
- Use custom `UIView` with `touchesBegan/Moved/Ended/Cancelled`, not `UIButton`. We need precise touch lifecycle for long-press and drag.
- Use manual frame layout in `KeyboardView`, not Auto Layout — avoids constraint churn on every layout pass.

**Long-press popup:**
- Use a `UIWindow` overlay so the popup can extend above the keyboard's clipped bounds. Test on real device — simulator clips differently.

**Clipboard / pasteboard:**
- Never call `UIPasteboard.general` on `viewDidLoad` — iOS 14+ shows a privacy banner.
- Only read pasteboard: (a) when the clipboard panel is explicitly opened, or (b) once on `viewDidAppear` after a 1-second delay.
- Gate all clipboard and haptic features behind `hasFullAccess` (the `UIInputViewController` property).

**Height constraint:**
- Store the height `NSLayoutConstraint` reference. Deactivate the old one before activating a new one when settings change.

**Settings changes:**
- Write to App Group `UserDefaults` immediately on every mutation. The extension reads on next `viewWillAppear`; no cross-process notifications needed for v1.

## Settings schema

```swift
struct TactlSettings: Codable {
    var keyboardHeight: CGFloat = 280          // 200...340 pt
    var longPressDuration: TimeInterval = 0.3   // 0.1...0.6 s
    var spaceCursorEnabled: Bool = true
    var spaceCursorVerticalEnabled: Bool = false
    var numberRowEnabled: Bool = true
    var clipboardEnabled: Bool = true
    var clipboardMaxEntries: Int = 20
    var hapticIntensity: HapticIntensity = .light
    var theme: ThemeMode = .system
    var keyPopupEnabled: Bool = true
}
```

## Theming (Gboard palette)

- Light: key `#FFFFFF`, keyboard bg `#D1D4DB`, text `#000000`
- Dark: key `#3C4043`, keyboard bg `#202124`, text `#FFFFFF`
- Accent (shift active, clipboard pins): `#1A73E8`
- Font: SF Pro system, 22pt letter labels, 16pt function key labels
- Press animation: `UIView.animate` 0.08s ease-out
