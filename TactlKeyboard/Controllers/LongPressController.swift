import UIKit

protocol LongPressControllerDelegate: AnyObject {
    func longPressController(
        _ controller: LongPressController,
        showPopupFor key: Key,
        sourceView: UIView
    )
    func longPressControllerDismissPopup(_ controller: LongPressController)
    func longPressController(_ controller: LongPressController, didSelectVariant variant: String)
    func longPressControllerOpenSettings(_ controller: LongPressController)
}

final class LongPressController {
    var longPressDuration: TimeInterval = 0.3
    weak var delegate: LongPressControllerDelegate?

    private var timer: Timer?
    private var pendingKey: Key?
    private var pendingSourceView: UIView?
    private(set) var isShowingPopup = false

    func touchesBegan(key: Key, sourceView: UIView) {
        cancel()
        pendingKey = key
        pendingSourceView = sourceView
        timer = Timer.scheduledTimer(withTimeInterval: longPressDuration, repeats: false) { [weak self] _ in
            self?.timerFired()
        }
    }

    func updatePopupHighlight(screenPoint: CGPoint) {
        // Popup view handles its own highlight tracking via this point
        guard isShowingPopup else { return }
        NotificationCenter.default.post(
            name: .longPressHighlightMoved,
            object: nil,
            userInfo: ["point": screenPoint]
        )
    }

    func touchesEnded() {
        timer?.invalidate()
        timer = nil
        if isShowingPopup {
            delegate?.longPressControllerDismissPopup(self)
            isShowingPopup = false
        }
        pendingKey = nil
        pendingSourceView = nil
    }

    func touchesCancelled() {
        cancel()
    }

    private func cancel() {
        timer?.invalidate()
        timer = nil
        if isShowingPopup {
            delegate?.longPressControllerDismissPopup(self)
            isShowingPopup = false
        }
        pendingKey = nil
        pendingSourceView = nil
    }

    private func timerFired() {
        guard let key = pendingKey, let sourceView = pendingSourceView else { return }
        if key.kind == .comma {
            delegate?.longPressControllerOpenSettings(self)
            return
        }
        guard !key.variants.isEmpty else { return }
        isShowingPopup = true
        delegate?.longPressController(self, showPopupFor: key, sourceView: sourceView)
    }
}

extension Notification.Name {
    static let longPressHighlightMoved = Notification.Name("tactl.longPressHighlightMoved")
    static let longPressVariantSelected = Notification.Name("tactl.longPressVariantSelected")
}
