import UIKit

final class ClipboardManager {
    private(set) var entries: [ClipboardEntry] = []
    private var lastCaptured: String = ""
    private var maxEntries: Int = 20
    var enabled: Bool = true

    private var fileURL: URL {
        AppGroup.containerURL.appendingPathComponent("clipboard.json")
    }

    func configure(maxEntries: Int, enabled: Bool) {
        self.maxEntries = maxEntries
        self.enabled = enabled
        load()
    }

    func capturePasteboardIfChanged(hasFullAccess: Bool) {
        guard enabled, hasFullAccess else { return }
        guard UIPasteboard.general.hasStrings else { return }
        guard let string = UIPasteboard.general.string, !string.isEmpty else { return }
        guard string != lastCaptured else { return }
        lastCaptured = string
        addEntry(string)
    }

    func addEntry(_ text: String) {
        entries.removeAll { $0.text == text && !$0.pinned }
        let entry = ClipboardEntry(text: text)
        entries.insert(entry, at: 0)
        trim()
        save()
    }

    func delete(_ entry: ClipboardEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func togglePin(_ entry: ClipboardEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx].pinned.toggle()
        save()
    }

    func clearAll() {
        entries.removeAll { !$0.pinned }
        save()
    }

    private func trim() {
        let pinned = entries.filter { $0.pinned }
        var unpinned = entries.filter { !$0.pinned }
        unpinned = Array(unpinned.prefix(maxEntries - pinned.count))
        entries = pinned + unpinned
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data)
        else { return }
        let cutoff = Date().addingTimeInterval(-86400)
        entries = decoded.filter { $0.pinned || $0.createdAt > cutoff }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
