// From https://github.com/DougGregor/swift-macro-examples/blob/main/MacroExamplesLib/Macros.swift
// swiftformat:options --indent 2

import Foundation

/// "Stringify" the provided value and produce a tuple that includes both the
/// original value as well as the source code that generated it.
@freestanding(expression) public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroExamplesPlugin", type: "StringifyMacro")

/// Macro that produces a warning on "+" operators within the expression, and
/// suggests changing them to "-".
@freestanding(expression) public macro addBlocker<T>(_ value: T) -> T = #externalMacro(module: "MacroExamplesPlugin", type: "AddBlocker")

/// Macro that produces a warning, as a replacement for the built-in
/// #warning("...").
@freestanding(expression) public macro myWarning(_ message: String) = #externalMacro(module: "MacroExamplesPlugin", type: "WarningMacro")

public enum FontWeight {
  case thin
  case normal
  case medium
  case semiBold
  case bold
}

public protocol ExpressibleByFontLiteral {
  init(fontLiteralName: String, size: Int, weight: FontWeight)
}

/// Font literal similar to, e.g., #colorLiteral.
@freestanding(expression) public macro fontLiteral<T>(name: String, size: Int, weight: FontWeight) -> T = #externalMacro(module: "MacroExamplesPlugin", type: "FontLiteralMacro")
  where T: ExpressibleByFontLiteral

/// Check if provided string literal is a valid URL and produce a non-optional
/// URL value. Emit error otherwise.
@freestanding(expression) public macro URL(_ stringLiteral: String) -> URL = #externalMacro(module: "MacroExamplesPlugin", type: "URLMacro")

/// Apply the specified attribute to each of the stored properties within the
/// type or member to which the macro is attached. The string can be
/// any attribute (without the `@`).
@attached(memberAttribute)
public macro wrapStoredProperties(_ attributeName: String) = #externalMacro(module: "MacroExamplesPlugin", type: "WrapStoredPropertiesMacro")

/// Wrap up the stored properties of the given type in a dictionary,
/// turning them into computed properties.
///
/// This macro composes three different kinds of macro expansion:
///   * Member-attribute macro expansion, to put itself on all stored properties
///     of the type it is attached to.
///   * Member macro expansion, to add a `_storage` property with the actual
///     dictionary.
///   * Accessor macro expansion, to turn the stored properties into computed
///     properties that look for values in the `_storage` property.
@attached(accessor)
@attached(member, names: named(_storage))
@attached(memberAttribute)
public macro DictionaryStorage() = #externalMacro(module: "MacroExamplesPlugin", type: "DictionaryStorageMacro")

public protocol Observable {}

public protocol Observer<Subject> {
  associatedtype Subject: Observable
}

public struct ObservationRegistrar<Subject: Observable> {
  public init() {}

  public func addObserver(_: some Observer<Subject>) {}

  public func removeObserver(_: some Observer<Subject>) {}

  public func beginAccess<Value>(_ keyPath: KeyPath<Subject, Value>) {
    print("beginning access for \(keyPath)")
  }

  public func beginAccess() {
    print("beginning access in \(Subject.self)")
  }

  public func endAccess() {
    print("ending access in \(Subject.self)")
  }

  public func register<Value>(observable _: Subject, willSet: KeyPath<Subject, Value>, to _: Value) {
    print("registering willSet event for \(willSet)")
  }

  public func register<Value>(observable _: Subject, didSet: KeyPath<Subject, Value>) {
    print("registering didSet event for \(didSet)")
  }
}

@attached(member, names: named(Storage), named(_storage), named(_registrar), named(addObserver), named(removeObserver), named(withTransaction))
@attached(memberAttribute)
@attached(conformance)
public macro Observable() = #externalMacro(module: "MacroExamplesPlugin", type: "ObservableMacro")

@attached(accessor)
public macro ObservableProperty() = #externalMacro(module: "MacroExamplesPlugin", type: "ObservablePropertyMacro")

/// Adds a "completionHandler" variant of an async function, which creates a new
/// task , calls thh original async function, and delivers its result to the completion
/// handler.
@attached(peer, names: overloaded)
public macro AddCompletionHandler() =
  #externalMacro(module: "MacroExamplesPlugin", type: "AddCompletionHandlerMacro")

@attached(peer, names: overloaded)
public macro AddAsync() =
  #externalMacro(module: "MacroExamplesPlugin", type: "AddAsyncMacro")

/// Add computed properties named `is<Case>` for each case element in the enum.
@attached(member, names: arbitrary)
public macro CaseDetection() = #externalMacro(module: "MacroExamplesPlugin", type: "CaseDetectionMacro")

@attached(member, names: named(Meta))
public macro MetaEnum() = #externalMacro(module: "MacroExamplesPlugin", type: "MetaEnumMacro")

@attached(member)
public macro CodableKey(name: String) = #externalMacro(module: "MacroExamplesPlugin", type: "CodableKey")

@attached(member, names: named(CodingKeys))
public macro CustomCodable() = #externalMacro(module: "MacroExamplesPlugin", type: "CustomCodable")

/// Create an option set from a struct that contains a nested `Options` enum.
///
/// Attach this macro to a struct that contains a nested `Options` enum
/// with an integer raw value. The struct will be transformed to conform to
/// `OptionSet` by
///   1. Introducing a `rawValue` stored property to track which options are set,
///    along with the necessary `RawType` typealias and initializers to satisfy
///    the `OptionSet` protocol.
///   2. Introducing static properties for each of the cases within the `Options`
///    enum, of the type of the struct.
///
/// The `Options` enum must have a raw value, where its case elements
/// each indicate a different option in the resulting option set. For example,
/// the struct and its nested `Options` enum could look like this:
///
///     @MyOptionSet
///     struct ShippingOptions {
///       private enum Options: Int {
///         case nextDay
///         case secondDay
///         case priority
///         case standard
///       }
///     }
@attached(member, names: arbitrary)
@attached(conformance)
public macro MyOptionSet<RawType>() = #externalMacro(module: "MacroExamplesPlugin", type: "OptionSetMacro")
