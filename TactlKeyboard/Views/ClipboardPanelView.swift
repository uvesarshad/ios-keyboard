import UIKit

protocol ClipboardPanelDelegate: AnyObject {
    func clipboardPanel(_ panel: ClipboardPanelView, didSelectEntry entry: ClipboardEntry)
    func clipboardPanelDidDismiss(_ panel: ClipboardPanelView)
    func clipboardPanel(_ panel: ClipboardPanelView, didDeleteEntry entry: ClipboardEntry)
    func clipboardPanel(_ panel: ClipboardPanelView, didTogglePinEntry entry: ClipboardEntry)
}

final class ClipboardPanelView: UIView {
    weak var delegate: ClipboardPanelDelegate?
    private var entries: [ClipboardEntry]
    private let theme: KeyboardTheme
    private var tableView: UITableView!
    private var doneButton: UIButton!

    init(entries: [ClipboardEntry], theme: KeyboardTheme) {
        self.entries = entries
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = theme.keyboardBackground

        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorColor = theme.functionKeyBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ClipboardCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)

        doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.tintColor = theme.accentColor
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        addSubview(doneButton)

        NSLayoutConstraint.activate([
            doneButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            doneButton.heightAnchor.constraint(equalToConstant: 28),
            tableView.topAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        if entries.isEmpty {
            let empty = UILabel()
            empty.text = "No clipboard history"
            empty.textAlignment = .center
            empty.textColor = theme.keyText.withAlphaComponent(0.4)
            empty.font = .systemFont(ofSize: 14)
            tableView.backgroundView = empty
        }
    }

    @objc private func doneTapped() {
        delegate?.clipboardPanelDidDismiss(self)
    }
}

extension ClipboardPanelView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ClipboardCell
        cell.configure(entry: entries[indexPath.row], theme: theme)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.clipboardPanel(self, didSelectEntry: entries[indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let entry = entries[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.delegate?.clipboardPanel(self, didDeleteEntry: entry)
            self.entries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let entry = entries[indexPath.row]
        let title = entry.pinned ? "Unpin" : "Pin"
        let pin = UIContextualAction(style: .normal, title: title) { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.delegate?.clipboardPanel(self, didTogglePinEntry: entry)
            self.entries[indexPath.row].pinned.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            done(true)
        }
        pin.backgroundColor = theme.accentColor
        return UISwipeActionsConfiguration(actions: [pin])
    }
}

private final class ClipboardCell: UITableViewCell {
    private let pinIcon = UILabel()
    private let previewLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .gray

        pinIcon.font = .systemFont(ofSize: 12)
        pinIcon.text = "📌"
        pinIcon.translatesAutoresizingMaskIntoConstraints = false

        previewLabel.font = .systemFont(ofSize: 14)
        previewLabel.lineBreakMode = .byTruncatingTail
        previewLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(pinIcon)
        contentView.addSubview(previewLabel)

        NSLayoutConstraint.activate([
            pinIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            pinIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 20),
            previewLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 4),
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            previewLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(entry: ClipboardEntry, theme: KeyboardTheme) {
        pinIcon.isHidden = !entry.pinned
        previewLabel.text = entry.text.replacingOccurrences(of: "\n", with: " ")
        previewLabel.textColor = theme.keyText
    }
}
