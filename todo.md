# Tactl Build — Task List

Sequenced from PRD v1. Each task is concrete and verifiable. Check off as you go.

---

## Phase 0 — Project scaffolding & shared layer

- [ ] **0.1 Verify Xcode targets**
  - Confirm `Tactl` (app) and `TactlKeyboard` (extension) targets exist with matching bundle IDs (`com.uves.tactl`, `com.uves.tactl.keyboard`)
  - Confirm both have `group.com.uves.tactl` App Group capability enabled
  - Confirm min iOS deployment target = 16.0 on both targets

- [ ] **0.2 Create TactlShared source folder**
  - Add `TactlShared/` directory inside the project
  - Files: `AppGroup.swift`, `Settings.swift`, `HapticEngine.swift`, `ClipboardEntry.swift`
  - Add each file to BOTH `Tactl` and `TactlKeyboard` target membership (no separate framework target — share via source membership to avoid SPM/framework setup overhead)

- [ ] **0.3 Implement `AppGroup.swift`**
  - Constant: `static let identifier = "group.com.uves.tactl"`
  - Helper: `static let defaults = UserDefaults(suiteName: identifier)!`
  - Helper: `static let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)!`

- [ ] **0.4 Implement `Settings.swift`**
  - `enum HapticIntensity: String, Codable { case off, light, medium, heavy }`
  - `enum ThemeMode: String, Codable { case system, light, dark }`
  - `struct TactlSettings: Codable` with all fields from PRD §4 + sensible defaults
  - `final class SettingsStore: ObservableObject` (for SwiftUI app):
    - `@Published var current: TactlSettings`
    - `load()` reads single JSON blob from App Group defaults under key `"tactl.settings.v1"`
    - `save()` writes JSON back; called on every mutation
  - Static `Settings.shared` snapshot API for the extension (read-only, fetched on each `viewWillAppear`)

- [ ] **0.5 Implement `HapticEngine.swift`**
  - Wraps `UIImpactFeedbackGenerator` keyed by intensity
  - `static let shared` with `prepare()` and `fire(intensity:)`
  - No-op when intensity is `.off` or when Full Access is disabled

---

## Phase 1 — Containing app (settings UI)

- [ ] **1.1 Replace `ContentView.swift` with `SettingsView`**
  - SwiftUI `NavigationStack` containing a scrollable settings form
  - Inject `@StateObject var store = SettingsStore()`

- [ ] **1.2 Implement onboarding card**
  - Dismissible card at top of settings: enable instructions per PRD §6.1
  - Dismissal state persisted in App Group defaults (`onboardingDismissed: Bool`)

- [ ] **1.3 Implement setting controls** (all bind to `store.current.*` with `onChange { store.save() }`)
  - Keyboard height slider (200…340, step 1), live numeric readout in pt
  - Long-press duration slider (100…600 ms, step 10), live readout
  - Spacebar cursor drag toggle + nested vertical toggle (disabled when parent off)
  - Number row toggle
  - Clipboard history toggle + "Clear history" button (deletes `clipboard.json`)
  - Haptics segmented control (Off / Light / Medium / Heavy)
  - Theme segmented control (Auto / Light / Dark)
  - About section: version from `Info.plist`, placeholder GitHub link

- [ ] **1.4 Build & launch app on simulator**
  - Confirm all controls render and persist across relaunches
  - Verify JSON blob written to App Group defaults

---

## Phase 2 — Keyboard data model & layout

- [ ] **2.1 `Models/Key.swift`**
  - `struct Key`: id, primary label, shifted label, variants `[String]`, width weight (CGFloat), kind enum (`.character`, `.shift`, `.backspace`, `.return`, `.space`, `.symbolToggle`, `.symbol2Toggle`, `.numberRow`, `.clipboard`, `.comma`, `.period`)

- [ ] **2.2 `Models/KeyboardLayout.swift`**
  - Static layouts: `qwertyLetters`, `qwertyShifted`, `symbols1` (`?123`), `symbols2` (`=\<`)
  - Each layout is `[[Key]]` (rows)
  - Number row defined separately so it can be toggled on/off without re-defining letter rows
  - Long-press variants table: e → é è ê ë ē, a → à á â ã ä, etc. (Gboard-style, English subset)

