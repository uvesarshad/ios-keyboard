import UIKit

protocol EmojiPanelDelegate: AnyObject {
    func emojiPanel(_ panel: EmojiPanelView, didSelectEmoji emoji: String)
    func emojiPanelDidDismiss(_ panel: EmojiPanelView)
}

// MARK: - Emoji data

private struct EmojiCategory {
    let name: String
    let symbol: String
    let emojis: [String]
}

private let emojiCategories: [EmojiCategory] = [
    EmojiCategory(name: "Smileys", symbol: "face.smiling", emojis: [
        "😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍","🤩",
        "😘","😗","☺️","😚","😙","🥲","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔",
        "🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","🤥","😌","😔","😪","🤤","😴","😷",
        "🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","🤯","🤠","🥳","🥸","😎","🤓","🧐",
        "😕","😟","🙁","☹️","😮","😯","😲","😳","🥺","😦","😧","😨","😰","😥","😢","😭",
        "😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠","🤬","😈","👿","💀","☠️",
        "💩","🤡","👹","👺","👻","👽","👾","🤖","😺","😸","😹","😻","😼","😽","🙀","😿","😾",
    ]),
    EmojiCategory(name: "People", symbol: "person", emojis: [
        "👋","🤚","🖐️","✋","🖖","👌","🤌","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","👇",
        "☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","💪","🦾","🦵",
        "🦶","👁️","👀","🧠","👄","💋","👶","🧒","👦","👧","🧑","👱","👨","🧔","👩","🧓",
        "👴","👵","🙍","🙎","🙅","🙆","💁","🙋","🧏","🙇","🤦","🤷","👩‍💻","👨‍💻","🧑‍🚀",
        "👮","💂","🕵️","👷","👸","🧙","🧚","🧛","🧜","🧝","🧞","🧟","👼","🎅","🤶",
        "🦸","🦹","🫂","👫","👬","👭","💏","💑","👪",
    ]),
    EmojiCategory(name: "Animals", symbol: "pawprint", emojis: [
        "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈",
        "🙉","🙊","🐔","🐧","🐦","🐤","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛",
        "🦋","🐌","🐞","🐜","🦟","🦗","🕷️","🦂","🐢","🐍","🦎","🐙","🦑","🦐","🦀","🐡",
        "🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🦍","🐘","🦛","🦏","🐪","🐫",
        "🦒","🦘","🐃","🐄","🐎","🐖","🐏","🐑","🦙","🐐","🦌","🐕","🐩","🦮","🐈",
        "🐓","🦃","🦚","🦜","🦢","🦩","🕊️","🐇","🦝","🦨","🦡","🦦","🦥","🐁","🐀","🐿️",
        "🦔","🐾","🐉","🐲","🌵","🌲","🌳","🌴","🌱","🌿","☘️","🍀","🍃","🍂","🍁","🍄",
        "🌾","💐","🌷","🌹","🥀","🌺","🌸","🌼","🌻","🌞","🌝","🌛","🌜","🌚","🌕","🌙",
        "⭐","🌟","🌠","🌌","☁️","⛅","🌤️","🌈","⚡","❄️","🌊","💧","🔥","🌪️","🌩️",
    ]),
    EmojiCategory(name: "Food", symbol: "fork.knife", emojis: [
        "🍎","🍊","🍋","🍇","🍓","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦",
        "🥬","🥒","🌶️","🧄","🧅","🥔","🍠","🥐","🥖","🍞","🥨","🧀","🥚","🍳","🥞","🧇",
        "🥓","🥩","🍗","🍖","🌭","🍔","🍟","🍕","🌮","🌯","🥗","🍝","🍜","🍲","🍛","🍣",
        "🍱","🥟","🍤","🍙","🍚","🍘","🍥","🧁","🍰","🎂","🍮","🍭","🍬","🍫","🍿","🍩",
        "🍪","🌰","🥜","🍯","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾","☕","🍵","🧃",
        "🥤","🧋","🍶","🥛","🫖",
    ]),
    EmojiCategory(name: "Activities", symbol: "figure.run", emojis: [
        "⚽","🏀","🏈","⚾","🥎","🏐","🏉","🎾","🥏","🎱","🏓","🏸","🏒","🏑","🥍","🏏",
        "🪃","⛳","🪁","🏹","🎣","🤿","🥊","🥋","🎽","🛹","🛼","🛷","⛸️","🥌","🎿","⛷️",
        "🏂","🪂","🏋️","🤼","🤸","⛹️","🤺","🏊","🚣","🧘","🏄","🚴","🏇","🤾","🏌️","🧗",
        "🤹","🎪","🎭","🎨","🎬","🎤","🎧","🎼","🎹","🥁","🪘","🎷","🎺","🎸","🪕","🎻",
        "🎲","♟️","🎯","🎳","🎮","🎰","🧩","🎁","🎀","🎊","🎉","🎈","🧧","🎆","🎇","🧨",
        "✨","🎑","🎃","🎄","🎋","🎍","🎠","🎡","🎢","🎭","🎪",
    ]),
    EmojiCategory(name: "Travel", symbol: "airplane", emojis: [
        "🚗","🚕","🚙","🚌","🚎","🏎️","🚓","🚑","🚒","🚐","🛻","🚚","🚛","🚜","🏍️","🛵",
        "🚲","🛴","🛹","🛼","⛵","🚤","🛥️","🛳️","⛴️","🚢","✈️","🛩️","🛫","🛬","💺","🚁",
        "🚀","🛸","🚞","🚝","🚄","🚅","🚈","🚂","🚇","🚊","🚉","🌍","🌎","🌏","🗺️","🧭",
        "🏔️","⛰️","🌋","🗻","🏕️","🏖️","🏜️","🏝️","🏟️","🏛️","🏗️","🏘️","🏠","🏡","🏢",
        "🏥","🏦","🏨","🏩","🏪","🏫","🏬","🏭","🗼","🗽","⛪","🕌","⛩️","🕍","⛽","🛣️",
        "🛤️","🚧","⚓","🛟","🚦","🚥","🚨","🗺️","🎠","🎡","🎢","💈","🎪","🏁","🚩","🏳️",
    ]),
    EmojiCategory(name: "Objects", symbol: "lightbulb", emojis: [
        "⌚","📱","💻","⌨️","🖥️","🖱️","💾","💿","📀","📷","📸","📹","🎥","📞","☎️","📺",
        "📻","🧭","⏱️","⏰","🕰️","📡","🔋","🔌","💡","🔦","🕯️","🪔","🧯","💰","💳","🪙",
        "💹","📈","📉","📊","📋","📌","📍","📎","✂️","🔒","🔓","🔑","🗝️","🔨","🪓","⛏️",
        "⚒️","🛠️","🔧","🔩","⚙️","🧲","🪜","🪞","🪟","🛋️","🪑","🚽","🚿","🛁","🧴","🧷",
        "🧹","🧺","🧻","🧼","🪥","🪒","🧽","🛒","💊","💉","🩺","🩹","🔬","🔭","🧬",
        "🧿","🪄","🔮","🪅","🎭","🎨","🖼️","🎪","🎰","🚪","🛏️","📦","📫","📬","📭","📮",
        "📜","📄","📑","🗒️","📓","📔","📒","📕","📗","📘","📙","📚","📖","🔖","🏷️",
    ]),
    EmojiCategory(name: "Symbols", symbol: "heart", emojis: [
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❤️‍🔥","❤️‍🩹","💕","💞","💓","💗",
        "💖","💘","💝","💟","☮️","✝️","☪️","🕉️","✡️","☯️","🛐","♈","♉","♊","♋","♌","♍",
        "♎","♏","♐","♑","♒","♓","⛎","🆔","⚛️","☢️","☣️","📵","🔞","❌","⭕","🛑","⛔",
        "📛","🚫","💯","♻️","✅","❎","⚠️","🔱","⚜️","🔰","💠","ℹ️","🔤","🔡","🔠","🆖",
        "🆗","🆙","🆒","🆕","🆓","0️⃣","1️⃣","2️⃣","3️⃣","4️⃣","5️⃣","6️⃣","7️⃣","8️⃣","9️⃣",
        "🔟","#️⃣","*️⃣","▶️","⏸️","⏹️","⏺️","⏩","⏪","⏫","⏬","◀️","🔼","🔽","➡️","⬅️",
        "⬆️","⬇️","↗️","↘️","↙️","↖️","↕️","↔️","↪️","↩️","⤴️","⤵️","🔃","🔄","🔙","🔚",
        "🔛","🔜","🔝","🔀","🔁","🔂","🔊","🔉","🔈","🔇","📢","📣","🔔","🔕","🎵","🎶",
    ]),
]

