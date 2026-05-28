import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, touchesBeganOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesMovedOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesEndedOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesCancelledOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?

    private let layoutManager: LayoutManager
    private let settings: TactlSettings
    private(set) var theme: KeyboardTheme
    private let showGlobe: Bool

    private var keyViews: [KeyView] = []
    private var fullAccessBanner: UIView?

    // Layout constants
    private let hPad: CGFloat = 3
    private let vPad: CGFloat = 6
    private let keyGap: CGFloat = 6
    private let rowGap: CGFloat = 8

    init(layoutManager: LayoutManager, settings: TactlSettings, theme: KeyboardTheme, showGlobe: Bool) {
        self.layoutManager = layoutManager
        self.settings = settings
        self.theme = theme
        self.showGlobe = showGlobe
        super.init(frame: .zero)
        layoutManager.showGlobe = showGlobe
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyTheme(_ newTheme: KeyboardTheme) {
        theme = newTheme
        backgroundColor = newTheme.keyboardBackground
        refresh()
    }

    func refresh() {
        rebuild()
    }

    func showFullAccessBanner(_ show: Bool) {
        fullAccessBanner?.removeFromSuperview()
        fullAccessBanner = nil
        guard show else { return }

        let banner = UILabel()
        banner.text = "Enable Full Access in Settings for clipboard & haptics"
        banner.font = .systemFont(ofSize: 10)
        banner.textAlignment = .center
        banner.textColor = theme.keyText.withAlphaComponent(0.6)
        banner.backgroundColor = theme.functionKeyBackground.withAlphaComponent(0.7)
        banner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: trailingAnchor),
            banner.topAnchor.constraint(equalTo: topAnchor),
            banner.heightAnchor.constraint(equalToConstant: 18),
        ])
        fullAccessBanner = banner
    }

    // MARK: - Private

    private func rebuild() {
        keyViews.forEach { $0.removeFromSuperview() }
        keyViews.removeAll()
        backgroundColor = theme.keyboardBackground

        let allRows = buildRows()
        for row in allRows {
            for key in row {
                let kv = KeyView(key: key)
                kv.delegate = self
                addSubview(kv)
                keyViews.append(kv)
            }
        }
        setNeedsLayout()
    }

    private func buildRows() -> [[Key]] {
        let showNumberRow = settings.numberRowEnabled && layoutManager.page == .letters
        var rows: [[Key]] = []
        if showNumberRow { rows.append(KeyboardLayout.numberRow) }
        rows += layoutManager.activeRows
        rows.append(layoutManager.activeFunctionRow)
        return rows
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bannerHeight: CGFloat = fullAccessBanner != nil ? 18 : 0
        let availH = bounds.height - bannerHeight
        let availW = bounds.width - 2 * hPad

        let allRows = buildRows()
        let numRows = allRows.count
        guard numRows > 0 else { return }

        let totalRowGaps = rowGap * CGFloat(numRows - 1)
        let totalRowH = availH - 2 * vPad - totalRowGaps
        let rowH = max(1, totalRowH / CGFloat(numRows))

        var keyViewIter = keyViews.makeIterator()

        for (ri, row) in allRows.enumerated() {
            let rowY = bannerHeight + vPad + CGFloat(ri) * (rowH + rowGap)
            let isLetterRow2 = ri == (settings.numberRowEnabled && layoutManager.page == .letters ? 2 : 1)
                               && layoutManager.page == .letters

            // For row 2 (ASDF…) apply a small centering inset
            let charWidth = unitWidth(for: row, availWidth: availW)
            let inset = isLetterRow2 ? charWidth / 2 : 0
            let effectiveW = availW - 2 * inset
            let effectiveLeft = hPad + inset

            let totalWeight = row.reduce(0.0) { $0 + $1.widthWeight }
            let gaps = keyGap * CGFloat(max(0, row.count - 1))
            let unit = (effectiveW - gaps) / totalWeight

            var x = effectiveLeft
            for key in row {
                guard let kv = keyViewIter.next() else { continue }
                let w = unit * key.widthWeight
                kv.frame = CGRect(x: x, y: rowY, width: w, height: rowH)
                kv.configure(
                    labelText: labelText(for: key),
                    theme: theme,
                    shiftState: layoutManager.shiftState
                )
                x += w + keyGap
            }
        }
    }

    private func unitWidth(for row: [Key], availWidth: CGFloat) -> CGFloat {
        // Returns the width of a weight-1.0 key in this row (all character keys are weight 1.0)
        let totalWeight = row.reduce(0.0) { $0 + $1.widthWeight }
        let gaps = keyGap * CGFloat(max(0, row.count - 1))
        return (availWidth - gaps) / totalWeight
    }

    private func labelText(for key: Key) -> String {
        layoutManager.labelForKey(key)
    }
}

// MARK: - KeyViewDelegate

extension KeyboardView: KeyViewDelegate {
    func keyViewTouchesBegan(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?) {
        keyView.setPressed(true)
        delegate?.keyboardView(self, touchesBeganOn: keyView, touches: touches, event: event)
    }

    func keyViewTouchesMoved(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?) {
        delegate?.keyboardView(self, touchesMovedOn: keyView, touches: touches, event: event)
    }

    func keyViewTouchesEnded(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?) {
        keyView.setPressed(false)
        delegate?.keyboardView(self, touchesEndedOn: keyView, touches: touches, event: event)
    }

    func keyViewTouchesCancelled(_ keyView: KeyView, touches: Set<UITouch>, event: UIEvent?) {
        keyView.setPressed(false)
        delegate?.keyboardView(self, touchesCancelledOn: keyView, touches: touches, event: event)
    }
}
