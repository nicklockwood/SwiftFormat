// swiftformat:options --swiftversion 5.7

struct Foo<Value> {
    func bar<V, R>(
        _: V,
        _ work: () -> R
    ) -> R
        where Value == @Sendable () -> V,
        V: Sendable
    {
        work()
    }
}
