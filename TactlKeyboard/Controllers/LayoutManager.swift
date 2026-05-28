import Foundation

enum Page { case letters, symbols1, symbols2 }
enum ShiftState { case off, on, caps }

final class LayoutManager {
    var page: Page = .letters { didSet { onLayoutChange?() } }
    var shiftState: ShiftState = .off { didSet { onShiftChange?() } }

    // Heavy: needs full rebuild (page change swaps key set)
    var onLayoutChange: (() -> Void)?
    // Light: same keys, just re-render labels/colors
    var onShiftChange: (() -> Void)?

    var activeRows: [[Key]] {
        switch page {
        case .letters: KeyboardLayout.letterRows
        case .symbols1: KeyboardLayout.symbols1Rows
        case .symbols2: KeyboardLayout.symbols2Rows
        }
    }

    var activeFunctionRow: [Key] {
        switch page {
        case .letters: KeyboardLayout.functionRow
        case .symbols1: KeyboardLayout.symbols1FunctionRow
        case .symbols2: KeyboardLayout.symbols2FunctionRow
        }
    }

    func cycleShift() {
        switch shiftState {
        case .off: shiftState = .on
        case .on:  shiftState = .caps
        case .caps: shiftState = .off
        }
    }

    func autoLowerAfterInput() {
        if shiftState == .on { shiftState = .off }
    }

    func labelForKey(_ key: Key) -> String {
        switch key.kind {
        case .character, .comma, .period:
            return shiftState != .off ? key.shiftedLabel : key.label
        default:
            return key.label
        }
    }
}
