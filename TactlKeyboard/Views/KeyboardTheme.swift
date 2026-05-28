import UIKit

struct KeyboardTheme {
    let keyboardBackground: UIColor
    let keyBackground: UIColor
    let functionKeyBackground: UIColor
    let spaceKeyBackground: UIColor
    let keyText: UIColor
    let functionKeyText: UIColor
    let accentColor: UIColor

    // Gboard light
    static let light = KeyboardTheme(
        keyboardBackground: UIColor(red: 0.820, green: 0.831, blue: 0.859, alpha: 1),
        keyBackground: .white,
        functionKeyBackground: UIColor(red: 0.671, green: 0.690, blue: 0.722, alpha: 1),
        spaceKeyBackground: .white,
        keyText: .black,
        functionKeyText: .black,
        accentColor: UIColor(red: 0.102, green: 0.451, blue: 0.914, alpha: 1)
    )

    // Gboard dark
    static let dark = KeyboardTheme(
        keyboardBackground: UIColor(red: 0.125, green: 0.129, blue: 0.137, alpha: 1),
        keyBackground: UIColor(red: 0.235, green: 0.251, blue: 0.263, alpha: 1),
        functionKeyBackground: UIColor(red: 0.157, green: 0.165, blue: 0.173, alpha: 1),
        spaceKeyBackground: UIColor(red: 0.235, green: 0.251, blue: 0.263, alpha: 1),
        keyText: .white,
        functionKeyText: .white,
        accentColor: UIColor(red: 0.102, green: 0.451, blue: 0.914, alpha: 1)
    )

    func backgroundColor(for key: Key, shiftState: ShiftState = .off) -> UIColor {
        switch key.kind {
        case .character, .comma, .period, .nextKeyboard:
            return keyBackground
        case .space:
            return spaceKeyBackground
        case .shift:
            return shiftState == .caps ? accentColor : functionKeyBackground
        default:
            return functionKeyBackground
        }
    }

    func textColor(for key: Key) -> UIColor {
        switch key.kind {
        case .character, .comma, .period, .space:
            return keyText
        default:
            return functionKeyText
        }
    }

    func font(for key: Key) -> UIFont {
        switch key.kind {
        case .character, .comma, .period:
            return .systemFont(ofSize: 22, weight: .regular)
        case .space:
            return .systemFont(ofSize: 14, weight: .regular)
        default:
            return .systemFont(ofSize: 15, weight: .regular)
        }
    }
}
