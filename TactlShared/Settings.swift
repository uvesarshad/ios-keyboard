import Foundation
import Combine

enum HapticIntensity: String, Codable, CaseIterable {
    case off, light, medium, heavy

    var displayName: String {
        switch self {
        case .off: "Off"
        case .light: "Light"
        case .medium: "Medium"
        case .heavy: "Heavy"
        }
    }
}

enum ThemeMode: String, Codable, CaseIterable {
    case system, light, dark

    var displayName: String {
        switch self {
        case .system: "Auto"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

struct TactlSettings: Codable, Equatable {
    var keyboardHeight: CGFloat = 280
    var longPressDuration: TimeInterval = 0.3
    var spaceCursorEnabled: Bool = true
    var spaceCursorVerticalEnabled: Bool = false
    var numberRowEnabled: Bool = true
    var clipboardEnabled: Bool = true
    var clipboardMaxEntries: Int = 20
    var hapticIntensity: HapticIntensity = .light
    var soundEnabled: Bool = true
    var theme: ThemeMode = .system
    var keyPopupEnabled: Bool = true
    var onboardingDismissed: Bool = false

    enum CodingKeys: String, CodingKey {
        case keyboardHeight, longPressDuration, spaceCursorEnabled,
             spaceCursorVerticalEnabled, numberRowEnabled, clipboardEnabled,
             clipboardMaxEntries, hapticIntensity, soundEnabled, theme,
             keyPopupEnabled, onboardingDismissed
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        keyboardHeight = try c.decodeIfPresent(CGFloat.self, forKey: .keyboardHeight) ?? 280
        longPressDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .longPressDuration) ?? 0.3
        spaceCursorEnabled = try c.decodeIfPresent(Bool.self, forKey: .spaceCursorEnabled) ?? true
        spaceCursorVerticalEnabled = try c.decodeIfPresent(Bool.self, forKey: .spaceCursorVerticalEnabled) ?? false
        numberRowEnabled = try c.decodeIfPresent(Bool.self, forKey: .numberRowEnabled) ?? true
        clipboardEnabled = try c.decodeIfPresent(Bool.self, forKey: .clipboardEnabled) ?? true
        clipboardMaxEntries = try c.decodeIfPresent(Int.self, forKey: .clipboardMaxEntries) ?? 20
        hapticIntensity = try c.decodeIfPresent(HapticIntensity.self, forKey: .hapticIntensity) ?? .light
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        theme = try c.decodeIfPresent(ThemeMode.self, forKey: .theme) ?? .system
        keyPopupEnabled = try c.decodeIfPresent(Bool.self, forKey: .keyPopupEnabled) ?? true
        onboardingDismissed = try c.decodeIfPresent(Bool.self, forKey: .onboardingDismissed) ?? false
    }
}

// Used by the containing app (SwiftUI)
final class SettingsStore: ObservableObject {
    @Published var current = TactlSettings()
    private static let key = "tactl.settings.v1"

    init() { load() }

    func load() {
        guard let data = AppGroup.defaults.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode(TactlSettings.self, from: data)
        else { return }
        current = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(current) else { return }
        AppGroup.defaults.set(data, forKey: Self.key)
    }

    func clearClipboard() {
        let url = AppGroup.containerURL.appendingPathComponent("clipboard.json")
        try? FileManager.default.removeItem(at: url)
    }
}

// Used by the keyboard extension (snapshot read on each viewWillAppear)
enum Settings {
    static func load() -> TactlSettings {
        guard let data = AppGroup.defaults.data(forKey: "tactl.settings.v1"),
              let decoded = try? JSONDecoder().decode(TactlSettings.self, from: data)
        else { return TactlSettings() }
        return decoded
    }
}
