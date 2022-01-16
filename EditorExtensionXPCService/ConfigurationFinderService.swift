//
//  ConfigurationFinderService.swift
//  EditorExtensionXPCService
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import AppKit
import Foundation

@objc class ConfigurationFinderService: NSObject, ConfigurationFinderServiceProtocol {
    enum Error: Swift.Error {
        case failedToFetchXcodeFilePath
        case failedToFindConfigurationFile
        case failedToParseConfigurationFile
        case noAccessToAccessibilityAPI
    }

    func findConfiguration(withReply reply: @escaping ([String: String]?) -> Void) {
        do {
            let frontMostFileURL = try getXcodeFrontWindowFileURL()
            let configurationData = try findConfigurationFile(for: frontMostFileURL)
            let configuration = try parseConfigFile(configurationData)
            reply(configuration)
        } catch {
            reply(nil)
        }
    }

    func getXcodeFrontWindowFileURL() throws -> URL {
        let activeXcodes = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Xcode")
            .filter(\.isActive)

        // fetch file path of the frontmost window of Xcode through Accessability API.
        for xcode in activeXcodes {
            let application = AXUIElementCreateApplication(xcode.processIdentifier)
            do {
                let frontmostWindow = try application.copyValue(key: kAXFocusedWindowAttribute, ofType: AXUIElement.self)
                let path = try frontmostWindow.copyValue(key: kAXDocumentAttribute, ofType: String.self)
                return URL(fileURLWithPath: path)
            } catch {
                if let axError = error as? AXError, axError == .apiDisabled {
                    throw Error.noAccessToAccessibilityAPI
                }
            }
        }

        throw Error.failedToFetchXcodeFilePath
    }

    func findConfigurationFile(for fileURL: URL) throws -> Data {
        var directoryURL = fileURL

        while !directoryURL.pathComponents.contains("..") {
            defer { directoryURL.deleteLastPathComponent() }
            let fileURL = directoryURL.appendingPathComponent(swiftFormatConfigurationFile, isDirectory: false)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return try Data(contentsOf: fileURL)
            }
        }

        throw Error.failedToFindConfigurationFile
    }
}

extension AXError: Error {}

extension AXUIElement {
    func copyValue<T>(key: String, ofType _: T.Type = T.self) throws -> T {
        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(self, key as CFString, &value)
        if error == .success, let value = value as? T {
            return value
        }
        throw error
    }
}
