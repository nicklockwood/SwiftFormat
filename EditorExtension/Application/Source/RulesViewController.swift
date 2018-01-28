//
//  RulesViewController.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 27-01-18.
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

import Cocoa

/// Goal: Display Active & Inactive Rules and allow theire state modification
class RulesViewController: NSViewController {

    override var title: String? {
        get {
            return "Rules"
        }
        set {
            super.title = title
        }
    }

    @IBOutlet var tableView: NSTableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            let nib = NSNib(nibNamed: "RuleSelectionTableCellView", bundle: nil)
            tableView.register(nib, forIdentifier: "bob")
            tableView.usesAutomaticRowHeights = true
            tableView.reloadData()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

//MARK: - Table View Data Source
extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 22
    }


    /* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView). Note that NSTableCellView does not actually display the objectValue, and its value is to be used for bindings. See NSTableCellView.h for more information.
     */
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return row
    }
}

//MARK: - Table View Delegate
extension RulesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {

        let cell = tableView.makeView(withIdentifier: "bob", owner: nil) as? RuleSelectionTableCellView
        cell?.button.title = "My title: \(row)"
        return cell
    }
}


