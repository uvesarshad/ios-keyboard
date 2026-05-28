# Tactl — Product Requirements Document

**A flexible iOS keyboard for power typists who miss Gboard on Android.**

Version: 1.0 (v1 / one-shot build)
Owner: Uves
Target: Personal use, sideload via Apple Developer account
Build mode: Single-pass AI coding agent (Claude Code / Codex CLI)

---

## 1. Why this exists

iOS's stock keyboard and every third-party iOS keyboard (Gboard, Grammarly, SwiftKey) feel rigid compared to Gboard on Android. The cursor-drag on spacebar is twitchy, height is fixed, long-press feels slow, and there's no quick clipboard. Tactl fixes the specific frictions that make iOS typing feel worse than Android — without trying to compete with Apple on autocorrect or with Gboard on swipe typing.

**Non-goals (v1):**
- Swipe / glide typing
- ML-based autocorrect (use iOS `UILexicon` + basic word completion only)
- Voice typing
- Multi-language beyond English
- App Store distribution (personal sideload only)
- iCloud sync

---

## 2. Core feature set

### 2.1 Layout
- Standard QWERTY, Gboard-familiar key sizing and spacing
- **Dedicated persistent number row** at the top (toggleable in settings, default ON)
- Standard symbol page (`?123`) and secondary symbol page (`=\<`)
- Shift, backspace, return, space, comma, period, `?123` toggle
- Long-press any letter to access accented variants and related symbols (Gboard-style popup)
- Comma key long-press → settings shortcut (Gboard parity)

### 2.2 Height adjustment
- Slider in settings: range 200pt to 340pt (default 280pt)
- Live preview in settings app
- Persisted via App Group `UserDefaults`, read by extension on `viewWillAppear`

### 2.3 Spacebar cursor drag
- Touch and hold space → after configurable delay (default 250ms) enter cursor-nav mode
- Horizontal drag adjusts cursor by character offset using `textDocumentProxy.adjustTextPosition(byCharacterOffset:)`
- Vertical drag (optional, default OFF) moves cursor by line
- Haptic feedback on entering nav mode
- Release exits nav mode; no character inserted

### 2.4 Long-press duration setting
- Slider: 100ms to 600ms (default 300ms)
- Applies globally to: character variant popup, space-to-cursor, number row long-press to symbols

### 2.5 Clipboard history
- Requires "Allow Full Access" toggle by user
- Stores last 20 clipboard entries in App Group shared container
- Accessed via dedicated clipboard key on number row, OR long-press on `?123`
- Tap an entry to paste; swipe left to delete
- Pinned entries persist; unpinned auto-expire after 24 hours
- Settings option to disable entirely

### 2.6 Haptics
- Per-key haptic feedback (UIImpactFeedbackGenerator, light by default)
- Intensity slider: Off / Light / Medium / Heavy
- Requires Full Access

### 2.7 Theming
- Light and dark mode (auto-follow system)
- Gboard-inspired color palette:
  - Light: key background `#FFFFFF`, keyboard background `#D1D4DB`, text `#000000`
  - Dark: key background `#3C4043`, keyboard background `#202124`, text `#FFFFFF`
- Accent color for shift active state and clipboard pins: `#1A73E8` (Gboard blue)
- Font: SF Pro (system) at 22pt key labels, 16pt for shift/return/etc.

---

## 3. Architecture

### 3.1 Project structure

```
Tactl/
├── TactlApp/                    # Containing app (settings UI + onboarding)
│   ├── TactlApp.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   └── Info.plist
├── TactlKeyboard/               # Keyboard extension
│   ├── KeyboardViewController.swift
│   ├── Views/
│   │   ├── KeyboardView.swift
│   │   ├── KeyView.swift
│   │   ├── NumberRowView.swift
│   │   ├── ClipboardPanelView.swift
│   │   └── KeyPopupView.swift
│   ├── Controllers/
│   │   ├── LayoutManager.swift
│   │   ├── InputHandler.swift
│   │   ├── CursorDragController.swift
│   │   ├── LongPressController.swift
│   │   └── ClipboardManager.swift
│   ├── Models/
│   │   ├── Key.swift
│   │   ├── KeyboardLayout.swift
│   │   └── ClipboardEntry.swift
│   └── Info.plist
├── TactlShared/                 # Shared framework (App Group)
│   ├── Settings.swift           # UserDefaults wrapper for App Group
│   ├── AppGroup.swift           # Constants
│   └── HapticEngine.swift
└── Tactl.xcodeproj
```

