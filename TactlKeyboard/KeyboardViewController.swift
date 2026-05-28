import UIKit

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
    private var popupWindow: UIWindow?
    private var popupView: KeyPopupView?
    private var activeKeyView: KeyView?

    // MARK: - Lifecycle

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
        let kv = KeyboardView(
            layoutManager: layoutManager,
            settings: settings,
            theme: theme,
            showGlobe: needsInputModeSwitchKey
        )
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
        if !hasFullAccess && (settings.clipboardEnabled || settings.hapticIntensity != .off) {
            kv.showFullAccessBanner(true)
        }
        layoutManager.onChange = { [weak self] in
            self?.keyboardView?.refresh()
        }
    }

    private func resolvedTheme() -> KeyboardTheme {
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
    }

    // MARK: - Popup

    private func presentPopup(for key: Key, sourceView: UIView) {
        dismissPopup()
        guard let windowScene = view.window?.windowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.frame = windowScene.coordinateSpace.bounds
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
        window.windowLevel = .alert + 1

        let popup = KeyPopupView(variants: key.variants, theme: theme)
        popup.onVariantSelected = { [weak self] variant in
            self?.inputHandler.handleVariantSelected(variant)
        }
        popup.positionAbove(sourceView: sourceView, in: window)
        window.addSubview(popup)
        window.makeKeyAndVisible()
        popupWindow = window
        popupView = popup
    }

    private func dismissPopup() {
        popupView?.commitSelection()
        popupWindow?.isHidden = true
        popupWindow = nil
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
        activeKeyView = keyView

        switch keyView.key.kind {
        case .space where settings.spaceCursorEnabled:
            cursorDragController.touchesBegan(at: touch.location(in: self.view))

        case .backspace:
            inputHandler.handleTap(keyView.key)
            inputHandler.startBackspaceRepeat()

        case .nextKeyboard:
            break  // handled in touchesEnded

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

        if keyView.key.kind == .space && settings.spaceCursorEnabled {
            cursorDragController.touchesMoved(to: touch.location(in: self.view))
        } else if longPressController.isShowingPopup {
            let screenPt = touch.location(in: nil)
            popupView?.updateHighlight(screenPoint: screenPt)
        }
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesEndedOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        defer { activeKeyView = nil }

        switch keyView.key.kind {
        case .space where settings.spaceCursorEnabled:
            let wasTap = cursorDragController.touchesEnded()
            if wasTap { inputHandler.handleTap(keyView.key) }

        case .backspace:
            inputHandler.stopBackspaceRepeat()

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
    }

    func keyboardView(
        _ view: KeyboardView,
        touchesCancelledOn keyView: KeyView,
        touches: Set<UITouch>,
        event: UIEvent?
    ) {
        inputHandler.stopBackspaceRepeat()
        cursorDragController.touchesCancelled()
        longPressController.touchesCancelled()
        dismissPopup()
        activeKeyView = nil
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
