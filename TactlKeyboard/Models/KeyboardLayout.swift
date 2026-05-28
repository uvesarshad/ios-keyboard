import Foundation

enum KeyboardLayout {

    // MARK: - Letter rows
    // Each character key carries a single alternate (number or symbol) shown in the
    // corner and produced by long-press.

    static let row1: [Key] = [
        Key(label: "q", variants: ["1"]),
        Key(label: "w", variants: ["2"]),
        Key(label: "e", variants: ["3"]),
        Key(label: "r", variants: ["4"]),
        Key(label: "t", variants: ["5"]),
        Key(label: "y", variants: ["6"]),
        Key(label: "u", variants: ["7"]),
        Key(label: "i", variants: ["8"]),
        Key(label: "o", variants: ["9"]),
        Key(label: "p", variants: ["0"]),
    ]

    static let row2: [Key] = [
        Key(label: "a", variants: ["@"]),
        Key(label: "s", variants: ["#"]),
        Key(label: "d", variants: ["$"]),
        Key(label: "f", variants: ["_"]),
        Key(label: "g", variants: ["&"]),
        Key(label: "h", variants: ["-"]),
        Key(label: "j", variants: ["+"]),
        Key(label: "k", variants: ["("]),
        Key(label: "l", variants: [")"]),
    ]

    static let row3: [Key] = [
        Key(label: "⇧", shiftedLabel: "⇧", widthWeight: 1.5, kind: .shift),
        Key(label: "z", variants: ["*"]),
        Key(label: "x", variants: ["\""]),
        Key(label: "c", variants: ["'"]),
        Key(label: "v", variants: [":"]),
        Key(label: "b", variants: [";"]),
        Key(label: "n", variants: ["!"]),
        Key(label: "m", variants: ["?"]),
        Key(label: "⌫", shiftedLabel: "⌫", widthWeight: 1.5, kind: .backspace),
    ]

    static let letterRows: [[Key]] = [row1, row2, row3]

    // MARK: - Number row (top, optional)

    static let numberRow: [Key] = [
        Key(label: "1", variants: ["!"]),
        Key(label: "2", variants: ["@"]),
        Key(label: "3", variants: ["#"]),
        Key(label: "4", variants: ["$"]),
        Key(label: "5", variants: ["%"]),
        Key(label: "6", variants: ["^"]),
        Key(label: "7", variants: ["&"]),
        Key(label: "8", variants: ["*"]),
        Key(label: "9", variants: ["("]),
        Key(label: "0", variants: [")"]),
    ]

    // MARK: - Function row
    // iOS provides its own input-mode switcher dock, so we don't render a globe key.
    // The smiley key calls advanceToNextInputMode() — cycles to the user's Emoji
    // keyboard if they have it enabled in Settings → Keyboards.

    static let functionRow: [Key] = [
        Key(label: "?123", shiftedLabel: "?123", widthWeight: 1.5, kind: .symbolToggle),
        Key(label: ",", shiftedLabel: ",", kind: .comma),
        Key(label: "😀", shiftedLabel: "😀", widthWeight: 1.2, kind: .emojiSwitch),
        Key(label: " ", shiftedLabel: " ", widthWeight: 4.5, kind: .space),
        Key(label: ".", shiftedLabel: ".", kind: .period),
        Key(label: "return", shiftedLabel: "return", widthWeight: 2.0, kind: .return),
    ]

    // MARK: - Symbols1 (?123)

    static let symbols1Row1: [Key] = [
        Key(label: "1"), Key(label: "2"), Key(label: "3"),
        Key(label: "4"), Key(label: "5"), Key(label: "6"),
        Key(label: "7"), Key(label: "8"), Key(label: "9"), Key(label: "0"),
    ]

    static let symbols1Row2: [Key] = [
        Key(label: "!"), Key(label: "@"), Key(label: "#"),
        Key(label: "$"), Key(label: "%"), Key(label: "^"),
        Key(label: "&"), Key(label: "*"), Key(label: "("), Key(label: ")"),
    ]

    static let symbols1Row3: [Key] = [
        Key(label: "=\\<", shiftedLabel: "=\\<", widthWeight: 1.5, kind: .symbol2Toggle),
        Key(label: "-"), Key(label: "+"), Key(label: "="),
        Key(label: "/"), Key(label: ";"), Key(label: "'"), Key(label: "\""),
        Key(label: "⌫", shiftedLabel: "⌫", widthWeight: 1.5, kind: .backspace),
    ]

    static let symbols1Rows: [[Key]] = [symbols1Row1, symbols1Row2, symbols1Row3]

    static let symbols1FunctionRow: [Key] = [
        Key(label: "ABC", shiftedLabel: "ABC", widthWeight: 1.5, kind: .letterToggle),
        Key(label: ",", kind: .comma),
        Key(label: "😀", shiftedLabel: "😀", widthWeight: 1.2, kind: .emojiSwitch),
        Key(label: " ", widthWeight: 4.5, kind: .space),
        Key(label: ".", kind: .period),
        Key(label: "return", widthWeight: 2.0, kind: .return),
    ]

    // MARK: - Symbols2 (=\<)

    static let symbols2Row1: [Key] = [
        Key(label: "~"), Key(label: "`"), Key(label: "|"),
        Key(label: "·"), Key(label: "√"), Key(label: "π"),
        Key(label: "÷"), Key(label: "×"), Key(label: "¶"), Key(label: "∆"),
    ]

    static let symbols2Row2: [Key] = [
        Key(label: "£"), Key(label: "¢"), Key(label: "€"),
        Key(label: "¥"), Key(label: "°"), Key(label: "="),
        Key(label: "{"), Key(label: "}"), Key(label: "\\"),
    ]

    static let symbols2Row3: [Key] = [
        Key(label: "?123", shiftedLabel: "?123", widthWeight: 1.5, kind: .symbolToggle),
        Key(label: "["), Key(label: "]"), Key(label: "<"),
        Key(label: ">"), Key(label: "_"), Key(label: "?"), Key(label: "!"),
        Key(label: "⌫", shiftedLabel: "⌫", widthWeight: 1.5, kind: .backspace),
    ]

    static let symbols2Rows: [[Key]] = [symbols2Row1, symbols2Row2, symbols2Row3]

    static let symbols2FunctionRow: [Key] = [
        Key(label: "ABC", shiftedLabel: "ABC", widthWeight: 1.5, kind: .letterToggle),
        Key(label: ",", kind: .comma),
        Key(label: "😀", shiftedLabel: "😀", widthWeight: 1.2, kind: .emojiSwitch),
        Key(label: " ", widthWeight: 4.5, kind: .space),
        Key(label: ".", kind: .period),
        Key(label: "return", widthWeight: 2.0, kind: .return),
    ]
}
