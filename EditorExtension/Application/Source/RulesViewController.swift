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
        var isEnabled: Bool {
            didSet {
                enableDidChangeAction(isEnabled)
            }
        }

        private let enableDidChangeAction: (Bool) -> Void

        init(name: String, isEnabled: Bool, enableDidChangeAction: @escaping (Bool) -> Void) {
            self.name = name
            self.isEnabled = isEnabled
            self.enableDidChangeAction = enableDidChangeAction
        }
    }

    private var ruleViewModels = [RuleViewModel]()

    @IBOutlet var tableView: NSTableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            RuleSelectionTableCellView.register(with: tableView)
            if #available(OSX 10.13, *) {
                tableView.usesAutomaticRowHeights = true
            } else {
                tableView.rowHeight = 30
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let store = RulesStore()
        ruleViewModels = store
            .rules
            .sorted()
            .map { rule in
                RulesViewController.RuleViewModel(name: rule.name,
                                                  isEnabled: rule.isEnabled,
                                                  enableDidChangeAction: {
                                                      var updatedRule = rule
                                                      updatedRule.isEnabled = $0
                                                      store.save(updatedRule)
                })
            }
    }
}

// MARK: - Table View Data Source

extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return ruleViewModels.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return ruleViewModels[row]
    }
}

// MARK: - Table View Delegate

extension RulesViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView,
                   viewFor _: NSTableColumn?,
                   row _: Int) -> NSView? {

        let cell = tableView.makeView(withIdentifier: RuleSelectionTableCellView.defaultIdentifier, owner: nil) as? RuleSelectionTableCellView
        return cell
    }
}
