//
//  FreeTextTableCellView.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 04-02-18.
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

import Cocoa

class FreeTextTableCellView: NSTableCellView {
    @IBOutlet var title: NSTextField!
    @IBOutlet var freeTextField: NSTextField!

    override var objectValue: Any? {
        didSet {
            guard let freeText = objectValue as? UserSelectionFreeText else {
                return
            }
            title.stringValue = freeText.title ?? ""
            freeTextField.stringValue = freeText.selection
            updateErrorState()
        }
    }

    func updateErrorState() {
        guard let freeText = objectValue as? UserSelectionFreeText else {
            return
        }
        title.textColor = freeText.isValid ? NSColor.textColor : NSColor.red
    }
}

extension FreeTextTableCellView: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        guard let textView: NSTextView = obj.userInfo!["NSFieldEditor"] as? NSTextView,
            let freeText = objectValue as? UserSelectionFreeText else {
            return
        }
        freeText.selection = textView.string
        updateErrorState()
    }
}

extension NSUserInterfaceItemIdentifier {
    static let freeTextTableCellView = NSUserInterfaceItemIdentifier(rawValue: "FreeTextTableCellView")
}
