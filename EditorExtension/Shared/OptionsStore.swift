//
//  OptionsStore.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 22-02-18.
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

import Foundation

struct SavedOption {
    var argumentValue: String
    let descriptor: OptionDescriptor

    var isDeprecated: Bool {
        return descriptor.isDeprecated
    }
}

private extension SavedOption {
    init(_ rep: OptionsStore.OptionRepresentation) throws {
        guard let descriptor = Descriptors.byName[rep.id] else {
            throw FormatError.options("Unknown option \(rep.id)")
        }
        self.descriptor = descriptor
        // Sanitize value by converting to FormatOptions and back again
        var options = FormatOptions.default
        try descriptor.toOptions(rep.arg, &options)
        argumentValue = descriptor.fromOptions(options)
    }
}

private extension FormatOptions {
    init(_ rep: OptionsStore.OptionStoreRepresentation) throws {
        var formatOptions = FormatOptions.default
        for descriptor in Descriptors.all.reversed() {
            // By loading formatting options in reverse, we ensure that
            // non-deprecated/renamed values will overwrite legacy values
            if let value = rep[descriptor.argumentName] {
                try descriptor.toOptions(value, &formatOptions)
            }
        }
        self = formatOptions
    }
}

struct OptionsStore {
    fileprivate typealias ArgumentName = String
    fileprivate typealias ArgumentValue = String
    fileprivate typealias OptionRepresentation = (id: ArgumentName, arg: ArgumentValue)
    fileprivate typealias OptionStoreRepresentation = [ArgumentName: ArgumentValue]

    private let optionsKey = "format-options"
    private let inferOptionsKey = "infer-options"
    private let store: UserDefaults

    private static var defaultStore: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: UserDefaults.groupDomain) else {
            fatalError("The UserDefaults Store is invalid")
        }
        return defaults
    }()

    init(_ store: UserDefaults = OptionsStore.defaultStore) {
        self.store = store
        setUpDefaultValuesIfNeeded()
    }

    var formatOptions: FormatOptions {
        return try! FormatOptions(load())
    }

    var inferOptions: Bool {
        get { return (store.object(forKey: inferOptionsKey) as? NSNumber)?.boolValue ?? true }
        nonmutating set {
            store.set(NSNumber(booleanLiteral: newValue), forKey: inferOptionsKey)
        }
    }

    var options: [SavedOption] {
        return try! load().map(SavedOption.init)
    }

    func save(_ option: SavedOption) {
        save((id: option.descriptor.argumentName, arg: option.argumentValue))
    }

    func save(_ options: [SavedOption]) {
        save(options.map { (id: $0.descriptor.argumentName, arg: $0.argumentValue) })
    }

    func save(_ options: FormatOptions) {
        save(Descriptors.all.map {
            let value = $0.fromOptions(options)
            return SavedOption(argumentValue: value, descriptor: $0)
        } as [SavedOption])
    }

    func restore(_ options: FormatOptions) {
        clear()
        save(options)
        addNewOptionsIfNeeded()
    }

    func restore(_ options: [SavedOption]) {
        clear()
        save(options)
        addNewOptionsIfNeeded()
    }

    func resetOptionsToDefaults() {
        inferOptions = true
        let options = Descriptors.all.map {
            (id: $0.argumentName, arg: $0.defaultArgument)
        }
        clear()
        save(options)
    }
}

// MARK: - Business Rules

extension OptionsStore {
    private func setUpDefaultValuesIfNeeded() {
        if store.value(forKey: optionsKey) == nil {
            resetOptionsToDefaults()
        } else {
            addNewOptionsIfNeeded()
        }
    }

    private func addNewOptionsIfNeeded() {
        let allDescriptors = Descriptors.all
        var options = load()
        var idsToRemove = Set(options.keys)

        for descriptor in allDescriptors {
            if idsToRemove.remove(descriptor.argumentName) == nil {
                // New option
                options[descriptor.argumentName] = descriptor.defaultArgument
            }
        }

        for id in idsToRemove {
            // Obsolete option to remove
            options[id] = nil
        }

        save(options)
    }
}

// MARK: - Store Interactions

extension OptionsStore {
    private func clear() {
        store.set(nil, forKey: optionsKey)
    }

    private func load() -> OptionStoreRepresentation {
        guard let options = store
            .value(forKey: optionsKey) as? OptionStoreRepresentation
        else {
            return OptionStoreRepresentation()
        }
        return options
    }

    private func save(_ option: OptionRepresentation) {
        save([option])
    }

    /// Save the provided rules
    /// Will only override the options in the params
    private func save(_ options: [OptionRepresentation]) {
        var savedOptions = load()
        options.forEach { savedOptions[$0.id] = $0.arg }
        save(savedOptions)
    }

    /// Will replace the options with the param
    private func save(_ options: OptionStoreRepresentation) {
        store.set(options, forKey: optionsKey)
    }
}
