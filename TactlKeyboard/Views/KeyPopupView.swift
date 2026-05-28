import UIKit

final class KeyPopupView: UIView {
    private let variants: [String]
    private var variantLabels: [UILabel] = []
    private var selectedIndex: Int = -1
    private let theme: KeyboardTheme
    var onVariantSelected: ((String) -> Void)?

    private let hPad: CGFloat = 8
    private let itemWidth: CGFloat = 44
    private let itemHeight: CGFloat = 48

    init(variants: [String], theme: KeyboardTheme) {
        self.variants = variants
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = theme.keyBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4

        for (i, variant) in variants.enumerated() {
            let lbl = UILabel()
            lbl.text = variant
            lbl.textAlignment = .center
            lbl.font = .systemFont(ofSize: 22, weight: .regular)
            lbl.textColor = theme.keyText
            lbl.tag = i
            addSubview(lbl)
            variantLabels.append(lbl)
        }

        let w = CGFloat(variants.count) * itemWidth + 2 * hPad
        frame.size = CGSize(width: w, height: itemHeight)

        for (i, lbl) in variantLabels.enumerated() {
            lbl.frame = CGRect(x: hPad + CGFloat(i) * itemWidth, y: 0, width: itemWidth, height: itemHeight)
        }
    }

    func updateHighlight(screenPoint: CGPoint) {
        let local = convert(screenPoint, from: nil)
        let newIndex: Int
        if local.x < hPad {
            newIndex = 0
        } else if local.x > bounds.width - hPad {
            newIndex = variants.count - 1
        } else {
            newIndex = min(Int((local.x - hPad) / itemWidth), variants.count - 1)
        }

        guard newIndex != selectedIndex else { return }
        selectedIndex = newIndex
        for (i, lbl) in variantLabels.enumerated() {
            lbl.backgroundColor = i == selectedIndex ? theme.accentColor.withAlphaComponent(0.25) : .clear
            lbl.textColor = i == selectedIndex ? theme.accentColor : theme.keyText
        }
    }

    func commitSelection() {
        guard selectedIndex >= 0, selectedIndex < variants.count else { return }
        onVariantSelected?(variants[selectedIndex])
    }

    func positionAbove(sourceView: UIView, in window: UIWindow) {
        let sourceFrame = sourceView.convert(sourceView.bounds, to: window)
        var x = sourceFrame.midX - frame.width / 2
        // Clamp to window bounds
        x = max(4, min(x, window.bounds.width - frame.width - 4))
        let y = sourceFrame.minY - frame.height - 4
        frame.origin = CGPoint(x: x, y: max(4, y))
    }
}
