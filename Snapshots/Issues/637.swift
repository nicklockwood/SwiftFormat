final class TestClass {
    init(
        foo: Foo
    ) where
        Foo: Fooable,
        Foo.Bar: Barable,
        Foo.Something == Something,
        Foo.SomethingElse == SomethingElse
    {
        self.foo = foo
    }
}

final class MyClass: NSObject,
    FooProtocol,
    BarProtocol
{
    func someFunction() {}
}
