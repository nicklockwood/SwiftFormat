//
//  UserSelection.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 02-02-18.
//  Copyright 2018 Nick Lockwood
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

enum UserSelectionType {
    //  binary, list, freeText, none (for header), listOrFreeText
    case none(UserSelection)
    case binary(UserSelectionBinary)
    case list(UserSelectionList)
    case freeText(UserSelectionFreeText)

    //  This shold be a Protocol Extension and have unit test
    func associatedValue() -> Any? {
        let enumMirror = Mirror(reflecting: self)
        let enumAssociatedValue = enumMirror.children.first?.value
        return enumAssociatedValue
    }
}

class UserSelection {
    let identifier: String
    let title: String?
    let description: String?

    init(identifier: String, title: String?, description: String?) {
        self.identifier = identifier
        self.title = title
        self.description = description
    }
}

final class UserSelectionBinary: UserSelection {
    var selection: Bool {
        didSet {
            selectionObserver?(selection)
        }
    }

    private let selectionObserver: ((Bool) -> Void)?
    init(identifier: String, title: String?, description: String?, selection: Bool, observer: ((Bool) -> Void)?) {
        self.selection = selection
        selectionObserver = observer
        super.init(identifier: identifier, title: title, description: description)
    }
}

final class UserSelectionList: UserSelection {
    var selection: String {
        didSet {
            selectionObserver?(selection)
        }
    }

    let options: [String]

    private let selectionObserver: ((String) -> Void)?
    init(identifier: String, title: String?, description: String?, selection: String, options: [String], observer: ((String) -> Void)?) {
        self.selection = selection
        self.options = options
        selectionObserver = observer
        super.init(identifier: identifier, title: title, description: description)
    }
}

final class UserSelectionFreeText: UserSelection {

    static let defaultValidationStrategy: (String) -> Bool = { String -> Bool in
        return true
    }

    var selection: String {
        didSet {
            selectionObserver?(selection)
        }
    }
    var isValid: Bool {
        return validationStrategy(selection)
    }

    private let validationStrategy: (String) -> Bool
    private let selectionObserver: ((String) -> Void)?
    init(identifier: String,
         title: String?,
         description: String?,
         selection: String,
         observer: ((String) -> Void)? = nil,
         validationStrategy: @escaping ((String) -> Bool) = UserSelectionFreeText.defaultValidationStrategy) {

        self.selection = selection
        selectionObserver = observer
        self.validationStrategy = validationStrategy
        super.init(identifier: identifier, title: title, description: description)
    }
}
