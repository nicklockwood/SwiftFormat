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

extension FormatRule {
    var toolTip: String {
        return stripMarkdown(help) + "."
    }
}

final class RulesViewController: NSViewController {
    private var viewModels = [UserSelectionType]()

    @IBOutlet var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModels = buildRules()
        NotificationCenter.default.addObserver(self, selector: #selector(didLoadNewConfiguration), name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @objc private func didLoadNewConfiguration(_: Notification) {
        viewModels = buildRules()
        tableView?.reloadData()
    }

    private func buildRules() -> [UserSelectionType] {
        let store = RulesStore()
        let rules: [UserSelectionType] = store
            .rules
            .sorted()
            .map { rule in
                let d = UserSelectionBinary(
                    identifier: rule.name,
                    title: rule.name,
                    description: FormatRules.byName[rule.name]!.toolTip,
                    isEnabled: true,
                    selection: rule.isEnabled,
                    observer: {
                        var updatedRule = rule
                        updatedRule.isEnabled = $0
                        store.save(updatedRule)
                    }
                )
                return UserSelectionType.binary(d)
            }

        return rules
    }

    func model(forRow row: Int) -> UserSelectionType {
        return viewModels[row]
    }
}

// MARK: - Table View Data Source

extension RulesViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return viewModels.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return model(forRow: row).associatedValue()
    }
}

// MARK: - Table View Delegate

extension RulesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        return tableView.makeView(withIdentifier: .binarySelectionTableCellView, owner: self)
    }
}
