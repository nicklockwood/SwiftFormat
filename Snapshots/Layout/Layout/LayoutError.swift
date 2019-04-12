//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

private func stringify(_ error: Error) -> String {
    switch error {
    case is SymbolError,
         is LayoutError,
         is FileError,
         is XMLParser.Error,
         is Expression.Error:
        return "\(error)"
    default:
        return error.localizedDescription
    }
}

/// An error relating to a specific symbol/expression
internal struct SymbolError: Error, CustomStringConvertible {
    let symbol: String
    let error: Error
    var fatal = false

    init(_ error: Error, for symbol: String) {
        self.symbol = symbol
        if let error = error as? SymbolError {
            let description = error.description
            if symbol == error.symbol || description.contains(symbol) {
                self.error = error.error
            } else if description.contains(error.symbol) {
                self.error = SymbolError(description, for: error.symbol)
            } else {
                self.error = SymbolError("\(description) for \(error.symbol)", for: error.symbol)
            }
        } else {
            self.error = error
        }
    }

    /// Creates an error for the specified symbol
    init(_ message: String, for symbol: String) {
        self.init(Expression.Error.message(message), for: symbol)
    }

    /// Creates a fatal error for the specified symbol
    init(fatal message: String, for symbol: String) {
        self.init(Expression.Error.message(message), for: symbol)
        fatal = true
    }

    public var description: String {
        var description = stringify(error)
        if !description.contains(symbol) {
            description = "\(description) in \(symbol) expression"
        }
        return description
    }

    /// Associates error thrown by the wrapped closure with the given symbol
    static func wrap<T>(_ closure: () throws -> T, for symbol: String) throws -> T {
        do {
            return try closure()
        } catch {
            throw self.init(error, for: symbol)
        }
    }
}

/// The public interface for all Layout errors
public enum LayoutError: Error, Hashable, CustomStringConvertible {
    case message(String)
    case generic(Error, String?)
    case unknownExpression(Error /* SymbolError */, [String])
    case unknownSymbol(Error /* SymbolError */, [String])
    case multipleMatches([URL], for: String)

    public init?(_ error: Error?) {
        guard let error = error else {
            return nil
        }
        self.init(error)
    }

    public init(_ message: String, in className: String? = nil, in url: URL? = nil) {
        self.init(LayoutError.message(message), in: className, in: url)
    }

    @available(*, deprecated, message: "Use init(_:in:) instead")
    public init(_ message: String, for viewOrControllerClass: AnyClass?) {
        self.init(message, in: viewOrControllerClass.map(nameOfClass))
    }

    public init(_ error: Error, in className: String?, in url: URL?) {
        self = .generic(LayoutError(error, in: className), url?.lastPathComponent)
    }

    public init(_ error: Error, in classNameOrFile: String?) {
        if let cls: AnyClass = classNameOrFile.flatMap(classFromString) {
            self.init(error, for: cls)
        } else {
            self.init(LayoutError.generic(error, classNameOrFile))
        }
    }

    public init(_ error: Error, for viewOrControllerClass: AnyClass? = nil) {
        switch error {
        case LayoutError.multipleMatches:
            // Should never be wrapped or it's hard to treat as special case
            self = error as! LayoutError
        case let LayoutError.generic(_, cls) where cls == viewOrControllerClass.map(nameOfClass):
            self = error as! LayoutError
        case let error as LayoutError where viewOrControllerClass == nil:
            self = error
        default:
            self = .generic(error, viewOrControllerClass.map(nameOfClass))
        }
    }

    public var suggestions: [String] {
        switch self {
        case let .unknownExpression(_, suggestions),
             let .unknownSymbol(_, suggestions):
            return suggestions
        case let .generic(error, _):
            return (error as? LayoutError)?.suggestions ?? []
        default:
            return []
        }
    }

    public var description: String {
        switch self {
        case let .message(message):
            return message
        case let .generic(error, className):
            var description = stringify(error)
            if let className = className {
                if !description.contains(className) {
                    description = "\(description) in \(className)"
                }
            }
            return description
        case let .unknownExpression(error, _),
             let .unknownSymbol(error, _):
            return stringify(error)
        case let .multipleMatches(_, path):
            return "Layout found multiple source files matching \(path)"
        }
    }

    // Returns true if the error can be cleared, or false if the
    // error is fundamental, and requires a code change + reload to fix it
    public var isTransient: Bool {
        switch self {
        case let .generic(error, _),
             let .unknownSymbol(error, _),
             let .unknownExpression(error, _):
            if let error = error as? LayoutError {
                return error.isTransient
            }
            return (error as? SymbolError)?.fatal != true
        case .multipleMatches,
             _ where description.contains("XML"): // TODO: less hacky
            return false
        default:
            return true // TODO: handle expression parsing errors
        }
    }

    public var hashValue: Int {
        return description.hashValue
    }

    public static func == (lhs: LayoutError, rhs: LayoutError) -> Bool {
        return lhs.description == rhs.description
    }

    /// Converts error thrown by the wrapped closure to a LayoutError
    static func wrap<T>(_ closure: () throws -> T) throws -> T {
        return try wrap(closure, in: nil)
    }

    static func wrap<T>(_ closure: () throws -> T, in className: String?, in url: URL? = nil) throws -> T {
        do {
            return try closure()
        } catch {
            throw self.init(error, in: className, in: url)
        }
    }
}
