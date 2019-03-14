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

extension FormatOptions.Descriptor {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        inferOptionsButton.state = optionStore.inferOptions ? .on : .off
        viewModels = buildRules()
        NotificationCenter.default.addObserver(self, selector: #selector(didLoadNewConfiguration), name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @objc private func didLoadNewConfiguration(_: Notification) {
        viewModels = buildRules()
        tableView?.reloadData()
        inferOptionsButton?.state = (optionStore.inferOptions ? .on : .off)
    }

    @IBAction private func toggleInferOptions(_ sender: NSButton) {
        optionStore.inferOptions = (sender.state == .on)
        viewModels = buildRules()
        tableView?.reloadData()
    }

    private func buildRules() -> [UserSelectionType] {
        let optionsByName = Dictionary(uniqueKeysWithValues: optionStore
            .options
            .map { ($0.descriptor.argumentName, $0) })

        var results = [UserSelectionType]()
        ruleStore
            .rules
            .sorted()
            .forEach { rule in
                let formatRule = FormatRules.byName[rule.name]!

                let associatedOptions = formatRule
                    .options
                    .compactMap { optionName in optionsByName[optionName] }
                    .sorted { $0.descriptor.displayName < $1.descriptor.displayName }
                    .compactMap { option -> UserSelectionType? in
                        guard !option.isDeprecated,
                            option.descriptor.argumentName != FormatOptions.Descriptor.indentation.argumentName else {
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

                        case .text, .set:
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
        let backgroundColor: NSColor
        switch model {
        case .binary:
            id = .binarySelectionTableCellView
            let gray: CGFloat = 0.97
            backgroundColor = NSColor(calibratedRed: gray, green: gray, blue: gray, alpha: gray)
        case .list:
            id = .listSelectionTableCellView
            backgroundColor = NSColor.white
        case .freeText:
            id = .freeTextTableCellView
            backgroundColor = NSColor.white
        }

        let cell = tableView.makeView(withIdentifier: id, owner: self)
        cell?.wantsLayer = true

        cell?.layer?.backgroundColor = backgroundColor.cgColor

        return cell
    }
}
