protocol P1 {}

extension P1 {
    public func f() {}
}

public protocol P2 {
    public func f()
}

public struct S: P1, P2 {}