- [ ] **2.3 `Controllers/LayoutManager.swift`**
  - Holds current page state (`letters` / `symbols1` / `symbols2`) and shift state (`off`, `on`, `caps`)
  - Returns the active `[[Key]]` for the renderer
  - Emits change notifications via Combine `PassthroughSubject` so views re-render

---

## Phase 3 — Keyboard rendering (UIKit)

- [ ] **3.1 Rewrite `KeyboardViewController.swift`**
  - Strip the Apple "Next Keyboard" boilerplate (keep only `needsInputModeSwitchKey` handling; the next-keyboard button must remain reachable somewhere — bottom-left of bottom row when `needsInputModeSwitchKey` is true)
  - On `viewWillAppear`: load `Settings.shared`, rebuild keyboard view, apply height constraint (store reference so it can be deactivated)
  - Wire up: `LayoutManager`, `InputHandler`, `CursorDragController`, `LongPressController`, `ClipboardManager`, `HapticEngine`

- [ ] **3.2 `Views/KeyboardView.swift`**
  - Root container UIView that lays out: optional `NumberRowView`, letter rows, bottom function row
  - Uses manual frame layout (not Auto Layout) for each row's keys — faster and avoids constraint churn on every layout
  - Theme-aware background per PRD §2.7

- [ ] **3.3 `Views/KeyView.swift`**
  - Custom UIView (not UIButton — we need precise touch lifecycle for long-press and drag)
  - Renders rounded rect background + centered label
  - `touchesBegan/Moved/Ended/Cancelled` hooks delegated up to `InputHandler` and `LongPressController`
  - Press-state animation: `UIView.animate` 0.08s ease-out for background highlight
  - Theme-aware colors

- [ ] **3.4 `Views/NumberRowView.swift`**
  - Renders 1–0 row with long-press variants for symbols (1 → !, 2 → @, etc.)
  - Includes clipboard key on the right edge (if clipboard enabled)
  - Hidden entirely when `numberRowEnabled = false`; layout reflows

- [ ] **3.5 `Views/KeyPopupView.swift`**
  - Floating popup shown above the pressed key during long-press
  - Renders horizontal row of variants; current selection highlighted as finger drags
  - Anchored to keyboard window via a UIWindow overlay so it can extend above keyboard bounds (per PRD §5.2)
  - Dismiss on touch-up, commit selected variant

---

## Phase 4 — Input handling

- [ ] **4.1 `Controllers/InputHandler.swift`**
  - `handleTap(_ key: Key)`:
    - Character keys → `textDocumentProxy.insertText(...)` (respect shift state, then auto-clear single shift)
    - Backspace → `deleteBackward()` (with repeat-on-hold via timer)
    - Return → `insertText("\n")`
    - Comma/period → insert; period also triggers double-space-period logic
    - Shift → cycle `off → on → caps → off`
    - Symbol toggles → switch page in `LayoutManager`
  - Double-tap space → replace trailing space with `. ` (Gboard parity)
  - Fire `HapticEngine.fire` for every successful input event

- [ ] **4.2 `Controllers/LongPressController.swift`**
  - Per-key timer started on `touchesBegan` using `Settings.shared.longPressDuration`
  - On fire: show `KeyPopupView` with variants for that key, switch to drag-to-select mode
  - Comma long-press → open the containing app's settings (use `extensionContext?.open(URL("tactl://settings"))` with a custom URL scheme registered in the app's Info.plist)

- [ ] **4.3 `Controllers/CursorDragController.swift`** *(hero feature — PRD §5.1)*
  - Attached only to the spacebar's hit area (NOT a global UIPanGestureRecognizer — PRD AGENT AVOID)
  - `touchesBegan`: record start point, start activation timer (`longPressDuration`)
  - If timer fires before release: enter nav mode, haptic, switch from "pending space tap" to "cursor drag"
  - In nav mode `touchesMoved`: compute character offset from horizontal delta / `pointsPerCharacter` (default 8.0), call `adjustTextPosition(byCharacterOffset:)` with the diff since last frame
  - If vertical drag setting enabled: also accumulate vertical delta and call `adjustTextPosition(byCharacterOffset:)` with line-length approximation (or use `selectionWillChange` deltas — start with horizontal-only and add vertical behind the toggle)
  - `touchesEnded`: if nav mode → no character inserted; else insert space (or trigger double-space-period)
  - Guard: `adjustTextPosition` can silently no-op at boundaries — don't accumulate phantom state (PRD AGENT NOTE)

