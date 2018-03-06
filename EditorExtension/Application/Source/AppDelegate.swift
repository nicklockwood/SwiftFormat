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

struct Version: Codable {
    let version: Int
}

struct SwiftFormatXcodeConfiguration: Codable {
    static let fileExtension = "sfxx" //  TODO: Define the official extension

    let version: Int
    let rules: [Rule]
    let options: [SavedOption]
}

enum XcodeConfigurationError: Error, CustomStringConvertible, EnumAssociatable {
    case writing(String)
    case reading(String)
    case parsing(String)

    var description: String {
        let message: String = associatedValue()
        return message
    }

    var localizedDescription: String {
        return description
    }
}

extension NSNotification.Name {
    static let ApplicationDidLoadNewConfiguration = NSNotification.Name("ApplicationDidLoadNewConfiguration")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow? {
        return NSApp.mainWindow
    }

    @objc
    @IBAction func resetToDefault(_: NSMenuItem) {
        RulesStore().resetRulesToDefaults()
        OptionsStore().resetOptionsToDefaults()
        NotificationCenter.default.post(name: .ApplicationDidLoadNewConfiguration, object: nil)
    }

    @objc
    @IBAction func openConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let dialog = NSOpenPanel()
        dialog.title = "Choose a configuration file"
        dialog.showsResizeIndicator = true
        dialog.allowedFileTypes = [SwiftFormatXcodeConfiguration.fileExtension]
        dialog.allowsMultipleSelection = false

        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url else {
                return
            }

            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch let error {
                self.showError(XcodeConfigurationError.reading("Problem while reading the file \(url). [\(error)]"))
                return
            }

            let decoder = JSONDecoder()
            do {
                let version = try decoder.decode(Version.self, from: data)
                if version.version != 1 {
                    throw XcodeConfigurationError.parsing("Unsupported version number: \(version.version)")
                }
                let configuration = try decoder.decode(SwiftFormatXcodeConfiguration.self, from: data)
                RulesStore().restore(configuration.rules)
                OptionsStore().restore(configuration.options)

                NotificationCenter.default.post(name: .ApplicationDidLoadNewConfiguration, object: nil)
            } catch let error as XcodeConfigurationError {
                self.showError(error)
            } catch let error {
                self.showError(XcodeConfigurationError.parsing("Problem while decoding file: \(url). [\(error)]"))
            }
        }
    }

    @objc
    @IBAction func saveConfiguration(_: NSMenuItem) {
        guard let window = window else {
            return
        }

        let conf = SwiftFormatXcodeConfiguration(version: 1,
                                                 rules: RulesStore().rules,
                                                 options: OptionsStore().options)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let dataToWrite: Data
        do {
            dataToWrite = try encoder.encode(conf)
        } catch let error {
            self.showError(XcodeConfigurationError.writing("Problem while encoding configuration data. [\(error)]"))
            return
        }

        let dialog = NSSavePanel()
        dialog.title = "Export Configuration"
        dialog.nameFieldStringValue = "name.\(SwiftFormatXcodeConfiguration.fileExtension)"
        dialog.beginSheetModal(for: window) { response in
            guard response == .OK, let url = dialog.url else {
                return
            }
            do {
                try dataToWrite.write(to: url)
            } catch let error {
                self.showError(XcodeConfigurationError.writing("Problem while writing configuration to url: \(url). [\(error)]"))
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
