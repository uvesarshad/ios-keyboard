import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, touchesBeganOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesMovedOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesEndedOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardView(_ view: KeyboardView, touchesCancelledOn keyView: KeyView, touches: Set<UITouch>, event: UIEvent?)
    func keyboardViewDidTapEmoji(_ view: KeyboardView, sourceView: UIView, event: UIEvent)
    func keyboardViewDidTapClipboard(_ view: KeyboardView)
    func keyboardView(_ view: KeyboardView, didTapPrediction kind: PredictionKind, word: String)
}

final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?

    private let layoutManager: LayoutManager
    private let settings: TactlSettings
    private(set) var theme: KeyboardTheme

    private var keyViews: [KeyView] = []
    private var cachedRows: [[Key]] = []
    private var fullAccessBanner: UIView?
    private let toolbar: ToolbarView

    private let hPad: CGFloat = 3
    private let vPad: CGFloat = 6
    private let keyGap: CGFloat = 6
    private let rowGap: CGFloat = 8

    init(layoutManager: LayoutManager, settings: TactlSettings, theme: KeyboardTheme) {
        self.layoutManager = layoutManager
        self.settings = settings
        self.theme = theme
        self.toolbar = ToolbarView(theme: theme)
        super.init(frame: .zero)
        setupToolbar()
        rebuild()
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyTheme(_ newTheme: KeyboardTheme) {
        theme = newTheme
        backgroundColor = newTheme.keyboardBackground
        toolbar.applyTheme(newTheme)
        reconfigureKeys()
    }

    /// Full rebuild — call when the set of keys changes (page swap, settings change).
    func refresh() {
        rebuild()
    }

    /// Light update — call when only shift state changes. Reuses existing key views.
    func reconfigureKeys() {
        guard !keyViews.isEmpty else { return }
        var iter = keyViews.makeIterator()
        for row in cachedRows {
            for key in row {
                guard let kv = iter.next() else { continue }
                kv.configure(
                    labelText: layoutManager.labelForKey(key),
                    theme: theme,
                    shiftState: layoutManager.shiftState
                )
            }
        }
    }

    func updatePredictionTriplet(_ triplet: PredictionTriplet) {
        toolbar.updatePredictionTriplet(triplet)
    }

    func showBackspacePreview(deletionText: String) {
        toolbar.showBackspacePreview(deletionText: deletionText)
    }

    func hideBackspacePreview() {
        toolbar.hideBackspacePreview()
    }

    func showFullAccessBanner(_ show: Bool) {
        fullAccessBanner?.removeFromSuperview()
        fullAccessBanner = nil
        guard show else { return }
        let banner = UILabel()
        banner.text = "Enable Full Access in Settings for clipboard history"
        banner.font = .systemFont(ofSize: 10)
        banner.textAlignment = .center
        banner.textColor = theme.keyText.withAlphaComponent(0.6)
        banner.backgroundColor = theme.functionKeyBackground.withAlphaComponent(0.8)
        banner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(banner)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: trailingAnchor),
            banner.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            banner.heightAnchor.constraint(equalToConstant: 18),
        ])
        fullAccessBanner = banner
    }

    // MARK: - Private

    private func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: ToolbarView.height),
        ])
        toolbar.onEmojiTapped = { [weak self] sourceView, event in
            guard let self else { return }
            self.delegate?.keyboardViewDidTapEmoji(self, sourceView: sourceView, event: event)
        }
        toolbar.onClipboardTapped = { [weak self] in
            guard let self else { return }
            self.delegate?.keyboardViewDidTapClipboard(self)
        }
        toolbar.onPredictionTapped = { [weak self] kind, word in
            guard let self else { return }
            self.delegate?.keyboardView(self, didTapPrediction: kind, word: word)
        }
    }

    private func buildRows() -> [[Key]] {
        let showNumberRow = settings.numberRowEnabled && layoutManager.page == .letters
        var rows: [[Key]] = []
        if showNumberRow { rows.append(KeyboardLayout.numberRow) }
        rows += layoutManager.activeRows
        rows.append(layoutManager.activeFunctionRow)
        return rows
    }

    private func rebuild() {
        keyViews.forEach { $0.removeFromSuperview() }
        keyViews.removeAll()
        backgroundColor = theme.keyboardBackground

        cachedRows = buildRows()
        for row in cachedRows {
            for key in row {
                let kv = KeyView(key: key)
                kv.delegate = self
                kv.configure(
                    labelText: layoutManager.labelForKey(key),
                    theme: theme,
                    shiftState: layoutManager.shiftState
                )
                addSubview(kv)
                keyViews.append(kv)
            }
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !keyViews.isEmpty else { return }

        let toolbarH = ToolbarView.height
        let bannerH: CGFloat = fullAccessBanner != nil ? 18 : 0
        let topOffset = toolbarH + bannerH
        let availH = bounds.height - topOffset
        let availW = bounds.width - 2 * hPad

        let numRows = cachedRows.count
        guard numRows > 0 else { return }

        let totalRowH = availH - 2 * vPad - rowGap * CGFloat(numRows - 1)
        let rowH = max(1, totalRowH / CGFloat(numRows))

        var keyViewIter = keyViews.makeIterator()

        for (ri, row) in cachedRows.enumerated() {
            let rowY = topOffset + vPad + CGFloat(ri) * (rowH + rowGap)

            let isLetterRow2 = layoutManager.page == .letters
                && ri == (settings.numberRowEnabled ? 2 : 1)
            let unitW = charUnitWidth(for: row, availW: availW)
            let inset = isLetterRow2 ? unitW / 2 : 0
            let effectiveW = availW - 2 * inset
            let effectiveLeft = hPad + inset

            let totalWeight = row.reduce(0.0) { $0 + $1.widthWeight }
            let gaps = keyGap * CGFloat(max(0, row.count - 1))
            let unit = (effectiveW - gaps) / totalWeight

            var x = effectiveLeft
            for key in row {
                guard let kv = keyViewIter.next() else { continue }
                let w = max(1, unit * key.widthWeight)
                kv.frame = CGRect(x: x, y: rowY, width: w, height: rowH)
                x += w + keyGap
            }
        }
    }

    private func charUnitWidth(for row: [Key], availW: CGFloat) -> CGFloat {
        let totalWeight = row.reduce(0.0) { $0 + $1.widthWeight }
        let gaps = keyGap * CGFloat(max(0, row.count - 1))
        return (availW - gaps) / totalWeight
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
