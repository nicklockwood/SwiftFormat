//
//  ListSelectionTableCellView.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 03-02-18.
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

class ListSelectionTableCellView: NSTableCellView {
    @IBOutlet var title: NSTextField!
    @IBOutlet var dropDown: NSPopUpButton!
    @IBAction func listSelectionChanged(_: NSPopUpButton) {
        guard let model = objectValue as? UserSelectionList else {
            return
        }
        model.selection = dropDown.selectedItem!.title
    }

    override var objectValue: Any? {
        didSet {
            guard let model = objectValue as? UserSelectionList else {
                return
            }
            title.textColor = model.isEnabled ? .textColor : .disabledControlTextColor
            title.stringValue = model.title ?? ""
            dropDown.isEnabled = model.isEnabled
            dropDown.removeAllItems()
            dropDown.addItems(withTitles: model.options.map { $0 })
            dropDown.selectItem(withTitle: model.selection)
        }
    }
}

extension NSUserInterfaceItemIdentifier {
    static let listSelectionTableCellView = NSUserInterfaceItemIdentifier(rawValue: "ListSelectionTableCellView")
}
