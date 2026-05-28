import UIKit

final class HapticEngine {
    static let shared = HapticEngine()

    private var generators: [HapticIntensity: UIImpactFeedbackGenerator] = [:]

    private init() {
        let pairs: [(HapticIntensity, UIImpactFeedbackGenerator.FeedbackStyle)] = [
            (.light, .light), (.medium, .medium), (.heavy, .heavy)
        ]
        for (intensity, style) in pairs {
            generators[intensity] = UIImpactFeedbackGenerator(style: style)
        }
    }

    func prepare() {
        generators.values.forEach { $0.prepare() }
    }

    func fire(intensity: HapticIntensity) {
        guard intensity != .off else { return }
        generators[intensity]?.impactOccurred()
    }
}
