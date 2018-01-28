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

    class RuleViewModel {
        let name: String
        var isEnable: Bool {
            didSet {
                enableDidChangeAction(isEnable)
            }
        }

        private let enableDidChangeAction: (Bool) -> Void

        init(name: String, isEnable: Bool, enableDidChangeAction: @escaping (Bool) -> Void) {
            self.name = name
            self.isEnable = isEnable
            self.enableDidChangeAction = enableDidChangeAction
        }
    }

    var ruleViewModels = [RuleViewModel]()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        title = "Rules"
    }

    @IBOutlet var tableView: NSTableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            let nib = NSNib(nibNamed: "RuleSelectionTableCellView", bundle: nil)
            tableView.register(nib, forIdentifier: "bob")
            tableView.usesAutomaticRowHeights = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let store = RulesStore()

        ruleViewModels = store
            .rules
            .sorted()
            .map { rule in
                RulesViewController.RuleViewModel(name: rule.name,
                                                  isEnable: rule.isActive,
                                                  enableDidChangeAction: {
                                                      var updatedRule = rule
                                                      updatedRule.isActive = $0
                                                      store.save(updatedRule)
                })
            }
    }
}

// MARK: - Table View Data Source
extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ruleViewModels.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return ruleViewModels[row]
    }
}

// MARK: - Table View Delegate
extension RulesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {

        let cell = tableView.makeView(withIdentifier: "bob", owner: nil) as? RuleSelectionTableCellView
        return cell
    }
}
