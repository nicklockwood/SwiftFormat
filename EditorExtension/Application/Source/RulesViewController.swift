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
        return stripMarkdown(help)
    }
}

extension OptionDescriptor {
    // If this extension won't compile have a look at
    // https://stackoverflow.com/questions/35673290/extension-of-a-nested-type-in-swift
    // https://bugs.swift.org/browse/SR-631

    var toolTip: String {
        return stripMarkdown(help) + "."
    }
}

final class RulesViewController: NSViewController {
    private let ruleStore = RulesStore()
    private let optionStore = OptionsStore()
    private var viewModels = [UserSelectionType]()

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var inferOptionsButton: NSButton!
    @IBOutlet var swiftVersionDropDown: NSPopUpButton!
    @IBOutlet var searchField: NSSearchField!

    override func viewDidLoad() {
        super.viewDidLoad()
        inferOptionsButton.state = optionStore.inferOptions ? .on : .off
        swiftVersionDropDown.removeAllItems()
        swiftVersionDropDown.addItems(withTitles: ["auto"] + swiftVersions)
        updateSelectedVersion()
        viewModels = buildRules()
        NotificationCenter.default.addObserver(self, selector: #selector(didLoadNewConfiguration),
                                               name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @objc private func didLoadNewConfiguration(_: Notification) {
        viewModels = buildRules()
        tableView?.reloadData()
        inferOptionsButton?.state = (optionStore.inferOptions ? .on : .off)
        updateSelectedVersion()
    }

    @IBAction private func toggleInferOptions(_ sender: NSButton) {
        optionStore.inferOptions = (sender.state == .on)
        viewModels = buildRules()
        tableView?.reloadData()
    }

    @IBAction func selectVersion(_ sender: NSPopUpButton) {
        var formatOptions = optionStore.formatOptions
        let version = Version(rawValue: sender.selectedItem?.title ?? "0") ?? .undefined
        formatOptions.swiftVersion = version
        optionStore.save(formatOptions)
    }

    private func updateSelectedVersion() {
        let currentVersion = optionStore.formatOptions.swiftVersion
        var selectedIndex = 0
        for (i, versionString) in (["0"] + swiftVersions).enumerated() {
            if currentVersion >= Version(rawValue: versionString) ?? .undefined {
                selectedIndex = i
            }
        }
        swiftVersionDropDown.selectItem(at: selectedIndex)
    }

    private func buildRules() -> [UserSelectionType] {
        let optionsByName = Dictionary(uniqueKeysWithValues: optionStore
            .options
            .map { ($0.descriptor.argumentName, $0) })
        let filterText = searchField.stringValue.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).lowercased()

        var results = [UserSelectionType]()
        ruleStore
            .rules
            .filter { filterText.isEmpty || $0.name.lowercased().contains(filterText) }
            .sorted()
            .forEach { rule in
                guard let formatRule = FormatRules.byName[rule.name] else { return }

                let associatedOptions = formatRule
                    .options
                    .compactMap { optionName in optionsByName[optionName] }
                    .sorted { $0.descriptor.displayName < $1.descriptor.displayName }
                    .compactMap { option -> UserSelectionType? in
                        guard !option.isDeprecated else {
                            return nil
                        }
                        let descriptor = option.descriptor
                        let selection = option.argumentValue
                        let saveOption: (String) -> Void = { [weak self] in
                            var option = option
                            option.argumentValue = $0
                            self?.optionStore.save(option)
                        }

                        let enabled = !optionStore.inferOptions

                        switch descriptor.type {
                        case let .binary(t, f):
                            let list = UserSelectionList(
                                identifier: descriptor.argumentName,
                                title: descriptor.displayName,
                                description: descriptor.toolTip,
                                isEnabled: enabled,
                                selection: selection,
                                options: [t[0], f[0]],
                                observer: saveOption
                            )
                            return UserSelectionType.list(list)

                        case let .enum(values):
                            let list = UserSelectionList(
                                identifier: descriptor.argumentName,
                                title: descriptor.displayName,
                                description: descriptor.toolTip,
                                isEnabled: enabled,
                                selection: selection,
                                options: values,
                                observer: saveOption
                            )
                            return UserSelectionType.list(list)

                        case .text, .int, .set, .array:
                            let freeText = UserSelectionFreeText(
                                identifier: descriptor.argumentName,
                                title: descriptor.displayName,
                                description: descriptor.toolTip,
                                isEnabled: enabled,
                                selection: selection,
                                observer: { input in
                                    if descriptor.validateArgument(input) {
                                        saveOption(input)
                                    }
                                },
                                validationStrategy: descriptor.validateArgument
                            )
                            return UserSelectionType.freeText(freeText)
                        }
                    }

                let d = UserSelectionBinary(identifier: rule.name,
                                            title: rule.name,
                                            description: formatRule.toolTip,
                                            isEnabled: true,
                                            selection: rule.isEnabled,
                                            observer: { [weak self] in
                                                var updatedRule = rule
                                                updatedRule.isEnabled = $0
                                                self?.ruleStore.save(updatedRule)
                                            })

                results.append(UserSelectionType.binary(d))
                results.append(contentsOf: associatedOptions)
            }

        return results
    }

    func model(forRow row: Int) -> UserSelectionType {
        return viewModels[row]
    }
}

// MARK: - Search Field Delegate

extension RulesViewController: NSSearchFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == searchField {
            viewModels = buildRules()
            tableView?.reloadData()
        }
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
        let model = self.model(forRow: row)
        let id: NSUserInterfaceItemIdentifier
        switch model {
        case .binary:
            id = .binarySelectionTableCellView
        case .list:
            id = .listSelectionTableCellView
        case .freeText:
            id = .freeTextTableCellView
        }

        return tableView.makeView(withIdentifier: id, owner: self)
    }

    func tableView(_ tableView: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        if let rowView = tableView.makeView(withIdentifier: .ruleRowView, owner: self) as? NSTableRowView {
            return rowView
        }

        let rowView = NSTableRowView(frame: .zero)
        rowView.identifier = .ruleRowView
        return rowView
    }

    func tableView(_: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        switch model(forRow: row) {
        case .binary:
            rowView.backgroundColor = NSColor.controlAlternatingRowBackgroundColors[1]
        case .list, .freeText:
            rowView.backgroundColor = NSColor.controlAlternatingRowBackgroundColors[0]
        }
    }
}

private extension NSUserInterfaceItemIdentifier {
    static let ruleRowView = NSUserInterfaceItemIdentifier(rawValue: "RuleRowView")
}
