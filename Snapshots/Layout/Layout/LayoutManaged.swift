//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

/// A protocol for view-type classes that can be configured using Layout
@objc protocol LayoutConfigurable: class {
    /// Expression names and types
    @objc static var expressionTypes: [String: RuntimeType] { get }
}

/// A protocol for view-type classes that can be managed by Layout
@objc protocol LayoutManaged: LayoutConfigurable {
    /// Constructor argument names and types
    @objc static var parameterTypes: [String: RuntimeType] { get }

    /// Default expressions to use when not specified
    @objc static var defaultExpressions: [String: String] { get }

    /// The name of the String or NSAttributedString property to use for body text
    /// Return nil to indicate that the view doesn't allow body text
    @objc optional static var bodyExpression: String? { get }

    /// Deprecated symbols
    /// Key is the symbol name, value is the suggested replacement
    /// Empty value string indicates no replacement available
    @objc static var deprecatedSymbols: [String: String] { get }

    // Set expression value
    @objc func setValue(_ value: Any, forExpression name: String) throws

    // Set expression value with animation (if applicable)
    @objc func setAnimatedValue(_ value: Any, forExpression name: String) throws

    /// Get symbol value
    @objc func value(forSymbol name: String) throws -> Any

    /// Called immediately before a child node is added
    /// Returning false will cancel insertion of the node
    @objc func shouldInsertChildNode(_ node: LayoutNode, at _: Int) -> Bool

    /// Called immediately after a child node is added
    @objc func didInsertChildNode(_ node: LayoutNode, at index: Int)

    /// Called immediately before a child node is removed
    // TODO: remove index argument as it isn't used
    @objc func willRemoveChildNode(_ node: LayoutNode, at index: Int)

    /// Called immediately after layout has been updated
    @objc func didUpdateLayout(for node: LayoutNode)
}

func clearExpressionTypes() {
    _cachedExpressionTypes.removeAll()
}

extension LayoutConfigurable {
    /// Cached copy of the view expressions
    static var cachedExpressionTypes: [String: RuntimeType] {
        if let types = _cachedExpressionTypes[hashKey] {
            return types
        }
        let types = expressionTypes
        _cachedExpressionTypes[hashKey] = types
        return types
    }

    fileprivate static var hashKey: Int {
        // TODO: is it safe to assume uniqueness for this?
        return (self as AnyClass).hash()
    }
}

private var _cachedExpressionTypes = [Int: [String: RuntimeType]]()
