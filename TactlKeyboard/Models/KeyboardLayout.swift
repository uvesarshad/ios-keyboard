import Foundation

enum KeyboardLayout {

    // MARK: - Letter rows

    static let row1: [Key] = [
        Key(label: "q", variants: []),
        Key(label: "w", variants: []),
        Key(label: "e", variants: ["é", "è", "ê", "ë", "ē"]),
        Key(label: "r", variants: []),
        Key(label: "t", variants: []),
        Key(label: "y", variants: ["ý", "ÿ"]),
        Key(label: "u", variants: ["ú", "ù", "û", "ü", "ū"]),
        Key(label: "i", variants: ["í", "ì", "î", "ï", "ī"]),
        Key(label: "o", variants: ["ó", "ò", "ô", "õ", "ö", "ø", "ō"]),
        Key(label: "p", variants: []),
    ]

    static let row2: [Key] = [
        Key(label: "a", variants: ["à", "á", "â", "ã", "ä", "å", "ā"]),
        Key(label: "s", variants: ["ß", "ś"]),
        Key(label: "d", variants: []),
        Key(label: "f", variants: []),
        Key(label: "g", variants: []),
        Key(label: "h", variants: []),
        Key(label: "j", variants: []),
        Key(label: "k", variants: []),
        Key(label: "l", variants: []),
    ]

    static let row3: [Key] = [
        Key(label: "⇧", shiftedLabel: "⇧", widthWeight: 1.5, kind: .shift),
        Key(label: "z", variants: []),
        Key(label: "x", variants: []),
        Key(label: "c", variants: ["ç", "ć"]),
        Key(label: "v", variants: []),
        Key(label: "b", variants: []),
        Key(label: "n", variants: ["ñ", "ń"]),
        Key(label: "m", variants: []),
        Key(label: "⌫", shiftedLabel: "⌫", widthWeight: 1.5, kind: .backspace),
    ]

    static let letterRows: [[Key]] = [row1, row2, row3]

    // MARK: - Number row (top, optional)

    static let numberRow: [Key] = [
        Key(label: "1", variants: ["!", "¡"]),
        Key(label: "2", variants: ["@", "²"]),
        Key(label: "3", variants: ["#", "³"]),
        Key(label: "4", variants: ["$", "£", "€", "¥"]),
        Key(label: "5", variants: ["%", "‰"]),
        Key(label: "6", variants: ["^"]),
        Key(label: "7", variants: ["&"]),
        Key(label: "8", variants: ["*", "×"]),
        Key(label: "9", variants: ["("]),
        Key(label: "0", variants: [")"]),
    ]

    // MARK: - Function rows
    // Globe (🌐) is always shown — gives access to emoji keyboard and other input methods.

    static let functionRow: [Key] = [
        Key(label: "🌐", shiftedLabel: "🌐", widthWeight: 1.2, kind: .nextKeyboard),
        Key(label: "?123", shiftedLabel: "?123", widthWeight: 1.5, kind: .symbolToggle),
        Key(label: ",", shiftedLabel: ",", variants: ["!", "\"", "'", "#"], kind: .comma),
        Key(label: " ", shiftedLabel: " ", widthWeight: 5.0, kind: .space),
        Key(label: ".", shiftedLabel: ".", variants: ["…", "·", "•"], kind: .period),
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
        Key(label: "🌐", shiftedLabel: "🌐", widthWeight: 1.2, kind: .nextKeyboard),
        Key(label: "ABC", shiftedLabel: "ABC", widthWeight: 1.5, kind: .letterToggle),
        Key(label: ",", kind: .comma),
        Key(label: " ", widthWeight: 5.0, kind: .space),
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
        Key(label: "🌐", shiftedLabel: "🌐", widthWeight: 1.2, kind: .nextKeyboard),
        Key(label: "ABC", shiftedLabel: "ABC", widthWeight: 1.5, kind: .letterToggle),
        Key(label: ",", kind: .comma),
        Key(label: " ", widthWeight: 5.0, kind: .space),
        Key(label: ".", kind: .period),
        Key(label: "return", widthWeight: 2.0, kind: .return),
    ]
}
