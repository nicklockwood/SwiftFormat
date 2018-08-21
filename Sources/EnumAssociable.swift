//
//  EnumAssociable.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 13-02-18.
//  Copyright © 2018 Nick Lockwood.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
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

import Foundation

protocol EnumAssociable {}

extension EnumAssociable {
    private var _associatedValue: Any? {
        let mirror = Mirror(reflecting: self)
        precondition(mirror.displayStyle == Mirror.DisplayStyle.enum, "Can only be apply to an Enum")
        let optionalValue = mirror.children.first?.value
        if let value = optionalValue {
            let description = "\(value)"
            precondition(!description.contains("->") && !description.contains("(Function)"),
                         "Doesn't work when associated value is a closure")
        }
        return optionalValue
    }

    func associatedValue<T: _Optional>() -> T {
        guard let value = _associatedValue else {
            return T._none
        }
        return value as! T
    }

    func associatedValue<T>() -> T {
        return _associatedValue as! T
    }
}

protocol _Optional {
    static var _none: Self { get }
}

extension Optional: _Optional {
    static var _none: Optional { return none }
}
