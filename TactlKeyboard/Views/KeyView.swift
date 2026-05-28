import UIKit

protocol KeyViewDelegate: AnyObject {
    func keyViewTouchesBegan(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyViewTouchesMoved(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyViewTouchesEnded(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyViewTouchesCancelled(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
}

final class KeyView: UIView {
    let key: Key
    weak var delegate: KeyViewDelegate?

    private let label = UILabel()
    private let altLabel = UILabel()
    private var normalBackground: UIColor = .white
    private var pressedBackground: UIColor = .lightGray

    init(key: Key) {
        self.key = key
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 0
        // shouldRasterize + shadowPath drops the per-frame offscreen pass that
        // shadows normally trigger — important when rendering 30+ keys.
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        layer.masksToBounds = false

        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        altLabel.textAlignment = .right
        altLabel.font = .systemFont(ofSize: 10, weight: .regular)
        altLabel.translatesAutoresizingMaskIntoConstraints = false
        altLabel.isUserInteractionEnabled = false
        addSubview(altLabel)
        NSLayoutConstraint.activate([
            altLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            altLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])
    }

    func configure(labelText: String, theme: KeyboardTheme, shiftState: ShiftState) {
        label.text = labelText
        label.font = theme.font(for: key)
        label.textColor = theme.textColor(for: key)
        normalBackground = theme.backgroundColor(for: key, shiftState: shiftState)
        pressedBackground = normalBackground.withAlphaComponent(0.5)
        backgroundColor = normalBackground

        if let firstVariant = key.variants.first, key.kind == .character || key.kind == .comma || key.kind == .period {
            altLabel.text = firstVariant
            altLabel.textColor = theme.keyText.withAlphaComponent(0.45)
            altLabel.isHidden = false
        } else {
            altLabel.isHidden = true
        }
    }

    func setPressed(_ pressed: Bool) {
        // Instant on press, brief fade on release — keeps typing feel snappy.
        if pressed {
            backgroundColor = pressedBackground
        } else {
            UIView.animate(
                withDuration: 0.05,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut]
            ) {
                self.backgroundColor = self.normalBackground
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Pre-compute shadow path so CoreAnimation doesn't trace the layer alpha mask
        // every frame. Update on every layout so shape stays correct on resize.
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.keyViewTouchesBegan(self, touches: touches, event: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.keyViewTouchesMoved(self, touches: touches, event: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.keyViewTouchesEnded(self, touches: touches, event: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.keyViewTouchesCancelled(self, touches: touches, event: event)
    }
}
