import UIKit

struct PredictionTriplet {
    var typed: String?       // the partial word currently typed (or nil)
    var correction: String?  // best spell correction (nil if same as typed)
    var completion: String?  // best completion (nil if same as typed)
}

enum PredictionKind { case typed, correction, completion }

final class ToolbarView: UIView {
    static let height: CGFloat = 36

    var onEmojiTapped: ((UIView, UIEvent) -> Void)?
    var onClipboardTapped: (() -> Void)?
    var onPredictionTapped: ((PredictionKind, String) -> Void)?

    private let emojiButton = UIButton(type: .system)
    private let clipboardButton = UIButton(type: .system)
    private let typedChip = TappableLabel()
    private let correctionChip = TappableLabel()
    private let completionChip = TappableLabel()
    private let backspaceLabel = UILabel()

    private var current = PredictionTriplet()
    private var inBackspaceMode = false
    private(set) var theme: KeyboardTheme

    init(theme: KeyboardTheme) {
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        emojiButton.setImage(UIImage(systemName: "face.smiling", withConfiguration: cfg), for: .normal)
        emojiButton.addTarget(self, action: #selector(handleEmoji(_:forEvent:)), for: .touchUpInside)
        addSubview(emojiButton)

        clipboardButton.setImage(UIImage(systemName: "doc.on.clipboard", withConfiguration: cfg), for: .normal)
        clipboardButton.addTarget(self, action: #selector(clipboardTapped), for: .touchUpInside)
        addSubview(clipboardButton)

        for chip in [typedChip, correctionChip, completionChip] {
            chip.font = .systemFont(ofSize: 15)
            chip.textAlignment = .center
            chip.lineBreakMode = .byTruncatingTail
            chip.backgroundColor = .clear
            chip.isHidden = true
            addSubview(chip)
        }
        typedChip.onTap = { [weak self] in
            guard let self, let w = self.current.typed else { return }
            self.onPredictionTapped?(.typed, w)
        }
        correctionChip.onTap = { [weak self] in
            guard let self, let w = self.current.correction else { return }
            self.onPredictionTapped?(.correction, w)
        }
        completionChip.onTap = { [weak self] in
            guard let self, let w = self.current.completion else { return }
            self.onPredictionTapped?(.completion, w)
        }

        backspaceLabel.font = .systemFont(ofSize: 13)
        backspaceLabel.textAlignment = .left
        backspaceLabel.lineBreakMode = .byTruncatingHead
        backspaceLabel.isHidden = true
        addSubview(backspaceLabel)

        applyTheme(theme)
    }

    func applyTheme(_ theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = theme.functionKeyBackground
        emojiButton.tintColor = theme.keyText
        clipboardButton.tintColor = theme.keyText
        backspaceLabel.textColor = theme.keyText
        // Flat text — colors differentiate roles.
        typedChip.textColor = theme.keyText.withAlphaComponent(0.55)
        correctionChip.textColor = theme.accentColor
        completionChip.textColor = theme.keyText
    }

    // MARK: - Predictions

    func updatePredictionTriplet(_ triplet: PredictionTriplet) {
        current = triplet
        guard !inBackspaceMode else { return }

        if let t = triplet.typed, !t.isEmpty {
            typedChip.text = t
            typedChip.isHidden = false
        } else {
            typedChip.isHidden = true
        }

        if let c = triplet.correction, !c.isEmpty {
            correctionChip.text = c
            correctionChip.isHidden = false
        } else {
            correctionChip.isHidden = true
        }

        if let comp = triplet.completion, !comp.isEmpty {
            completionChip.text = comp
            completionChip.isHidden = false
        } else {
            completionChip.isHidden = true
        }

        backspaceLabel.isHidden = true
        setNeedsLayout()
    }

    // MARK: - Backspace preview

    func showBackspacePreview(deletionText: String) {
        inBackspaceMode = true
        typedChip.isHidden = true
        correctionChip.isHidden = true
        completionChip.isHidden = true
        backspaceLabel.isHidden = false
        if deletionText.isEmpty {
            backspaceLabel.text = "← drag left to select words"
            backspaceLabel.textColor = theme.keyText.withAlphaComponent(0.6)
        } else {
            backspaceLabel.text = "⌫ " + deletionText
            backspaceLabel.textColor = theme.accentColor
        }
        setNeedsLayout()
    }

    func hideBackspacePreview() {
        inBackspaceMode = false
        backspaceLabel.isHidden = true
        updatePredictionTriplet(current)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let sideW: CGFloat = 44
        let gap: CGFloat = 8
        let predAreaX = sideW + gap
        let predAreaW = bounds.width - 2 * sideW - 2 * gap

        emojiButton.frame = CGRect(x: 0, y: 0, width: sideW, height: bounds.height)
        clipboardButton.frame = CGRect(x: bounds.width - sideW, y: 0, width: sideW, height: bounds.height)

        if inBackspaceMode {
            backspaceLabel.frame = CGRect(x: predAreaX + 4, y: 4, width: predAreaW - 8, height: bounds.height - 8)
            return
        }

        let chips = [typedChip, correctionChip, completionChip].filter { !$0.isHidden }
        guard !chips.isEmpty else { return }
        let count = CGFloat(chips.count)
        let chipW = (predAreaW - gap * (count - 1)) / count
        for (i, chip) in chips.enumerated() {
            chip.frame = CGRect(
                x: predAreaX + CGFloat(i) * (chipW + gap),
                y: 0,
                width: chipW,
                height: bounds.height
            )
        }
    }

    // MARK: - Actions

    @objc private func handleEmoji(_ sender: UIButton, forEvent event: UIEvent) {
        onEmojiTapped?(sender, event)
    }

    @objc private func clipboardTapped() {
        onClipboardTapped?()
    }
}

private final class TappableLabel: UILabel {
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handleTap() {
        onTap?()
    }
}
