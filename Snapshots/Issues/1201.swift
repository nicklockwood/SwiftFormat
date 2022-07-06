// MARK: - Actions

public enum Actions: Hashable, Decodable {
    case redirect(URL?)
    case refresh
    case back

    // MARK: Public

    public var redirectURL: URL? {
        let path = /Self.redirect
        return path.extract(from: self)?.flatMap { $0 }
    }
}

public extension Core_Action_ComposedAction {
    var uiAction: Actions {
        switch component {
        case let .actionRedirect(redirect):
            return Actions.redirect(URL(string: redirect.link.value))
        case .actionBack:
            return .back
        default:
            return .refresh
        }
    }
}
