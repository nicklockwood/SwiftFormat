// swiftformat:options --swiftversion 5.7

struct Foo<Value> {
    func bar<V, R>(
        _ value: V,
        _ work: () -> R
    ) -> R
        where Value == @Sendable () -> V,
        V: Sendable
    {
        work()
    }
}
