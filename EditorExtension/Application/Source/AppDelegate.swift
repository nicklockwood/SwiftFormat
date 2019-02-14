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

    func loadConfiguration(_ url: URL) -> Bool {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            showError(FormatError.reading("problem reading configuration from \(url.path). [\(error)]"))
            return false
        }

        let options: Options
        do {
            let args = try parseConfigFile(data)
            options = try Options(args, in: url.deletingLastPathComponent().path)
        } catch {
            showError(error)
            return false
        }

        let rules = options.rules ?? allRules.subtracting(FormatRules.disabledByDefault)
        RulesStore().restore(Set(FormatRules.byName.keys).map {
            Rule(name: $0, isEnabled: rules.contains($0))
        })
        if let formatOptions = options.formatOptions {
            OptionsStore().inferOptions = false
            OptionsStore().restore(formatOptions)
        } else {
            OptionsStore().inferOptions = true
        }
        return true
    }

    func application(_: NSApplication, openFile file: String) -> Bool {
        let url = URL(fileURLWithPath: file)
        if loadConfiguration(url) {
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            NotificationCenter.default.post(name: .applicationDidLoadNewConfiguration, object: nil)
            return true
        }
        return false
    }

    @IBAction func resetToDefault(_: NSMenuItem) {
        UserDefaults(suiteName: UserDefaults.groupDomain)?.clearAll(in: UserDefaults.groupDomain)
        RulesStore().resetRulesToDefaults()
        OptionsStore().resetOptionsToDefaults()
        NotificationCenter.default.post(name: .applicationDidLoadNewConfiguration, object: nil)
    }

    @IBAction func openConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let dialog = NSOpenPanel()
        dialog.title = "Choose a configuration file"
        dialog.delegate = self
        dialog.showsHiddenFiles = true
        dialog.showsResizeIndicator = true
        dialog.allowsMultipleSelection = false

        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url, self.loadConfiguration(url) else {
                return
            }
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            NotificationCenter.default.post(name: .applicationDidLoadNewConfiguration, object: nil)
        }
    }

    @IBAction func saveConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let dialog = NSSavePanel()
        dialog.title = "Export Configuration"
        dialog.showsHiddenFiles = true
        dialog.nameFieldStringValue = swiftFormatConfigurationFile
        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url else {
                return
            }

            let optionsStore = OptionsStore()
            let formatOptions = optionsStore.inferOptions ? nil : optionsStore.formatOptions
            let rules = RulesStore().rules.compactMap { $0.isEnabled ? $0.name : nil }
            let config = serialize(options: Options(formatOptions: formatOptions, rules: Set(rules))) + "\n"
            do {
                try config.write(to: url, atomically: true, encoding: .utf8)
            } catch {
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

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate: NSOpenSavePanelDelegate {
    func panel(_: Any, shouldEnable url: URL) -> Bool {
        return url.hasDirectoryPath ||
            url.pathExtension == swiftFormatConfigurationFile.dropFirst() ||
            url.lastPathComponent == swiftFormatConfigurationFile
    }
}

extension NSNotification.Name {
    static let applicationDidLoadNewConfiguration = NSNotification.Name("ApplicationDidLoadNewConfiguration")
}
