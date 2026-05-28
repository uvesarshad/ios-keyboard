import UIKit

protocol InputHandlerDelegate: AnyObject {
    var textDocumentProxy: UITextDocumentProxy { get }
    var hasFullAccess: Bool { get }
    func showClipboardPanel()
    func advanceToNextInputMode(from view: UIView, with event: UIEvent?)
}

final class InputHandler {
    weak var delegate: InputHandlerDelegate?
    var layoutManager: LayoutManager?
    var hapticIntensity: HapticIntensity = .light

    private var lastInputWasSpace = false
    private var backspaceTimer: Timer?

    func handleTap(_ key: Key, sourceView: UIView? = nil, event: UIEvent? = nil) {
        guard let proxy = delegate?.textDocumentProxy else { return }
        fireHaptic()
        UIDevice.current.playInputClick()

        switch key.kind {
        case .character:
            let text = layoutManager?.labelForKey(key) ?? key.label
            proxy.insertText(text)
            lastInputWasSpace = false
            layoutManager?.autoLowerAfterInput()

        case .comma:
            proxy.insertText(",")
            lastInputWasSpace = false
            layoutManager?.autoLowerAfterInput()

        case .period:
            proxy.insertText(".")
            lastInputWasSpace = false
            layoutManager?.autoLowerAfterInput()

        case .space:
            if lastInputWasSpace {
                proxy.deleteBackward()
                proxy.insertText(". ")
                lastInputWasSpace = false
            } else {
                proxy.insertText(" ")
                lastInputWasSpace = true
            }

        case .backspace:
            proxy.deleteBackward()
            lastInputWasSpace = false

        case .return:
            proxy.insertText("\n")
            lastInputWasSpace = false
            layoutManager?.autoLowerAfterInput()

        case .shift:
            layoutManager?.cycleShift()

        case .symbolToggle:
            layoutManager?.page = (layoutManager?.page == .symbols1) ? .letters : .symbols1

        case .symbol2Toggle:
            layoutManager?.page = .symbols2

        case .letterToggle:
            layoutManager?.page = .letters

        case .clipboard:
            delegate?.showClipboardPanel()

        case .nextKeyboard:
            if let sv = sourceView, let ev = event {
                delegate?.advanceToNextInputMode(from: sv, with: ev)
            }
        }
    }

    func handleVariantSelected(_ variant: String) {
        delegate?.textDocumentProxy.insertText(variant)
        lastInputWasSpace = false
        layoutManager?.autoLowerAfterInput()
        fireHaptic()
        UIDevice.current.playInputClick()
    }

    func startBackspaceRepeat() {
        backspaceTimer?.invalidate()
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.delegate?.textDocumentProxy.deleteBackward()
        }
    }

    func stopBackspaceRepeat() {
        backspaceTimer?.invalidate()
        backspaceTimer = nil
    }

    // Haptics do NOT require Full Access on iOS — only pasteboard does.
    private func fireHaptic() {
        guard hapticIntensity != .off else { return }
        HapticEngine.shared.fire(intensity: hapticIntensity)
    }
}
