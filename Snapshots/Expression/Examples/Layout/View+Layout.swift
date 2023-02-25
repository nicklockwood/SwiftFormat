//
//  View+Layout.swift
//  Layout
//
//  Created by Nick Lockwood on 21/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Expression
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Expression
import UIKit

private class LayoutData: NSObject {
    private weak var view: UIView!
    private var inProgress = Set<String>()

    func computedValue(forKey key: String) throws -> Double {
        if inProgress.contains(key) {
            throw Expression.Error.message("Circular reference: \(key) depends on itself")
        }
        defer { inProgress.remove(key) }
        inProgress.insert(key)

        if let expression = props[key] {
            return try expression.evaluate()
        }
        switch key {
        case "right":
            return try computedValue(forKey: "left") + computedValue(forKey: "width")
        case "bottom":
            return try computedValue(forKey: "top") + computedValue(forKey: "height")
        default:
            throw Expression.Error.undefinedSymbol(.variable(key))
        }
    }

    private func common(_ symbol: Expression.Symbol) -> Expression.SymbolEvaluator? {
        switch symbol {
        case .variable("auto"):
            return { _ in throw Expression.Error.message("`auto` can only be used for width or height") }
        case let .variable(name):
            let parts = name.components(separatedBy: ".")
            if parts.count == 2 {
                return { [unowned self] _ in
                    if let sublayout = self.view.window?.subview(forKey: parts[0])?.layout {
                        return try sublayout.computedValue(forKey: parts[1])
                    }
                    throw Expression.Error.message("No view found for key `\(parts[0])`")
                }
            }
            return { [unowned self] _ in
                try self.computedValue(forKey: parts[0])
            }
        default:
            return nil
        }
    }

    var key: String?
    var left: String? {
        didSet {
            props["left"] = Expression(
                Expression.parse(left ?? "0"),
                impureSymbols: { symbol in
                    switch symbol {
                    case .postfix("%"):
                        return { [unowned self] args in
                            self.view.superview.map { Double($0.frame.width) / 100 * args[0] } ?? 0
                        }
                    default:
                        return self.common(symbol)
                    }
                }
            )
        }
    }

    var top: String? {
        didSet {
            props["top"] = Expression(
                Expression.parse(top ?? "0"),
                impureSymbols: { symbol in
                    switch symbol {
                    case .postfix("%"):
                        return { [unowned self] args in
                            self.view.superview.map { Double($0.frame.height) / 100 * args[0] } ?? 0
                        }
                    default:
                        return self.common(symbol)
                    }
                }
            )
        }
    }

    var width: String? {
        didSet {
            props["width"] = Expression(
                Expression.parse(width ?? "100%"),
                impureSymbols: { symbol in
                    switch symbol {
                    case .postfix("%"):
                        return { [unowned self] args in
                            self.view.superview.map { Double($0.frame.width) / 100 * args[0] } ?? 0
                        }
                    case .variable("auto"):
                        return { [unowned self] _ in
                            self.view.superview.map { superview in
                                Double(self.view.systemLayoutSizeFitting(superview.frame.size).width)
                            } ?? 0
                        }
                    default:
                        return self.common(symbol)
                    }
                }
            )
        }
    }

    var height: String? {
        didSet {
            props["height"] = Expression(
                Expression.parse(height ?? "100%"),
                impureSymbols: { symbol in
                    switch symbol {
                    case .postfix("%"):
                        return { [unowned self] args in
                            self.view.superview.map { Double($0.frame.height) / 100 * args[0] } ?? 0
                        }
                    case .variable("auto"):
                        return { [unowned self] _ in
                            try self.view.superview.map { superview in
                                var size = superview.frame.size
                                size.width = try CGFloat(self.computedValue(forKey: "width"))
                                return Double(self.view.systemLayoutSizeFitting(size).height)
                            } ?? 0
                        }
                    default:
                        return self.common(symbol)
                    }
                }
            )
        }
    }

    private var props: [String: Expression] = [:]

    init(_ view: UIView) {
        self.view = view
        left = nil
        top = nil
        width = nil
        height = nil
    }
}

@IBDesignable
public extension UIView {
    fileprivate var layout: LayoutData? {
        return layout(create: false)
    }

    private func layout(create: Bool) -> LayoutData! {
        let layout = layer.value(forKey: "layout") as? LayoutData
        if layout == nil, create {
            let layout = LayoutData(self)
            layer.setValue(layout, forKey: "layout")
            return layout
        }
        return layout
    }

    @IBInspectable var key: String? {
        get { return layout?.key }
        set { layout(create: true).key = newValue }
    }

    @IBInspectable var left: String? {
        get { return layout?.left }
        set { layout(create: true).left = newValue }
    }

    @IBInspectable var top: String? {
        get { return layout?.top }
        set { layout(create: true).top = newValue }
    }

    @IBInspectable var width: String? {
        get { return layout?.width }
        set { layout(create: true).width = newValue }
    }

    @IBInspectable var height: String? {
        get { return layout?.height }
        set { layout(create: true).height = newValue }
    }

    fileprivate func subview(forKey key: String) -> UIView? {
        if self.key == key {
            return self
        }
        for view in subviews {
            if let match = view.subview(forKey: key) {
                return match
            }
        }
        return nil
    }

    func updateLayout() throws {
        guard let layout = layout(create: true) else {
            return
        }
        frame = try CGRect(x: layout.computedValue(forKey: "left"),
                           y: layout.computedValue(forKey: "top"),
                           width: layout.computedValue(forKey: "width"),
                           height: layout.computedValue(forKey: "height"))

        for view in subviews {
            try view.updateLayout()
        }
    }
}
