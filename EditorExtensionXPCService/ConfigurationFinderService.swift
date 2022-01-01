//
//  ConfigurationFinderService.swift
//  EditorExtensionXPCService
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Foundation

@objc class ConfigurationFinderService: NSObject, ConfigurationFinderServiceProtocol {
    enum Error: Swift.Error {
        case failedToFetchXcodeFilePath
        case failedToFindConfigurationFile
        case failedToParseConfigurationFile
    }
    
    func findConfiguration(withReply reply: @escaping ([String: String]?) -> Void) {
        getXcodeFrontWindowFileURL { result in
            switch result {
            case let .success(frontMostFileURL):
                do {
                    let configurationData = try self.findConfigurationFile(for: frontMostFileURL)
                    let configuration = try parseConfigFile(configurationData)
                    reply(configuration)
                } catch {
                    print(error)
                    reply(nil)
                }
            case let .failure(error):
                print(error)
                reply(nil)
            }
        }
    }
    
    func getXcodeFrontWindowFileURL(onComplete: @escaping (Result<URL, Swift.Error>) -> Void) {
        // usually returns the path to xcodeproj, xcworkspace or project root
        let appleScript = """
        tell application "Xcode"
            return path of document of the first window
        end tell
        """
        
        // NSAppleScript is not used because it hangs the service when execute
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", appleScript]
        let outpipe = Pipe()
        task.standardOutput = outpipe
        task.terminationHandler = { task in
            do {
                if let data = try readToEnd(outpipe), let path = String(data: data, encoding: .utf8) {
                    let trimmedNewLine = path.trimmingCharacters(in: .newlines)
                    return onComplete(.success(URL(fileURLWithPath: trimmedNewLine)))
                }
                throw Error.failedToFetchXcodeFilePath
            } catch {
                return onComplete(.failure(error))
            }
        }
        
        do {
            try task.run()
        } catch {
            return onComplete(.failure(error))
        }
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

func readToEnd(_ pipe: Pipe) throws -> Data? {
    if #available(macOS 10.15.4, *) {
        return try pipe.fileHandleForReading.readToEnd()
    } else {
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
}
