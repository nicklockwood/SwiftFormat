//
//  OptionsViewController.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 05/07/2018.
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

extension FormatOptions.Descriptor {
    var toolTip: String {
        return stripMarkdown(help) + "."
    }
}

final class OptionsViewController: NSViewController {
    private var viewModels = [UserSelectionType]()
    private var inferOptions = false
    private let store = OptionsStore()

    @IBOutlet var tableView: NSTableView!
    @IBOutlet var inferOptionsButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateConfiguration()
        NotificationCenter.default.addObserver(self, selector: #selector(updateConfiguration), name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @objc private func updateConfiguration() {
        viewModels = buildOptions()
        inferOptionsButton.state = store.inferOptions ? .on : .off
        tableView?.reloadData()
    }

    @IBAction private func toggleInferOptions(_: NSButton) {
        store.inferOptions = (inferOptionsButton.state == .on)
        viewModels = buildOptions()
        tableView.reloadData()
    }

    private func buildOptions() -> [UserSelectionType] {
        let result = store
            .options
            .sorted(by: { $0.descriptor.displayName < $1.descriptor.displayName })
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
                    self?.store.save(option)
                }

                let enabled = !store.inferOptions

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

        return result
    }

    func model(forRow row: Int) -> UserSelectionType {
        return viewModels[row]
    }
}

// MARK: - Table View Data Source

extension OptionsViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return viewModels.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return model(forRow: row).associatedValue()
    }
}

// MARK: - Table View Delegate

extension OptionsViewController: NSTableViewDelegate {
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
}
