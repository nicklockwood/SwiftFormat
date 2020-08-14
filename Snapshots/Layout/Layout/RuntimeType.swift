//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

private let objCBoolIsChar = (OBJC_BOOL_IS_BOOL == 0)

private protocol _AnyHashable {
    var base: Any { get }
}

extension AnyHashable: _AnyHashable {}

func clearRuntimeTypeCache() {
    RuntimeType.cache.removeAll()
}

public class RuntimeType: NSObject {
    enum Kind: Equatable, CustomStringConvertible {
        case any(Any.Type)
        case `class`(AnyClass)
        case `struct`(String)
        case pointer(String)
        case `protocol`(Protocol)
        case options(Any.Type, [String: Any])
        case array(RuntimeType)

        public static func == (lhs: Kind, rhs: Kind) -> Bool {
            return lhs.description == rhs.description
        }

        public var description: String {
            switch self {
            case let .any(type),
                 let .options(type, _):
                return "\(type)"
            case let .class(type):
                return "\(type).Type"
            case let .struct(type),
                 let .pointer(type):
                return type
            case let .protocol(proto):
                return "<\(NSStringFromProtocol(proto))>"
            case let .array(type):
                return "Array<\(type)>"
            }
        }
    }

    enum Availability: Equatable {
        case available
        case unavailable(reason: String?)

        public static func == (lhs: Availability, rhs: Availability) -> Bool {
            switch (lhs, rhs) {
            case (.available, .available):
                return true
            case let (.unavailable(lhs), .unavailable(rhs)):
                return lhs == rhs
            case (.available, _),
                 (.unavailable, _):
                return false
            }
        }
    }

    public var swiftType: Any.Type? {
        switch kind {
        case let .any(type):
            return type
        case let .class(cls):
            return Swift.type(of: cls)
        case let .struct(name),
             let .pointer(name):
            // TODO: find a general solution
            switch name {
            case "CGImage":
                return CGImage.self
            case "CGColor":
                return CGColor.self
            case "CGPath":
                return CGPath.self
            default:
                return nil
            }
        case let .protocol(proto):
            // TODO: can we get the specific protocol type?
            return Swift.type(of: proto)
        case let .options(type, _):
            return type
        case let .array(elementType):
            // TODO: find a general solution
            switch elementType.swiftType {
            case is String.Type:
                return [String].self
            default:
                return [Any].self
            }
        }
    }

    public typealias Getter = (_ target: AnyObject, _ key: String) -> Any?
    public typealias Setter = (_ target: AnyObject, _ key: String, _ value: Any) throws -> Void
    internal typealias Caster = (_ value: Any) -> Any?

    let kind: Kind
    private(set) var availability = Availability.available
    private(set) var getter: Getter?
    private(set) var setter: Setter?
    internal var caster: Caster?

    fileprivate static var cache = [String: RuntimeType?]()
    private static let queue = DispatchQueue(label: "com.Layout.RuntimeType")
    private static func _type(named typeName: String) -> RuntimeType? {
        if let type = queue.sync(execute: { cache[typeName] }) {
            return type
        }
        let type: RuntimeType?
        switch typeName {
        case "CGColor",
             "CGImage",
             "CGPath":
            type = RuntimeType(.pointer(typeName))
        case "CGColorRef",
             "CGImageRef",
             "CGPathRef":
            type = RuntimeType(.pointer(String(typeName.dropLast(3))))
        case "NSString":
            type = RuntimeType(.any(String.self))
        case "NSArray":
            type = RuntimeType(.array(.any))
        default:
            if let cls = classFromString(typeName) {
                type = RuntimeType(.any(cls))
            } else if let proto = protocolFromString(typeName) {
                type = RuntimeType(.protocol(proto))
            } else if typeName.hasPrefix("Array<"), typeName.hasSuffix(">") {
                let name = typeName.dropLast()["Array<".endIndex...]
                type = RuntimeType.type(named: String(name)).map { RuntimeType(.array($0)) }
            } else if typeName.hasPrefix("["), typeName.hasSuffix("]") {
                let name = typeName.dropFirst().dropLast()
                // TODO: What about dictionary literals (or arrays of dictionary literals, etc)?
                type = RuntimeType.type(named: String(name)).map { RuntimeType(.array($0)) }
            } else {
                type = nil
            }
        }
        queue.sync { cache[typeName] = type }
        return type
    }

