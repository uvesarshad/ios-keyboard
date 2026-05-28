import UIKit

// UIInputView subclass that:
// 1. Conforms to UIInputViewAudioFeedback so the system plays key clicks.
// 2. Drives its own height through intrinsicContentSize (the documented Apple
//    pattern for allowsSelfSizing = true). Adding an external NSLayoutConstraint
//    on the input view's height creates an Auto Layout conflict that some host
//    apps (WhatsApp, complex layouts) resolve by falling back to the system keyboard.
private final class TactlInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }

    private var heightConstraint: NSLayoutConstraint?

    var keyboardHeight: CGFloat = 280 {
        didSet {
            heightConstraint?.constant = keyboardHeight
        }
    }

    init() {
        super.init(frame: .zero, inputViewStyle: .keyboard)
        allowsSelfSizing = true
        // Own our height via a self-contained constraint.
        // Priority 999 lets the system override in edge cases without constraint conflicts.
        let hc = heightAnchor.constraint(equalToConstant: keyboardHeight)
        hc.priority = UILayoutPriority(999)
        hc.isActive = true
        heightConstraint = hc
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class KeyboardViewController: UIInputViewController {

    private let layoutManager = LayoutManager()
    private let inputHandler = InputHandler()
    private let cursorDragController = CursorDragController()
    private let longPressController = LongPressController()
    private let clipboardManager = ClipboardManager()
    // UITextChecker is heavy — construct lazily so it doesn't run during the iOS
    // extension-launch timeout window.
    private lazy var textChecker = UITextChecker()

    private var settings = TactlSettings()
    private var theme: KeyboardTheme = .light
    private var keyboardView: KeyboardView?
    private var clipboardPanel: ClipboardPanelView?
    private var emojiPanel: EmojiPanelView?
    private var popupView: KeyPopupView?
    private var personalWords: Set<String> = []

    // Backspace state
    private var backspaceSwipeActive = false
    private var backspaceTouchStartX: CGFloat = 0
    private var backspaceTouchedDragThreshold: Bool = false
    private var backspaceWordCount: Int = 0
    private let backspaceDragThreshold: CGFloat = 18
    private let backspacePointsPerWord: CGFloat = 30

    // Prediction debounce
    private var predictionWorkItem: DispatchWorkItem?
    private let predictionQueue = DispatchQueue(label: "tactl.predictions", qos: .userInitiated)

    // MARK: - Lifecycle

    override func loadView() {
        view = TactlInputView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Build the keyboard once on first load. viewWillAppear only applies diffs.
        settings = Settings.load()
        applySettings()
        rebuildKeyboard()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.loadPersonalDictionary()
        }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: KeyboardViewController, _) in
            self.theme = self.resolvedTheme()
            self.keyboardView?.applyTheme(self.theme)
            self.emojiPanel?.applyTheme(self.theme)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let newSettings = Settings.load()
        guard newSettings != settings else { return }
        let needsRebuild = newSettings.numberRowEnabled != settings.numberRowEnabled
        settings = newSettings
        applySettings()
        if needsRebuild {
            rebuildKeyboard()
        } else {
            keyboardView?.reconfigureKeys()
            scheduleToolbarUpdate()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        predictionWorkItem?.cancel()
        predictionWorkItem = nil
        inputHandler.stopBackspaceRepeat()
        cursorDragController.touchesCancelled()
        longPressController.touchesCancelled()
        dismissPopup()
        if backspaceSwipeActive { exitBackspaceWordMode(commit: false) }
    }

    deinit {
        predictionWorkItem?.cancel()
        layoutManager.onLayoutChange = nil
        layoutManager.onShiftChange = nil
    }

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)
        scheduleToolbarUpdate()
    }

    // MARK: - Setup

    private func applySettings() {
        theme = resolvedTheme()

        (view as? TactlInputView)?.keyboardHeight = settings.keyboardHeight

        cursorDragController.longPressDuration = settings.longPressDuration
        cursorDragController.verticalEnabled = settings.spaceCursorVerticalEnabled
        cursorDragController.hasFullAccess = hasFullAccess
        cursorDragController.proxy = textDocumentProxy

        longPressController.longPressDuration = settings.longPressDuration
        longPressController.delegate = self

        inputHandler.layoutManager = layoutManager
        inputHandler.hapticIntensity = settings.hapticIntensity
        inputHandler.soundEnabled = settings.soundEnabled
        inputHandler.delegate = self

        clipboardManager.configure(
            maxEntries: settings.clipboardMaxEntries,
            enabled: settings.clipboardEnabled
        )
        DispatchQueue.global(qos: .utility).async {
            HapticEngine.shared.prepare()
        }
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
        layoutManager.onLayoutChange = { [weak self] in
            self?.keyboardView?.refresh()
            self?.scheduleToolbarUpdate()
        }
        layoutManager.onShiftChange = { [weak self] in
            self?.keyboardView?.reconfigureKeys()
        }
        scheduleToolbarUpdate()
    }

    private func resolvedTheme() -> KeyboardTheme {
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
    }

    // MARK: - Personal dictionary

    private func loadPersonalDictionary() {
        let words = PersonalDictionary.load()
        // UITextChecker.learnWord is class-level and thread-safe.
        for word in words {
            UITextChecker.learnWord(word)
        }
        let lowered = Set(words.map { $0.lowercased() })
        DispatchQueue.main.async { [weak self] in
            self?.personalWords = lowered
        }
    }

    private func learnTypedWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if PersonalDictionary.add(trimmed) {
            personalWords.insert(trimmed.lowercased())
            UITextChecker.learnWord(trimmed)
            inputHandler.fireFeedback()
        }
    }

    // MARK: - Predictions

    private func scheduleToolbarUpdate() {
        predictionWorkItem?.cancel()
        let isLetters = layoutManager.page == .letters
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        if !isLetters {
            keyboardView?.updatePredictionTriplet(PredictionTriplet())
            return
        }
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let triplet = self.computeTriplet(for: context)
            DispatchQueue.main.async {
                self.keyboardView?.updatePredictionTriplet(triplet)
            }
        }
        predictionWorkItem = item
        // Background queue keeps UITextChecker off the main thread.
        predictionQueue.asyncAfter(deadline: .now() + 0.12, execute: item)
    }

    private func computeTriplet(for context: String) -> PredictionTriplet {
        // Cap context: only the last 200 chars are relevant for last-word prediction.
        let capped: String = {
            if context.count <= 200 { return context }
            return String(context.suffix(200))
        }()
        let nsContext = capped as NSString
        let lastWordRange = nsContext.range(of: "\\S+$", options: .regularExpression)
        guard lastWordRange.location != NSNotFound else { return PredictionTriplet() }

        let partial = nsContext.substring(with: lastWordRange)
        let partialNS = partial as NSString
        let range = NSRange(location: 0, length: partialNS.length)
        let lang = "en_US"

        var triplet = PredictionTriplet()
        triplet.typed = partial

        // Spell correction: only if word is misspelled
        let misspelledRange = textChecker.rangeOfMisspelledWord(in: partial, range: range, startingAt: 0, wrap: false, language: lang)
        if misspelledRange.location != NSNotFound {
            if let guesses = textChecker.guesses(forWordRange: range, in: partial, language: lang),
               let first = guesses.first, first.caseInsensitiveCompare(partial) != .orderedSame {
                triplet.correction = first
            }
        }

        // Completion
        if let completions = textChecker.completions(forPartialWordRange: range, in: partial, language: lang) {
            let first = completions.first { $0.caseInsensitiveCompare(partial) != .orderedSame }
            triplet.completion = first
        }

        return triplet
    }

    // MARK: - Backspace dual mode

    private func enterBackspaceWordMode() {
        guard !backspaceSwipeActive else { return }
        backspaceSwipeActive = true
        backspaceWordCount = 0
        inputHandler.stopBackspaceRepeat()
        keyboardView?.showBackspacePreview(deletionText: "")
    }

    private func exitBackspaceWordMode(commit: Bool) {
        guard backspaceSwipeActive else { return }
        backspaceSwipeActive = false
        if commit && backspaceWordCount > 0 {
            deleteWords(count: backspaceWordCount)
        }
        backspaceWordCount = 0
        keyboardView?.hideBackspacePreview()
    }

    private func updateBackspaceWordCount(currentX: CGFloat) {
        let dx = backspaceTouchStartX - currentX
        let count = max(0, Int(dx / backspacePointsPerWord))
        guard count != backspaceWordCount else { return }
        backspaceWordCount = count
        keyboardView?.showBackspacePreview(deletionText: previewText(forWordCount: count))
    }

    private func previewText(forWordCount count: Int) -> String {
        guard count > 0 else { return "" }
        let tokens = tokenize(textDocumentProxy.documentContextBeforeInput ?? "")
        var words: [String] = []
        for token in tokens.reversed() where token.isWord {
            words.insert(token.text, at: 0)
            if words.count >= count { break }
        }
        return words.joined(separator: " ")
    }

    private func deleteWords(count: Int) {
        guard count > 0 else { return }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }
        let tokens = tokenize(before)

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
        inputHandler.fireFeedback()
    }

    private func tokenize(_ text: String) -> [(isWord: Bool, text: String)] {
        var tokens: [(Bool, String)] = []
        var current = ""
        var inWord = false
        for ch in text {
            let isWordChar = !ch.isWhitespace
            if current.isEmpty {
                current = String(ch)
                inWord = isWordChar
            } else if isWordChar == inWord {
                current.append(ch)
            } else {
                tokens.append((inWord, current))
                current = String(ch)
                inWord = isWordChar
            }
        }
        if !current.isEmpty { tokens.append((inWord, current)) }
        return tokens
    }

    // MARK: - Popup

    private func presentPopup(for key: Key, sourceView: UIView) {
        dismissPopup()
        guard let container = keyboardView else { return }
        let popup = KeyPopupView(variants: key.variants, theme: theme)
        popup.onVariantSelected = { [weak self] variant in
            self?.inputHandler.handleVariantSelected(variant)
        }
        popup.positionAbove(sourceView: sourceView, in: container)
        container.addSubview(popup)
        popupView = popup
    }

    private func dismissPopup() {
        popupView?.commitSelection()
        popupView?.removeFromSuperview()
        popupView = nil
    }

    // MARK: - Emoji panel

    private func toggleEmojiPanel() {
        if emojiPanel != nil {
            dismissEmojiPanel()
        } else {
            presentEmojiPanel()
        }
    }

    private func presentEmojiPanel() {
        guard emojiPanel == nil else { return }
        dismissPopup()
        let panel = EmojiPanelView(theme: theme)
        panel.delegate = self
        // Use frame layout so the panel has correct bounds immediately — Auto Layout
        // constraints resolve after the first layout pass, which means UICollectionView
        // calls reloadData before its frame is set and renders no cells.
        panel.frame = view.bounds
        panel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(panel)
        emojiPanel = panel
    }

    private func dismissEmojiPanel() {
        emojiPanel?.removeFromSuperview()
        emojiPanel = nil
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

        // Any key touch (except the emoji toggle itself) dismisses the emoji panel.
        if keyView.key.kind != .emojiSwitch {
            dismissEmojiPanel()
        }

        switch keyView.key.kind {
        case .space where settings.spaceCursorEnabled:
            cursorDragController.touchesBegan(at: touch.location(in: self.view))

        case .backspace:
            inputHandler.handleTap(keyView.key)
            inputHandler.startBackspaceRepeat()
            backspaceTouchStartX = touch.location(in: self.view).x
            backspaceTouchedDragThreshold = false
            backspaceSwipeActive = false

        case .nextKeyboard, .emojiSwitch:
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

        switch keyView.key.kind {
        case .backspace:
            let dx = backspaceTouchStartX - loc.x
            if !backspaceTouchedDragThreshold, dx > backspaceDragThreshold {
                backspaceTouchedDragThreshold = true
                enterBackspaceWordMode()
            }
            if backspaceSwipeActive {
                updateBackspaceWordCount(currentX: loc.x)
            }

        case .space where settings.spaceCursorEnabled:
            cursorDragController.touchesMoved(to: loc)

        default:
            if longPressController.isShowingPopup {
                popupView?.updateHighlight(screenPoint: touch.location(in: nil))
            }
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
            inputHandler.stopBackspaceRepeat()
            if backspaceSwipeActive {
                exitBackspaceWordMode(commit: true)
            }

        case .nextKeyboard:
            handleInputModeList(from: keyView, with: event ?? UIEvent())

        case .emojiSwitch:
            toggleEmojiPanel()

        default:
            let wasConsumed = longPressController.didConsume
            longPressController.touchesEnded()
            if !wasConsumed {
                inputHandler.handleTap(keyView.key, sourceView: keyView, event: event)
            }
        }
        scheduleToolbarUpdate()
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesCancelledOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        inputHandler.stopBackspaceRepeat()
        if backspaceSwipeActive {
            exitBackspaceWordMode(commit: false)
        }
        cursorDragController.touchesCancelled()
        longPressController.touchesCancelled()
        dismissPopup()
    }

    func keyboardViewDidTapEmoji(_ view: KeyboardView, sourceView: UIView, event: UIEvent) {
        toggleEmojiPanel()
    }

    func keyboardViewDidTapClipboard(_ view: KeyboardView) {
        presentClipboardPanel()
    }

    func keyboardView(_ view: KeyboardView, didTapPrediction kind: PredictionKind, word: String) {
        switch kind {
        case .typed:
            learnTypedWord(word)
            scheduleToolbarUpdate()

        case .correction, .completion:
            // Replace the partial word with the chosen word + trailing space
            let before = textDocumentProxy.documentContextBeforeInput ?? ""
            let nsStr = before as NSString
            let lastWordRange = nsStr.range(of: "\\S+$", options: .regularExpression)
            if lastWordRange.location != NSNotFound {
                let partialLen = (nsStr.substring(with: lastWordRange) as NSString).length
                for _ in 0..<partialLen { textDocumentProxy.deleteBackward() }
            }
            textDocumentProxy.insertText(word + " ")
            layoutManager.autoLowerAfterInput()
            inputHandler.fireFeedback()
            scheduleToolbarUpdate()
        }
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

// MARK: - EmojiPanelDelegate

extension KeyboardViewController: EmojiPanelDelegate {
    func emojiPanel(_ panel: EmojiPanelView, didSelectEmoji emoji: String) {
        textDocumentProxy.insertText(emoji)
        inputHandler.fireFeedback()
        // Don't auto-dismiss — user likely wants to insert multiple emoji.
    }

    func emojiPanelDidDismiss(_ panel: EmojiPanelView) {
        dismissEmojiPanel()
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
