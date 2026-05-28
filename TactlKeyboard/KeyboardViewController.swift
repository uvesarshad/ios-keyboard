import UIKit

// UIInputView subclass so the system honours UIInputViewAudioFeedback for key clicks.
private final class TactlInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
    init() {
        super.init(frame: .zero, inputViewStyle: .keyboard)
        allowsSelfSizing = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class KeyboardViewController: UIInputViewController {

    // Controllers
    private let layoutManager = LayoutManager()
    private let inputHandler = InputHandler()
    private let cursorDragController = CursorDragController()
    private let longPressController = LongPressController()
    private let clipboardManager = ClipboardManager()

    // State
    private var settings = TactlSettings()
    private var theme: KeyboardTheme = .light
    private var heightConstraint: NSLayoutConstraint?
    private var keyboardView: KeyboardView?
    private var clipboardPanel: ClipboardPanelView?
    private var popupView: KeyPopupView?

    // Backspace swipe state
    private var backspaceSwipeTimer: Timer?
    private var backspaceSwipeActive = false
    private var backspaceSwipeStartX: CGFloat = 0
    private var backspaceSwipeWordCount: Int = 0

    // MARK: - Lifecycle

    override func loadView() {
        view = TactlInputView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = Settings.load()
        applySettings()
        rebuildKeyboard()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.clipboardManager.capturePasteboardIfChanged(hasFullAccess: self.hasFullAccess)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        theme = resolvedTheme()
        keyboardView?.applyTheme(theme)
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        updateToolbarPredictions()
    }

    // MARK: - Setup

    private func applySettings() {
        theme = resolvedTheme()

        heightConstraint?.isActive = false
        let hc = view.heightAnchor.constraint(equalToConstant: settings.keyboardHeight)
        hc.priority = .required
        hc.isActive = true
        heightConstraint = hc

        cursorDragController.longPressDuration = settings.longPressDuration
        cursorDragController.verticalEnabled = settings.spaceCursorVerticalEnabled
        cursorDragController.hasFullAccess = hasFullAccess
        cursorDragController.proxy = textDocumentProxy

        longPressController.longPressDuration = settings.longPressDuration
        longPressController.delegate = self

        inputHandler.layoutManager = layoutManager
        inputHandler.hapticIntensity = settings.hapticIntensity
        inputHandler.delegate = self

        clipboardManager.configure(
            maxEntries: settings.clipboardMaxEntries,
            enabled: settings.clipboardEnabled
        )
        HapticEngine.shared.prepare()
    }

    private func rebuildKeyboard() {
        keyboardView?.removeFromSuperview()
        let kv = KeyboardView(layoutManager: layoutManager, settings: settings, theme: theme)
        kv.delegate = self
        kv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(kv)
        NSLayoutConstraint.activate([
            kv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            kv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            kv.topAnchor.constraint(equalTo: view.topAnchor),
            kv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        keyboardView = kv
        if !hasFullAccess && settings.clipboardEnabled {
            kv.showFullAccessBanner(true)
        }
        layoutManager.onChange = { [weak self] in
            self?.keyboardView?.refresh()
            self?.updateToolbarPredictions()
        }
        updateToolbarPredictions()
    }

    private func resolvedTheme() -> KeyboardTheme {
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
    }

    // MARK: - Predictions

    private func updateToolbarPredictions() {
        guard layoutManager.page == .letters else {
            keyboardView?.updatePredictions([])
            return
        }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let words = computePredictions(for: context)
        keyboardView?.updatePredictions(words)
    }

    private func computePredictions(for context: String) -> [String] {
        let checker = UITextChecker()
        let lang = UITextChecker.availableLanguages.first ?? "en_US"

        // Extract the current partial word being typed
        let trimmed = context
        guard !trimmed.isEmpty else { return [] }

        // Find last word (partial)
        let nsContext = trimmed as NSString
        let lastWordRange = nsContext.range(of: "\\S+$", options: .regularExpression)

        var results: [String] = []

        if lastWordRange.location != NSNotFound {
            let partial = nsContext.substring(with: lastWordRange)
            let partialNS = partial as NSString
            let range = NSRange(location: 0, length: partialNS.length)

            // Completions for partial word
            if let completions = checker.completions(forPartialWordRange: range, in: partial, language: lang) {
                results = Array(completions.prefix(3))
            }

            // If no completions, try guesses (spell correction)
            if results.isEmpty {
                if let guesses = checker.guesses(forWordRange: range, in: partial, language: lang) {
                    results = Array(guesses.prefix(3))
                }
            }
        }

        return results
    }

    // MARK: - Backspace swipe (word deletion)

    private func enterBackspaceSwipeMode(startX: CGFloat) {
        backspaceSwipeActive = true
        backspaceSwipeStartX = startX
        backspaceSwipeWordCount = 0
        keyboardView?.showBackspaceIndicator(wordCount: 0)
        inputHandler.stopBackspaceRepeat()
    }

    private func exitBackspaceSwipeMode(shouldDelete: Bool) {
        guard backspaceSwipeActive else { return }
        backspaceSwipeActive = false
        backspaceSwipeTimer?.invalidate()
        backspaceSwipeTimer = nil

        if shouldDelete && backspaceSwipeWordCount > 0 {
            deleteWords(count: backspaceSwipeWordCount)
        }
        keyboardView?.hideBackspaceIndicator()
    }

    private func updateBackspaceSwipe(currentX: CGFloat) {
        guard backspaceSwipeActive else { return }
        let dx = backspaceSwipeStartX - currentX
        guard dx > 0 else {
            backspaceSwipeWordCount = 0
            keyboardView?.showBackspaceIndicator(wordCount: 0)
            return
        }
        // Each ~30pt of leftward drag = 1 word
        let wordCount = max(0, Int(dx / 30))
        if wordCount != backspaceSwipeWordCount {
            backspaceSwipeWordCount = wordCount
            keyboardView?.showBackspaceIndicator(wordCount: wordCount)
        }
    }

    private func deleteWords(count: Int) {
        guard count > 0 else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }

        // Tokenize into words+whitespace chunks, delete `count` word tokens from the right
        var tokens: [(isWord: Bool, text: String)] = []
        var current = ""
        var inWord = false
        for ch in before {
            let isWordChar = !ch.isWhitespace
            if isWordChar == inWord {
                current.append(ch)
            } else {
                if !current.isEmpty { tokens.append((inWord, current)) }
                current = String(ch)
                inWord = isWordChar
            }
        }
        if !current.isEmpty { tokens.append((inWord, current)) }

        var wordsDeleted = 0
        var charsToDelete = 0
        for token in tokens.reversed() {
            charsToDelete += token.text.count
            if token.isWord {
                wordsDeleted += 1
                if wordsDeleted >= count { break }
            }
        }

        for _ in 0..<charsToDelete {
            textDocumentProxy.deleteBackward()
        }
        HapticEngine.shared.fire(intensity: settings.hapticIntensity)
    }

    // MARK: - Popup

    private func presentPopup(for key: Key, sourceView: UIView) {
        dismissPopup()
        guard let window = view.window else { return }

        let popup = KeyPopupView(variants: key.variants, theme: theme)
        popup.onVariantSelected = { [weak self] variant in
            self?.inputHandler.handleVariantSelected(variant)
        }
        popup.positionAbove(sourceView: sourceView, in: window)
        window.addSubview(popup)
        popupView = popup
    }

    private func dismissPopup() {
        popupView?.commitSelection()
        popupView?.removeFromSuperview()
        popupView = nil
    }

    // MARK: - Clipboard panel

    private func presentClipboardPanel() {
        guard clipboardPanel == nil else { return }
        clipboardManager.capturePasteboardIfChanged(hasFullAccess: hasFullAccess)

        let panel = ClipboardPanelView(entries: clipboardManager.entries, theme: theme)
        panel.delegate = self
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.topAnchor.constraint(equalTo: view.topAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        clipboardPanel = panel
    }

    private func dismissClipboardPanel() {
        clipboardPanel?.removeFromSuperview()
        clipboardPanel = nil
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(
        _ view: KeyboardView,
        touchesBeganOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        guard let touch = touches.first else { return }

        switch keyView.key.kind {
        case .space where settings.spaceCursorEnabled:
            cursorDragController.touchesBegan(at: touch.location(in: self.view))

        case .backspace:
            inputHandler.handleTap(keyView.key)
            inputHandler.startBackspaceRepeat()
            // Start timer to enter swipe mode after longPressDuration
            let startX = touch.location(in: self.view).x
            backspaceSwipeTimer = Timer.scheduledTimer(
                withTimeInterval: settings.longPressDuration,
                repeats: false
            ) { [weak self] _ in
                self?.enterBackspaceSwipeMode(startX: startX)
            }

        case .nextKeyboard:
            break

        default:
            longPressController.touchesBegan(key: keyView.key, sourceView: keyView)
        }
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesMovedOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self.view)

        if keyView.key.kind == .backspace {
            if backspaceSwipeActive {
                updateBackspaceSwipe(currentX: loc.x)
            }
        } else if keyView.key.kind == .space && settings.spaceCursorEnabled {
            cursorDragController.touchesMoved(to: loc)
        } else if longPressController.isShowingPopup {
            popupView?.updateHighlight(screenPoint: touch.location(in: nil))
        }
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesEndedOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        switch keyView.key.kind {
        case .space where settings.spaceCursorEnabled:
            if cursorDragController.touchesEnded() {
                inputHandler.handleTap(keyView.key)
            }

        case .backspace:
            backspaceSwipeTimer?.invalidate()
            backspaceSwipeTimer = nil
            if backspaceSwipeActive {
                exitBackspaceSwipeMode(shouldDelete: true)
            } else {
                inputHandler.stopBackspaceRepeat()
            }

        case .nextKeyboard:
            handleInputModeList(from: keyView, with: event ?? UIEvent())

        default:
            if longPressController.isShowingPopup {
                dismissPopup()
                longPressController.touchesEnded()
            } else {
                longPressController.touchesEnded()
                inputHandler.handleTap(keyView.key, sourceView: keyView, event: event)
            }
        }
        updateToolbarPredictions()
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesCancelledOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        backspaceSwipeTimer?.invalidate()
        backspaceSwipeTimer = nil
        if backspaceSwipeActive {
            exitBackspaceSwipeMode(shouldDelete: false)
        }
        inputHandler.stopBackspaceRepeat()
        cursorDragController.touchesCancelled()
        longPressController.touchesCancelled()
        dismissPopup()
    }

    func keyboardViewDidTapEmoji(_ view: KeyboardView, sourceView: UIView, event: UIEvent) {
        handleInputModeList(from: sourceView, with: event)
    }

    func keyboardViewDidTapClipboard(_ view: KeyboardView) {
        presentClipboardPanel()
    }

    func keyboardView(_ view: KeyboardView, didSelectPrediction word: String) {
        // Replace the partial word before the cursor with the selected prediction
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let nsStr = before as NSString
        let lastWordRange = nsStr.range(of: "\\S+$", options: .regularExpression)
        if lastWordRange.location != NSNotFound {
            let partialWord = nsStr.substring(with: lastWordRange)
            for _ in 0..<partialWord.count {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.insertText(word + " ")
        layoutManager.autoLowerAfterInput()
        HapticEngine.shared.fire(intensity: settings.hapticIntensity)
        UIDevice.current.playInputClick()
        updateToolbarPredictions()
    }
}

// MARK: - LongPressControllerDelegate

extension KeyboardViewController: LongPressControllerDelegate {
    func longPressController(_ controller: LongPressController, showPopupFor key: Key, sourceView: UIView) {
        presentPopup(for: key, sourceView: sourceView)
    }

    func longPressControllerDismissPopup(_ controller: LongPressController) {
        dismissPopup()
    }

    func longPressController(_ controller: LongPressController, didSelectVariant variant: String) {
        inputHandler.handleVariantSelected(variant)
    }

    func longPressControllerOpenSettings(_ controller: LongPressController) {
        if let url = URL(string: "tactl://settings") {
            extensionContext?.open(url, completionHandler: nil)
        }
    }
}

// MARK: - InputHandlerDelegate

extension KeyboardViewController: InputHandlerDelegate {
    func showClipboardPanel() {
        presentClipboardPanel()
    }

    func advanceToNextInputMode(from view: UIView, with event: UIEvent?) {
        handleInputModeList(from: view, with: event ?? UIEvent())
    }
}

// MARK: - ClipboardPanelDelegate

extension KeyboardViewController: ClipboardPanelDelegate {
    func clipboardPanel(_ panel: ClipboardPanelView, didSelectEntry entry: ClipboardEntry) {
        textDocumentProxy.insertText(entry.text)
        dismissClipboardPanel()
    }

    func clipboardPanelDidDismiss(_ panel: ClipboardPanelView) {
        dismissClipboardPanel()
    }

    func clipboardPanel(_ panel: ClipboardPanelView, didDeleteEntry entry: ClipboardEntry) {
        clipboardManager.delete(entry)
    }

    func clipboardPanel(_ panel: ClipboardPanelView, didTogglePinEntry entry: ClipboardEntry) {
        clipboardManager.togglePin(entry)
    }
}