    public static func type(named typeName: String) -> RuntimeType? {
        if let type = _type(named: typeName) {
            return type
        }
        let instanceName = sanitizedTypeName(typeName)
        guard RuntimeType.responds(to: Selector(instanceName)),
            let type = RuntimeType.value(forKey: instanceName) as? RuntimeType
        else {
            return nil // No point updating cache, as it's already nil
        }
        queue.sync { cache[typeName] = type }
        return type
    }

    public static func array(of type: RuntimeType) -> RuntimeType {
        return RuntimeType(.array(type))
    }

    public static func array(of type: Any.Type) -> RuntimeType {
        return .array(of: RuntimeType(type))
    }

    static func unavailable(_ reason: String? = nil) -> RuntimeType? {
        #if arch(i386) || arch(x86_64)
            let type = RuntimeType(String.self)
            type.availability = .unavailable(reason: reason)
            return type
        #else
            return nil
        #endif
    }

    public var isAvailable: Bool {
        switch availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    public var values: [String: Any] {
        switch kind {
        case let .options(_, values):
            return values
        case .any,
             .class,
             .struct,
             .pointer,
             .protocol,
             .array:
            return [:]
        }
    }

    @nonobjc init(_ kind: Kind) {
        self.kind = kind
        switch kind {
        case let .any(type) where type is Selector.Type:
            getter = { target, key in
                let selector = Selector(key)
                let fn = unsafeBitCast(
                    class_getMethodImplementation(Swift.type(of: target), selector),
                    to: (@convention(c) (AnyObject?, Selector) -> Selector?).self
                )
                return fn(target, selector)
            }
            setter = { target, key, value in
                let selector = Selector(
                    "set\(key.capitalized()):"
                )
                let fn = unsafeBitCast(
                    class_getMethodImplementation(Swift.type(of: target), selector),
                    to: (@convention(c) (AnyObject?, Selector, Selector?) -> Void).self
                )
                fn(target, selector, value as? Selector)
            }
        default:
            break
        }
    }

    @nonobjc public convenience init(_ type: Any.Type) {
        if let type = RuntimeType._type(named: "\(type)") {
            self.init(type.kind)
            getter = type.getter
            setter = type.setter
            caster = type.caster
        } else {
            self.init(.any(type))
        }
    }

    @nonobjc public convenience init(_ type: Protocol) {
        self.init(.protocol(type))
    }

    @nonobjc public convenience init(class: AnyClass) {
        self.init(.class(`class`))
    }

    @nonobjc public convenience init<T>(array type: [T].Type) {
        self.init(.array(RuntimeType(type)))
    }

    @available(*, deprecated, message: "Use type(named:) instead")
    @nonobjc public convenience init?(_ typeName: String) {
        guard let type = RuntimeType.type(named: typeName) else {
            return nil
        }
        self.init(type.kind)
    }

    @nonobjc public convenience init?(objCType: String) {
        guard let first = objCType.unicodeScalars.first else {
            assertionFailure("Empty objCType")
            return nil
        }
        let type: Kind
        switch first {
        case "c" where objCBoolIsChar,
             "B":
            type = .any(Bool.self)
        case "c",
             "i",
             "s",
             "l",
             "q":
            type = .any(Int.self)
        case "C",
             "I",
             "S",
             "L",
             "Q":
            type = .any(UInt.self)
        case "f":
            type = .any(Float.self)
        case "d":
            type = .any(Double.self)
        case "*":
            type = .any(UnsafePointer<Int8>.self)
        case "@":
            if objCType.hasPrefix("@\"") {
                let range = "@\"".endIndex ..< objCType.index(before: objCType.endIndex)
                let className: String = String(objCType[range])
                if className.hasPrefix("<") {
                    let range = "<".endIndex ..< className.index(before: className.endIndex)
                    let protocolName: String = String(className[range])
                    if let proto = NSProtocolFromString(protocolName) {
                        type = .protocol(proto)
                    } else {
                        return nil
                    }
                } else if let cls = NSClassFromString(className) {
                    if cls == NSString.self {
                        type = .any(String.self)
                    } else {
                        type = .any(cls)
                    }
                } else {
                    return nil
                }
            } else {
                // Can't infer the object type, so ignore it
                return nil
            }
        case "#":
            // Can't infer the specific subclass, so ignore it
            return nil
        case ":":
            type = .any(Selector.self)
        case "{":
            type = .struct(sanitizedStructName(objCType))
        case "^" where objCType.hasPrefix("^{"),
             "r" where objCType.hasPrefix("r^{"):
            type = .pointer(sanitizedStructName(objCType))
        default:
            // Unsupported type
            return nil
        }
        self.init(type)
    }

    @nonobjc public init<T: RawRepresentable>(_: T.Type, _ values: [String: T]) {
        kind = .options(T.self, values)
        getter = { target, key in
            (target.value(forKey: key) as? T.RawValue).flatMap { T(rawValue: $0) }
        }
        setter = { target, key, value in
            target.setValue((value as? T)?.rawValue, forKey: key)
        }
        let rawType = RuntimeType(T.RawValue.self)
        caster = { value in
            (value as? T) ?? rawType.cast(value).flatMap {
                T(rawValue: $0 as! T.RawValue)
            }
        }
        availability = .available
    }

    @nonobjc public convenience init<T: RawRepresentable>(_ values: [String: T]) {
        self.init(T.self, values)
    }

    @nonobjc public init<T>(_: T.Type, _ values: [String: T]) {
        kind = .options(T.self, values)
        availability = .available
    }

    @nonobjc public convenience init<T>(_ values: [String: T]) {
        self.init(T.self, values)
    }

    @nonobjc public init<T: OptionSet>(_: T.Type, _ values: [String: T]) {
        kind = .options(T.self, values)
        getter = { target, key in
            (target.value(forKey: key) as? T.RawValue).flatMap { T(rawValue: $0) }
        }
        setter = { target, key, value in
            target.setValue((value as? T)?.rawValue, forKey: key)
        }
        let rawType = RuntimeType(T.RawValue.self)
        caster = { value in
            if let values = value as? [T] {
                return values.reduce([]) { (lhs: T, rhs: T) -> T in lhs.union(rhs) }
            }
            return (value as? T) ?? rawType.cast(value).flatMap {
                T(rawValue: $0 as! T.RawValue)
            }
        }
        availability = .available
    }

    @nonobjc public convenience init<T: OptionSet>(_ values: [String: T]) {
        self.init(T.self, values)
    }

    @nonobjc public init(_ values: Set<String>) {
        // TODO: add a new, optimized internal type for this case
        var keysAndValues = [String: String]()
        for string in values {
            keysAndValues[string] = string
        }
        kind = .options(String.self, keysAndValues)
        availability = .available
    }

    public override var description: String {
        switch availability {
        case .available:
            return kind.description
        case .unavailable:
            return "<unavailable>"
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? RuntimeType else {
            return false
        }
        if self === object {
            return true
        }
        switch (availability, object.availability) {
        case (.available, .available):
            return kind == object.kind
        case let (.unavailable(lreason), .unavailable(rreason)):
            return lreason == rreason
        case (.available, _),
             (.unavailable, _):
            return false
        }
    }

    public override var hash: Int {
        return description.hashValue
    }

    public func cast(_ value: Any) -> Any? {
        guard var value = AnyExpression.unwrap(value) else {
            return nil
        }
        if let hashableValue = value as? _AnyHashable { // Using _AnyHashable bypasses automatic upcasting
            value = hashableValue.base
        }
        if let caster = caster {
            return caster(value)
        }
        func cast(_ value: Any, as type: Any.Type) -> Any? {
            switch type {
            case is NSNumber.Type:
                return value as? NSNumber
            case is CGFloat.Type:
                return value as? CGFloat ??
                    (value as? Double).map { CGFloat($0) } ??
                    (value as? NSNumber).map { CGFloat(truncating: $0) }
            case is Double.Type:
                return value as? Double ??
                    (value as? CGFloat).map { Double($0) } ??
                    (value as? NSNumber).map { Double(truncating: $0) }
            case is Float.Type:
                return value as? Float ??
                    (value as? Double).map { Float($0) } ??
                    (value as? NSNumber).map { Float(truncating: $0) }
            case is Int.Type:
                return value as? Int ??
                    (value as? Double).map { Int($0) } ??
                    (value as? NSNumber).map { Int(truncating: $0) }
            case is UInt.Type:
                return value as? UInt ??
                    (value as? Double).map { UInt($0) } ??
                    (value as? NSNumber).map { UInt(truncating: $0) }
            case is Int64.Type:
                return value as? Int64 ??
                    (value as? Double).map { Int64($0) } ??
                    (value as? NSNumber).map { Int64(truncating: $0) }
            case is UInt64.Type:
                return value as? UInt64 ??
                    (value as? Double).map { UInt64($0) } ??
                    (value as? NSNumber).map { UInt64(truncating: $0) }
            case is Bool.Type:
                return value as? Bool ??
                    (value as? Double).map { $0 != 0 } ??
                    (value as? NSNumber).map { $0 != 0 }
            case is String.Type,
                 is NSString.Type:
                return value as? String ?? "\(value)"
            case is NSAttributedString.Type:
                return value as? NSAttributedString ?? NSAttributedString(string: "\(value)")
            case let subtype as AnyClass:
                return (value as AnyObject).isKind(of: subtype) ? value : nil
            case _ where type == Any.self:
                return value
            default:
                if let nsValue = value as? NSValue, sanitizedStructName(String(cString: nsValue.objCType)) == "\(type)" {
                    return value
                }
                return type == Swift.type(of: value) || "\(type)" == "\(Swift.type(of: value))" ? value : nil
            }
        }
        switch kind {
        case let .any(subtype),
             let .options(subtype, _):
            return cast(value, as: subtype)
        case let .class(type):
            if let value = value as? AnyClass, value.isSubclass(of: type) {
                return value
            }
            return nil
        case let .struct(type):
            if let value = value as? NSValue, sanitizedStructName(String(cString: value.objCType)) == type {
                return value
            }
            return nil
        case let .pointer(type):
            switch type {
            case "CGColor" where value is UIColor:
                return (value as! UIColor).cgColor
            case "CGImage" where value is UIImage:
                return (value as! UIImage).cgImage
            case "CGPath":
                if "\(value)".hasPrefix("Path") {
                    return value
                }
                fallthrough
            case "CGColor",
                 "CGImage":
                if "\(value)".hasPrefix("<\(type)") {
                    return value
                }
                return nil
            default:
                return value // No way to validate
            }
        case let .protocol(type):
            return (value as AnyObject).conforms(to: type) ? value : nil
        case let .array(type):
            if type.kind == .any(Any.self), value is NSArray {
                return value // Fast path, avoids copying
            }
            guard var array = value as? [Any] else {
                return type.cast(value).map { [$0] } // Scalar values are array-ified
            }
            for (i, value) in array.enumerated() {
                guard let value = type.cast(value) else {
                    return nil
                }
                array[i] = value
            }
            return array
        }
    }

    public func matches(_ type: Any.Type) -> Bool {
        switch kind {
        case let .any(_type):
            if let lhs = type as? AnyClass, let rhs = _type as? AnyClass {
                return rhs.isSubclass(of: lhs)
            }
            return type == _type || "\(type)" == "\(_type)"
        default:
            return false
        }
    }

    public func matches(_ value: Any) -> Bool {
        return cast(value) != nil
    }
}

// Return the human-readable name, without braces or underscores, etc
private func sanitizedStructName(_ objCType: String) -> String {
    guard let equalRange = objCType.range(of: "="),
        let braceRange = objCType.range(of: "{")
    else {
        return objCType
    }
    let name: String = String(objCType[braceRange.upperBound ..< equalRange.lowerBound])
    switch name {
    case "_NSRange":
        return "NSRange" // Yay! special cases
    default:
        return name
    }
}

// Converts type name to appropriate selector for lookup on RuntimeType
func sanitizedTypeName(_ typeName: String) -> String {
    var tail = Substring(typeName)
    var head = tail.popFirst().map { String($0.lowercased()) } ?? ""
    while let char = tail.popFirst() {
        if char.isLowercase || tail.first?.isLowercase == true {
            head.append(char)
            break
        }
        head += String(char.lowercased())
    }
    return String(head + tail).replacingOccurrences(of: ".", with: "_")
}
