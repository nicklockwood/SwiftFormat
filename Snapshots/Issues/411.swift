// swiftformat:disable --unusedPrivateDeclarations
Array([]
    .map {
        ""
    }.something())

final class Thing {
    private let somePublisher =
        Publishers.Factory<OtherThing, Never> { _ in
            // do some stuff here
            AnyCancellable {}
        }
        .share(replay: 1)
        .eraseToAnyPublisher()
}
