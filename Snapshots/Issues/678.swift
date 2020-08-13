// swiftformat:options --swiftversion 5.2

final class Value<T> {
    private let provider: () -> T

    init(provider: @escaping () -> T) {
        self.provider = provider
    }
}

final class Consumer {
    private(set) lazy var value = Value<String> { [unowned self] in
        self.someProvider()
    }

    private func someProvider() -> String {
        "string"
    }
}
