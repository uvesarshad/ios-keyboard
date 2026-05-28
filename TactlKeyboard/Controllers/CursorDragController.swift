import UIKit

final class CursorDragController {
    var longPressDuration: TimeInterval = 0.25
    var pointsPerCharacter: CGFloat = 8.0
    var verticalEnabled: Bool = false
    var hasFullAccess: Bool = false
    weak var proxy: UITextDocumentProxy?

    private enum State {
        case idle
        case pending(startX: CGFloat, startY: CGFloat)
        case navigating(startX: CGFloat, startY: CGFloat, lastH: Int, lastV: Int)
    }

    private var state: State = .idle
    private var activationTimer: Timer?

    // Returns true if the touch was a tap (not a drag), caller should insert space.
    @discardableResult
    func touchesBegan(at point: CGPoint) -> Bool {
        state = .pending(startX: point.x, startY: point.y)
        activationTimer = Timer.scheduledTimer(withTimeInterval: longPressDuration, repeats: false) { [weak self] _ in
            self?.activateNavMode()
        }
        return false
    }

    func touchesMoved(to point: CGPoint) {
        guard case let .navigating(startX, startY, lastH, lastV) = state else { return }

        let hDelta = point.x - startX
        let targetH = Int(hDelta / pointsPerCharacter)
        let hDiff = targetH - lastH
        if hDiff != 0 {
            proxy?.adjustTextPosition(byCharacterOffset: hDiff)
        }

        var newV = lastV
        if verticalEnabled {
            let vDelta = point.y - startY
            let targetV = Int(vDelta / 44.0)  // ~44pt per line
            let vDiff = targetV - lastV
            if vDiff != 0 {
                proxy?.adjustTextPosition(byCharacterOffset: vDiff * 30)
                newV = targetV
            }
        }

        state = .navigating(startX: startX, startY: startY, lastH: targetH, lastV: newV)
    }

    // Returns true if this was a tap (space should be inserted), false if it was a drag.
    func touchesEnded() -> Bool {
        activationTimer?.invalidate()
        activationTimer = nil
        defer { state = .idle }
        if case .navigating = state { return false }
        return true
    }

    func touchesCancelled() {
        activationTimer?.invalidate()
        activationTimer = nil
        state = .idle
    }

    private func activateNavMode() {
        guard case let .pending(x, y) = state else { return }
        state = .navigating(startX: x, startY: y, lastH: 0, lastV: 0)
        if hasFullAccess {
            HapticEngine.shared.fire(intensity: .medium)
        }
    }
}
