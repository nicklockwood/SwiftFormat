//
//  AttributeOrder.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 16/11/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Use a consistent order for declaration attributes.
    static let attributeOrder = FormatRule(
        help: "Use consistent ordering for declaration attributes.",
        options: ["attribute-order"]
    ) { formatter in
        formatter.forEach(.keyword) { i, token in
            guard token.isDeclarationTypeKeyword else { return }
            formatter.orderDeclarationAttributes(at: i)
        }
    } examples: {
        """
        ```diff
        - @objc
        - @discardableResult
        - @available(iOS 15, *)
        + @available(iOS 15, *)
        + @discardableResult
        + @objc
          func update() -> Bool { true }
        ```

        The default order is:
        `\(_FormatRules.defaultAttributeOrder.joined(separator: "`, `"))`.

        Use `--attribute-order available,MainActor,Test` to set a preferred order.
        Omitted defaults are inserted using their default positions, as with `--modifier-order`.
        Include custom attribute names without `@`. Qualified names must match exactly.
        An empty list uses the default order.

        Attributes not in the preferred order (including unlisted macros and property wrappers)
        are preserved as boundaries: attributes aren't moved across them. Comments also prevent
        reordering. Repeated attributes retain their relative order.

        Arguments move with their attribute and don't affect ordering. Existing spacing between
        attributes is preserved; use `wrapAttributes` to configure their placement.
        """
    }
}

extension Formatter {
    /// Declaration attribute names, in preferred order.
    var preferredAttributeOrder: [String] {
        let defaults = _FormatRules.defaultAttributeOrder
        guard !options.attributeOrder.isEmpty else { return defaults }
        return _FormatRules.mergePreferredOrder(options.attributeOrder, with: defaults.map { [$0] })
    }

    /// Sort attributes within declaration prefixes, leaving type attributes alone.
    func orderDeclarationAttributes(at declarationIndex: Int) {
        var attributes = [Int]()
        _ = modifiersForDeclaration(at: declarationIndex) { index, _ in
            if tokens[index].isAttribute {
                attributes.append(index)
            }
            return false
        }

        defer { updateEnablement(at: declarationIndex) }
        // Swapping attributes doesn't change the total token count, so later indices stay valid.
        for index in attributes.reversed() {
            updateEnablement(at: index)
            guard isEnabled(at: index) else { continue }
            orderAttribute(at: index)
        }
    }

    /// Insert an attribute into the preceding ordered run without moving its surrounding whitespace.
    func orderAttribute(at index: Int) {
        let order = preferredAttributeOrder
        guard let priority = attributePriority(at: index, order: order) else { return }
        var currentIndex = index
        while let previousIndex = self.index(of: .attribute, before: currentIndex),
              let previousEnd = endOfAttribute(at: previousIndex),
              previousEnd < currentIndex,
              tokens[previousEnd + 1 ..< currentIndex].allSatisfy(\.isSpaceOrLinebreak),
              let previousPriority = attributePriority(at: previousIndex, order: order),
              previousPriority > priority,
              let currentEnd = endOfAttribute(at: currentIndex)
        {
            updateEnablement(at: previousIndex)
            guard isEnabled(at: previousIndex) else { break }

            let count = currentEnd - currentIndex + 1
            moveTokens(in: currentIndex ... currentEnd, to: previousIndex)
            moveTokens(in: previousIndex + count ... previousEnd + count, to: currentEnd + 1)
            currentIndex = previousIndex
        }
    }

    /// Match the full attribute name, excluding generic parameters and arguments.
    func attributePriority(at index: Int, order: [String]) -> Int? {
        guard let end = endOfAttribute(at: index),
              !tokens[index ... end].contains(where: \.isComment),
              next(.nonSpace, after: end)?.isComment != true
        else { return nil }

        let name = tokens[index ... end]
            .prefix(while: { !$0.isStartOfScope })
            .filter { !$0.isSpaceOrLinebreak }.string.dropFirst()
        return order.firstIndex(of: String(name))
    }
}

extension _FormatRules {
    static let defaultAttributeOrder = [
        // Availability and declaration roles.
        "available", "backDeployed", "main", "propertyWrapper", "resultBuilder",
        "dynamicCallable", "dynamicMemberLookup",
        // Resilience, optimization, and result handling.
        "frozen", "inlinable", "usableFromInline", "discardableResult", "warn_unqualified_access",
        // Concurrency and interoperability, closest to the declaration.
        "preconcurrency", "MainActor", "objcMembers", "nonobjc", "objc",
        "IBDesignable", "IBInspectable", "IBAction", "IBSegueAction", "IBOutlet",
        "NSManaged", "NSCopying", "GKInspectable",
    ]
}
