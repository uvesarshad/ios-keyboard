import UIKit

/// Magnified bubble shown above a key while it is pressed (the iOS "key pop" feel).
/// A single instance is reused for every key press — never created per-touch.
final class KeyPreviewView: UIView {
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4

        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Show the bubble above `keyFrame` (already in `container`'s coordinates).
    func present(text: String, keyFrame: CGRect, theme: KeyboardTheme, in container: UIView) {
        label.text = text
        label.textColor = theme.keyText
        label.font = .systemFont(ofSize: 30, weight: .regular)
        backgroundColor = theme.keyBackground

        let w = max(40, keyFrame.width + 16)
        let h = keyFrame.height + 12
        var x = keyFrame.midX - w / 2
        x = max(2, min(x, container.bounds.width - w - 2))
        let y = max(2, keyFrame.minY - h - 2)

        frame = CGRect(x: x, y: y, width: w, height: h)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath

        if superview !== container { container.addSubview(self) }
        container.bringSubviewToFront(self)
        isHidden = false
    }

    func dismiss() {
        isHidden = true
    }
}
