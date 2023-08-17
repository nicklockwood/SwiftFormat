import ComposableArchitecture
import Foundation

struct AppDomain: Reducer {
    struct State: Equatable {
        enum UserState: Equatable {
            case signedIn(SignedInDomain.State)
            case signedOut(SignedOutDomain.State)
        }

        var user: UserState = .signedOut(.init())
        @PresentationState var alert: AlertState<Action.Alert>?
    }

    enum Action: Equatable {
        case openURL(URL)
        case signedIn(SignedInDomain.Action)
        case signedOut(SignedOutDomain.Action)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {}
    }

    @Dependency(\.networking) var networking
    @Dependency(\.keychain) var keychain

    var body: some Reducer<State, Action> {
        // Doubly scoped to grab a particular enum value's case.
        Scope(state: \.user, action: /AppDomain.Action.signedOut) {
            Scope(state: /AppDomain.State.UserState.signedOut,
                  action: /.self)
            {
                SignedOutDomain()
            }
        }

        // Doubly scoped to grab a particular enum value's case.
        Scope(state: \.user, action: /AppDomain.Action.signedIn) {
            Scope(state: /AppDomain.State.UserState.signedIn,
                  action: /.self)
            {
                SignedInDomain()
            }
        }

        // App Reducer
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case let .openURL(url):
                networking.handle(callbackURL: url)

                return .none
            case let .signedOut(.receiveEmployee(employee)):
                state.user = .signedIn(.idle(for: employee))

                return .action(.signedIn(.refreshExpenses))
            case .signedOut:
                // Handled by SignedOutDomain.
                return .none
            case .signedIn(.logOut):
                networking.signOut()
                keychain.removeAll()
                state.user = .signedOut(.init())

                return .none
            case .signedIn:
                // Handled by SignedInDomain.
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert) // Automatically manage alert state.

        // Global Error Reducer
        Reduce { state, action in
            switch action {
            case let .signedOut(.receiveSignIn(.failure(error as any LocalizedError))),
                 let .signedOut(.receiveRawEmployee(_, .failure(error as any LocalizedError))),
                 let .signedIn(.receiveEmployee(.failure(error as any LocalizedError))),
                 let .signedIn(.receiveExpenses(.failure(error as any LocalizedError))):
                state.alert = AppDomain.networkErrorAlert(error)
            case .openURL, .signedIn, .signedOut, .alert:
                // Handled by other reducers.
                break
            }

            return .none
        }
    }
}

extension AppDomain {
    static func networkErrorAlert(_ error: any LocalizedError) -> AlertState<Action.Alert> {
        let title = "An Error Occurred"
        let message = """
        Sorry, that network call failed due to an error, please try again.

        \(error.errorDescription ?? error.localizedDescription)
        """

        return .init(title: .init(title),
                     message: .init(message),
                     buttons: [.default(.init("OK"))])
    }
}
