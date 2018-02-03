//
//  RulesViewController.swift
//  SwiftFormat for Xcode
//
//  Created by Vincent Bernier on 27/01/18.
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

/// Goal: Display Active & Inactive Rules and allow their state to be modified
final class RulesViewController: NSViewController {

    final class RuleViewModel {
        //  TODO: Find a better name for enum and cases
        enum GroupPart {
            case main
            case sub
        }

        let selectionType: UserSelectionType
        let grouping: GroupPart
        init(selectionType: UserSelectionType, grouping: GroupPart = GroupPart.main) {
            self.selectionType = selectionType
            self.grouping = grouping
        }
    }

    private var ruleViewModels = [RuleViewModel]()

    @IBOutlet var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let store = RulesStore()
        ruleViewModels = store
            .rules
            .sorted()
            .map { rule in
                let d = UserSelectionBinary(identifier: rule.name,
                                            title: rule.name,
                                            description: nil,
                                            selection: rule.isEnabled,
                                            observer: {
                                                var updatedRule = rule
                                                updatedRule.isEnabled = $0
                                                store.save(updatedRule)
                })
                return UserSelectionType.binary(d)
            }
            .map { selectionType in
                return RuleViewModel(selectionType: selectionType)
        }

        let optionSelecitonType = UserSelectionType.binary(UserSelectionBinary(identifier: "option test",
                                                                               title: "option test",
                                                                               description: nil,
                                                                               selection: false,
                                                                               observer: { print("new value == \($0)") }))
        ruleViewModels.append(RuleViewModel(selectionType: optionSelecitonType, grouping: .sub))
    }

    func model(forRow row: Int) -> RuleViewModel {
        return ruleViewModels[row]
    }
}

// MARK: - Table View Data Source

extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return ruleViewModels.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return model(forRow: row).selectionType.associatedValue()
    }
}

// MARK: - Table View Delegate

extension RulesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let rule = model(forRow: row)
        switch rule.grouping {
        case .main:
            return tableView.makeView(withIdentifier: .mainBinarySelectionTableCellView, owner: self) as? MainBinarySelectionTableCellView
        case .sub:
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "OptionTestCell"), owner: self)
        }
    }
}

