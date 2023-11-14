// swiftformat:options --swiftversion 5.9

public enum ButtonState: Equatable {
    case normal
    case pressed // highlighted
    case selected
    case disabled // inactive
    #if os(macOS)
        case hovered
    #endif
}

func foo(buttonState: ButtonState) -> Int {
    let str: String
    let number: Int
    switch buttonState {
    #if os(macOS)
        case .normal,
             .hovered:
            str = "1"
            number = 1
    #else
        case .normal:
            str = "1"
            number = 1
    #endif

    case .pressed:
        str = "1"
        number = 1

    case .selected:
        return -1

    case .disabled:
        return -1
    }

    return 0
}