---

## Phase 5 — Clipboard

- [ ] **5.1 `Controllers/ClipboardManager.swift`**
  - Storage: `clipboard.json` in App Group container, array of `ClipboardEntry { id, text, createdAt, pinned }`
  - `capturePasteboardIfChanged()` per PRD §5.3 — only call from explicit entry points, never on `viewDidLoad`
  - `addEntry(_:)`, `delete(_:)`, `togglePin(_:)`, `clearAll()`
  - Auto-expire unpinned entries older than 24h on load
  - Enforce `clipboardMaxEntries` (default 20)

- [ ] **5.2 `Views/ClipboardPanelView.swift`**
  - Overlay view that replaces the keyboard area when opened
  - Vertical list of entries (text preview, pinned indicator)
  - Tap → paste (`insertText`) and dismiss panel
  - Swipe-left → delete with confirmation
  - Long-press → toggle pin
  - "Done" button to return to keyboard

- [ ] **5.3 Wire entry points**
  - Clipboard key on number row (when row enabled)
  - Long-press on `?123` (when number row disabled)
  - First capture: `viewDidAppear` + 1s delay (avoid pasteboard banner)

- [ ] **5.4 Full Access guard**
  - When `!hasFullAccess`: hide clipboard key, show inline banner above keyboard ("Enable Full Access in Settings to use clipboard + haptics")

---

## Phase 6 — Theming & polish

- [ ] **6.1 Theme application**
  - Resolve effective theme from `settings.theme` + `traitCollection.userInterfaceStyle`
  - Apply Gboard palette (PRD §2.7) to backgrounds, keys, labels, accent
  - React to `traitCollectionDidChange` when theme is `.system`

- [ ] **6.2 Typography**
  - SF Pro system font, 22pt for letter labels, 16pt for function-key labels

- [ ] **6.3 Press-state animations**
  - 0.08s ease-out per PRD §10 AGENT DECIDE

- [ ] **6.4 Full Access banner**
  - Subtle one-line strip above the top row when relevant features are gated

---

## Phase 7 — Integration & manual QA

- [ ] **7.1 Build for real iPhone over USB**
  - Apple Developer team ID configured via automatic signing
  - Resolve any provisioning profile errors

- [ ] **7.2 Enable Tactl in Settings → Keyboards → Add New Keyboard**

- [ ] **7.3 Run through PRD §8 checklist**
  - Keyboard appears in keyboard switcher
  - Typing works in Notes, Safari URL bar, Messages, Mail
  - Height slider visibly changes keyboard height on next open
  - Space-drag moves cursor smoothly without inserting a space
  - Tap space inserts space; double-tap space inserts `. `
  - Long-press `e` shows accent popup; drag selects; release commits
  - Number row toggle hides/shows row and reflows
  - Clipboard panel opens with recent items; paste works; pin works
  - Haptics fire per key with Full Access on
  - Dark mode follows system
  - No pasteboard privacy banner during normal typing

- [ ] **7.4 Tune `pointsPerCharacter` based on real-device feel**
  - Start at 8.0, adjust to taste

---

## Phase 8 — Cleanup

- [ ] **8.1 Remove any unused boilerplate** (default `ContentView.swift` placeholder, sample IBOutlets)
- [ ] **8.2 Add `// AGENT NOTE` and `// Known limitation` comments only where PRD calls them out** (PRD §9)
- [ ] **8.3 Commit in logical chunks** (shared layer → settings app → keyboard skeleton → input → cursor drag → clipboard → polish)

---

## Out of scope (v2 — do NOT build)
Swipe typing, Core ML autocorrect, theme editor, multi-language, emoji search, contextual shortcut row, iCloud sync.