// MARK: - EmojiPanelView

final class EmojiPanelView: UIView {
    weak var delegate: EmojiPanelDelegate?

    // All subviews use manual frame layout — no Auto Layout anywhere in this view.
    // This avoids timing issues where UICollectionView renders before constraints resolve.
    private var collectionView: UICollectionView!
    private var categoryBar: UIView!
    private var backButton: UIButton!
    private var categoryButtons: [UIButton] = []
    private var selectedCategory = 0
    private var theme: KeyboardTheme

    private let barHeight: CGFloat = 36
    private let cellSize: CGFloat = 42
    private let cellSpacing: CGFloat = 4

    init(theme: KeyboardTheme) {
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyTheme(_ theme: KeyboardTheme) {
        self.theme = theme
        backgroundColor = theme.keyboardBackground
        categoryBar.backgroundColor = theme.functionKeyBackground
        updateCategoryHighlight()
        collectionView.reloadData()
    }

    // MARK: - Frame layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        categoryBar.frame = CGRect(
            x: 0, y: bounds.height - barHeight,
            width: bounds.width, height: barHeight
        )
        collectionView.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width, height: bounds.height - barHeight
        )

        // Back button fixed on the left, category buttons fill the rest
        let backW: CGFloat = 44
        backButton.frame = CGRect(x: 0, y: 0, width: backW, height: barHeight)
        let remaining = bounds.width - backW
        let btnW = remaining / CGFloat(max(1, categoryButtons.count))
        for (i, btn) in categoryButtons.enumerated() {
            btn.frame = CGRect(x: backW + CGFloat(i) * btnW, y: 0, width: btnW, height: barHeight)
        }

        // Update flow layout item size based on actual width
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let inset: CGFloat = 6
            let available = bounds.width - 2 * inset
            let columns = max(1, Int(available / (cellSize + cellSpacing)))
            let itemW = floor((available - cellSpacing * CGFloat(columns - 1)) / CGFloat(columns))
            let newSize = CGSize(width: itemW, height: cellSize)
            if layout.itemSize != newSize {
                layout.itemSize = newSize
                collectionView.reloadData()
            }
        }
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = theme.keyboardBackground

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        layout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        layout.itemSize = CGSize(width: cellSize, height: cellSize)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "emoji")
        collectionView.showsVerticalScrollIndicator = false
        addSubview(collectionView)

        categoryBar = UIView()
        categoryBar.backgroundColor = theme.functionKeyBackground
        addSubview(categoryBar)

        backButton = UIButton(type: .system)
        let backCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        backButton.setImage(UIImage(systemName: "keyboard.chevron.compact.down", withConfiguration: backCfg), for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        categoryBar.addSubview(backButton)

        for (i, cat) in emojiCategories.enumerated() {
            let btn = UIButton(type: .system)
            let cfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            btn.setImage(UIImage(systemName: cat.symbol, withConfiguration: cfg), for: .normal)
            btn.tag = i
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            categoryBar.addSubview(btn)
            categoryButtons.append(btn)
        }

        updateCategoryHighlight()
    }

    private func updateCategoryHighlight() {
        backButton.tintColor = theme.keyText.withAlphaComponent(0.6)
        for (i, btn) in categoryButtons.enumerated() {
            btn.tintColor = i == selectedCategory
                ? theme.accentColor
                : theme.keyText.withAlphaComponent(0.45)
        }
    }

    @objc private func backTapped() {
        delegate?.emojiPanelDidDismiss(self)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        selectedCategory = sender.tag
        updateCategoryHighlight()
        collectionView.reloadData()
        collectionView.setContentOffset(.zero, animated: false)
    }
}

// MARK: - UICollectionViewDataSource / Delegate

extension EmojiPanelView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojiCategories[selectedCategory].emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emoji", for: indexPath) as! EmojiCell
        cell.emoji = emojiCategories[selectedCategory].emojis[indexPath.item]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojiCategories[selectedCategory].emojis[indexPath.item]
        delegate?.emojiPanel(self, didSelectEmoji: emoji)
    }
}

// MARK: - EmojiCell

private final class EmojiCell: UICollectionViewCell {
    private let label = UILabel()

    var emoji: String = "" {
        didSet { label.text = emoji }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
    }
}
