// ProtocolAssociatedTypeEdgeCase.swift
//
// Regression test: when organizeDeclarations sorts a protocol body with
// a custom --type-order that places instanceLifecycle before nestedType,
// the init can end up above the associatedtype declarations.  Some
// versions of the Swift compiler then fail to infer the default
// associated types for conforming types.
//
// The code below compiles as-is.  If organizeDeclarations were to move
// `init?(dependencies:context:)` above the two associatedtype lines,
// the compiler could fail to infer Dependencies == Void and
// Context == Void for LoggingPlugin.

public protocol Plugin {
    associatedtype Dependencies = Void

    associatedtype Context = Void

    init?(dependencies: Dependencies, context: Context)

    func run()
}

public struct LoggingPlugin: Plugin {
    public init?(dependencies: Void, context: Void) {}

    public func run() {}
}
