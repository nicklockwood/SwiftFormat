//
//  AppDelegate.swift
//  SwiftFormat for Xcode
//
//  Created by Tony Arnold on 5/10/16.
//  Copyright 2016 Nick Lockwood
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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow? {
        return NSApp.mainWindow
    }

    @objc
    @IBAction func resetToDefault(_: NSMenuItem) {
        RulesStore().resetRulesToDefaults()
        OptionsStore().resetOptionsToDefaults()
        NotificationCenter.default.post(name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @objc
    @IBAction func openConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let dialog = NSOpenPanel()
        dialog.title = "Choose a configuration file"
        dialog.showsResizeIndicator = true
        dialog.allowedFileTypes = [swiftFormatFileExtension]
        dialog.allowsMultipleSelection = false

        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url else {
                return
            }

            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch let error {
                self.showError(FormatError.reading("problem reading configuration from \(url.path). [\(error)]"))
                return
            }

            let configuration: SwiftFormatCLIArgumentsFile
            do {
                configuration = try SwiftFormatCLIArgumentsFile.decoded(data)
            } catch let error {
                self.showError(error)
                return
            }

            RulesStore().restore(configuration.rules)
            if let options = configuration.options {
                OptionsStore().inferOptions = false
                OptionsStore().restore(options)
            } else {
                OptionsStore().inferOptions = true
            }

            NotificationCenter.default.post(name: .applicationDidLoadNewConfiguration, object: nil)
        }
    }

    @objc
    @IBAction func saveConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let dialog = NSSavePanel()
        dialog.title = "Export Configuration"
        dialog.nameFieldStringValue = ".\(swiftFormatFileExtension)"
        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url else {
                return
            }

            let optionsStore = OptionsStore()
            let options = optionsStore.inferOptions ? nil : optionsStore.formatOptions
            let formatFile = SwiftFormatCLIArgumentsFile(rules: RulesStore().rules, options: options)
            let data = formatFile.encoded()

            do {
                try data.write(to: url)
            } catch let error {
                self.showError(FormatError.writing("problem writing configuration to \(url.path). [\(error)]"))
            }
        }
    }

    private func showError(_ error: Error) {
        guard let window = window else {
            return
        }

        let alert = NSAlert(error: error)
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.beginSheetModal(for: window)
    }
}

extension NSNotification.Name {
    static let applicationDidLoadNewConfiguration = NSNotification.Name("ApplicationDidLoadNewConfiguration")
}
