import UIKit

final class ToolbarView: UIView {
    static let height: CGFloat = 36

    // Closures — view + event passed for handleInputModeList
    var onEmojiTapped: ((UIView, UIEvent) -> Void)?
    var onClipboardTapped: (() -> Void)?
    var onPredictionSelected: ((String) -> Void)?

    private let emojiButton = UIButton(type: .system)
    private let clipboardButton = UIButton(type: .system)
    private var predButtons: [UIButton] = []
    private var currentPredictions: [String] = []
    private var inBackspaceMode = false
    private(set) var theme: KeyboardTheme

    init(theme: KeyboardTheme) {
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        emojiButton.setTitle("🌐", for: .normal)
        emojiButton.titleLabel?.font = .systemFont(ofSize: 18)
        emojiButton.addTarget(self, action: #selector(handleEmoji(_:forEvent:)), for: .touchUpInside)
        addSubview(emojiButton)

        clipboardButton.setTitle("📋", for: .normal)
        clipboardButton.titleLabel?.font = .systemFont(ofSize: 18)
        clipboardButton.addTarget(self, action: #selector(clipboardTapped), for: .touchUpInside)
        addSubview(clipboardButton)

        for _ in 0..<3 {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = .systemFont(ofSize: 15)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.isHidden = true
            btn.addTarget(self, action: #selector(predTapped(_:)), for: .touchUpInside)
            addSubview(btn)
            predButtons.append(btn)
        }

        applyTheme(theme)
    }

    func applyTheme(_ theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = theme.functionKeyBackground
        emojiButton.tintColor = theme.keyText
        clipboardButton.tintColor = theme.keyText
        for btn in predButtons {
            btn.setTitleColor(theme.keyText, for: .normal)
            btn.backgroundColor = theme.keyBackground.withAlphaComponent(0.7)
            btn.layer.cornerRadius = 4
        }
    }

    // MARK: - Predictions

    func updatePredictions(_ words: [String]) {
        currentPredictions = words
        guard !inBackspaceMode else { return }
        for (i, btn) in predButtons.enumerated() {
            if i < words.count {
                btn.setTitle(words[i], for: .normal)
                btn.isHidden = false
            } else {
                btn.isHidden = true
            }
        }
        setNeedsLayout()
    }

    // MARK: - Backspace swipe indicator

    func showBackspaceIndicator(wordCount: Int) {
        inBackspaceMode = true
        let text = wordCount == 0
            ? "← Swipe left to select words"
            : "⌫ \(wordCount) word\(wordCount == 1 ? "" : "s")"
        predButtons[0].setTitle(text, for: .normal)
        predButtons[0].isHidden = false
        predButtons[0].backgroundColor = wordCount > 0
            ? theme.accentColor.withAlphaComponent(0.25)
            : theme.keyBackground.withAlphaComponent(0.7)
        for i in 1..<predButtons.count { predButtons[i].isHidden = true }
        setNeedsLayout()
    }

    func hideBackspaceIndicator() {
        inBackspaceMode = false
        predButtons[0].backgroundColor = theme.keyBackground.withAlphaComponent(0.7)
        updatePredictions(currentPredictions)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let sideW: CGFloat = 44
        let gap: CGFloat = 4
        let predAreaX = sideW + gap
        let predAreaW = bounds.width - 2 * sideW - 2 * gap

        emojiButton.frame = CGRect(x: 0, y: 0, width: sideW, height: bounds.height)
        clipboardButton.frame = CGRect(x: bounds.width - sideW, y: 0, width: sideW, height: bounds.height)

        if inBackspaceMode {
            predButtons[0].frame = CGRect(x: predAreaX, y: 4, width: predAreaW, height: bounds.height - 8)
        } else {
            let visible = predButtons.filter { !$0.isHidden }
            let count = CGFloat(visible.count)
            guard count > 0 else { return }
            let predW = (predAreaW - gap * (count - 1)) / count
            for (i, btn) in visible.enumerated() {
                btn.frame = CGRect(
                    x: predAreaX + CGFloat(i) * (predW + gap),
                    y: 4,
                    width: predW,
                    height: bounds.height - 8
                )
            }
        }
    }

    // MARK: - Actions

    @objc private func handleEmoji(_ sender: UIButton, forEvent event: UIEvent) {
        onEmojiTapped?(sender, event)
    }

    @objc private func clipboardTapped() {
        onClipboardTapped?()
    }

    @objc private func predTapped(_ sender: UIButton) {
        guard !inBackspaceMode, let title = sender.title(for: .normal) else { return }
        onPredictionSelected?(title)
    }
}
