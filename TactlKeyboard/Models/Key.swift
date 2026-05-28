import UIKit

struct Key {
    enum Kind: Equatable {
        case character
        case shift
        case backspace
        case `return`
        case space
        case symbolToggle   // ?123
        case symbol2Toggle  // =\<
        case letterToggle   // ABC
        case clipboard
        case nextKeyboard
        case comma
        case period
    }

    let label: String
    let shiftedLabel: String
    let variants: [String]
    let widthWeight: CGFloat
    let kind: Kind

    init(
        label: String,
        shiftedLabel: String? = nil,
        variants: [String] = [],
        widthWeight: CGFloat = 1.0,
        kind: Kind = .character
    ) {
        self.label = label
        self.shiftedLabel = shiftedLabel ?? label.uppercased()
        self.variants = variants
        self.widthWeight = widthWeight
        self.kind = kind
    }
}