### 3.2 Tech stack
- **Language:** Swift 5.9+
- **UI:** UIKit for keyboard extension (SwiftUI is unreliable in input extensions). SwiftUI for the containing settings app.
- **Min iOS:** 16.0
- **Frameworks:** Foundation, UIKit, Combine (for settings reactivity in app)
- **No third-party dependencies in v1** — keep surface area minimal so the agent doesn't get tangled in SPM resolution. KeyboardKit considered but rejected to keep this fully owned and customizable.

### 3.3 App Group
- Identifier: `group.com.uves.tactl`
- Shared `UserDefaults` suite for settings
- Shared file container for clipboard history (`clipboard.json`)

---

## 4. Settings schema

Stored in App Group `UserDefaults` under suite `group.com.uves.tactl`:

```swift
struct TactlSettings: Codable {
    var keyboardHeight: CGFloat = 280          // 200...340
    var longPressDuration: TimeInterval = 0.3   // 0.1...0.6
    var spaceCursorEnabled: Bool = true
    var spaceCursorVerticalEnabled: Bool = false
    var numberRowEnabled: Bool = true
    var clipboardEnabled: Bool = true
    var clipboardMaxEntries: Int = 20
    var hapticIntensity: HapticIntensity = .light // off/light/medium/heavy
    var theme: ThemeMode = .system              // system/light/dark
    var keyPopupEnabled: Bool = true
}
```

---

## 5. Key implementation details

### 5.1 Spacebar cursor drag (the hero feature)

```swift
// In CursorDragController.swift
// AGENT NOTE: This is the single most important UX feature. Get this right
// or the keyboard is pointless. Test thoroughly with both single-line and
// multi-line text fields.

private var dragStartX: CGFloat = 0
private var lastOffset: Int = 0
private let pointsPerCharacter: CGFloat = 8.0  // tune this

func handleSpaceTouchBegan(at point: CGPoint) {
    dragStartX = point.x
    lastOffset = 0
    // Start timer for longPressDuration; if not exceeded, treat as space tap
}

func handleSpaceDrag(to point: CGPoint, proxy: UITextDocumentProxy) {
    let delta = point.x - dragStartX
    let targetOffset = Int(delta / pointsPerCharacter)
    let diff = targetOffset - lastOffset
    if diff != 0 {
        proxy.adjustTextPosition(byCharacterOffset: diff)
        lastOffset = targetOffset
    }
}
```

**AGENT NOTE:** `adjustTextPosition(byCharacterOffset:)` can fail silently at text boundaries. Don't assume it always moves; don't accumulate state that can't be reconciled.

**AGENT AVOID:** Do not implement cursor drag via UIPanGestureRecognizer on the entire keyboard view — it conflicts with key tap detection. Attach only to the spacebar's hit area with a custom touch handler.

### 5.2 Long-press popup

- After `longPressDuration` ms on a key with variants, show floating popup above the key
- Popup shows variants horizontally (e.g., `e` → `é è ê ë ē`)
- Finger drag selects variant; release commits
- Use a UIWindow overlay or transform-anchored UIView so it can extend beyond keyboard bounds

**AGENT NOTE:** The keyboard extension's view is height-clipped by iOS. Popups that extend above the keyboard's top edge ARE allowed and work — they render in the input accessory window. Test on a real device, not just simulator.

### 5.3 Clipboard

```swift
// ClipboardManager.swift
// AGENT NOTE: Reading UIPasteboard from a keyboard extension requires
// Full Access. Check hasFullAccess before reading. Do NOT poll the
// pasteboard continuously — only check on keyboard appear and when
// the clipboard panel is opened.

func capturePasteboardIfChanged() {
    guard hasFullAccess else { return }
    guard UIPasteboard.general.hasStrings else { return }
    guard let string = UIPasteboard.general.string else { return }
    if string != lastCaptured {
        addEntry(string)
        lastCaptured = string
    }
}
```

**AGENT AVOID:** Do not call `UIPasteboard.general` on `viewDidLoad`. iOS 14+ shows a privacy banner to the user every time you read the pasteboard. Only read when the clipboard panel is explicitly opened, OR once on `viewDidAppear` after a 1s delay.

### 5.4 Height adjustment

```swift
// KeyboardViewController.swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let height = Settings.shared.keyboardHeight
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
}
```

**AGENT NOTE:** You must deactivate the old height constraint before activating a new one when settings change. Store the constraint reference.

### 5.5 Full Access detection

```swift
var hasFullAccess: Bool {
    return self.hasFullAccess  // UIInputViewController property
}
```

If Full Access is off, show a banner in the keyboard suggesting the user enable it. Clipboard and haptics gracefully degrade.

---

## 6. Settings app (containing app)

SwiftUI-based, minimal. Single scrollable settings screen:

1. **Onboarding card** (shown until dismissed): "Enable Tactl in Settings → General → Keyboard → Keyboards → Add New Keyboard → Tactl → Allow Full Access"
2. **Keyboard height** — slider with live numeric value
3. **Long-press duration** — slider with live numeric value (in ms)
4. **Spacebar cursor drag** — toggle, sub-toggle for vertical
5. **Number row** — toggle
6. **Clipboard history** — toggle, "Clear history" button
7. **Haptics** — segmented control (Off / Light / Medium / Heavy)
8. **Theme** — segmented control (Auto / Light / Dark)
9. **About** — version, GitHub link placeholder

**AGENT NOTE:** Settings changes must be written to App Group UserDefaults immediately. The keyboard extension reads on `viewWillAppear`, so changes apply next time the keyboard opens. Do not attempt cross-process notifications (Darwin notifications work but add complexity; skip for v1).

---

## 7. Build & sideload setup

**Prerequisites:**
- Mac with Xcode 15+
- Apple Developer account ($99/year) — required for >7-day install on personal device
- iPhone running iOS 16+

**AGENT SEE:** Bundle identifiers
- App: `com.uves.tactl`
- Extension: `com.uves.tactl.keyboard`
- App Group: `group.com.uves.tactl`

**AGENT DECIDE:** Code signing — agent should configure automatic signing with the user's team ID. Prompt the user for their team ID once during setup; do not hardcode.

---

## 8. Testing checklist (manual, post-build)

- [ ] Keyboard appears in Settings → Keyboards after enabling
- [ ] Typing works in Notes, Safari URL bar, Messages, Mail
- [ ] Height slider visibly changes keyboard height
- [ ] Space-drag moves cursor smoothly without inserting space
- [ ] Tap space (no drag) inserts space
- [ ] Double-tap space inserts period + space (Gboard parity)
- [ ] Long-press `e` shows accent variants
- [ ] Number row toggle hides/shows row and reflows keyboard
- [ ] Clipboard panel opens with last copied items
- [ ] Haptics fire on each key (with Full Access on)
- [ ] Dark mode switches with system
- [ ] No pasteboard privacy banner appears during normal typing

---

## 9. Known limitations (acknowledge in code comments)

- Autocorrect is intentionally minimal in v1 — relies on `UILexicon` only
- No swipe typing
- Clipboard history is local to device; no sync
- Cannot intercept system-level shortcuts (CapsLock, etc.)
- Full Access is required for haptics and clipboard (iOS limitation)

---

## 10. Agent directives summary

**AGENT NOTE — must-knows:**
- Build for real device, not simulator (haptics, full access, and pasteboard behave differently)
- UIKit only in the extension; SwiftUI only in the containing app
- All shared state goes through App Group UserDefaults
- Test space-cursor-drag obsessively — it's the hero feature

**AGENT AVOID:**
- Third-party SPM packages (keep it self-contained)
- Polling the pasteboard
- UIPanGestureRecognizer on the whole keyboard view
- Hardcoding the developer team ID
- SwiftUI inside the keyboard extension

**AGENT SEE:**
- Bundle IDs in section 7
- Settings schema in section 4
- File structure in section 3.1

**AGENT DECIDE:**
- Exact `pointsPerCharacter` value for space-drag sensitivity (start at 8.0, tune)
- Popup styling details within the Gboard-familiar aesthetic
- Animation curves for press states (use `UIView.animate` with 0.08s ease-out)

---

## 11. Out of scope but worth noting for v2

- Swipe typing (consider integrating an open-source gesture-to-text engine)
- Custom autocorrect via Core ML
- Theme editor with custom colors
- Keyboard shortcuts row for current app context
- Emoji search
- Multi-language switching
