//
//  ProjectConfigurationFinder.swift
//  Editor Extension
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Foundation

private let connection: NSXPCConnection = {
    let connection = NSXPCConnection(
        serviceName: "com.charcoaldesign.SwiftFormat-for-Xcode.EditorExtensionXPCService"
    )
    connection.remoteObjectInterface =
        NSXPCInterface(with: ConfigurationFinderServiceProtocol.self)
    connection.resume()
    return connection
}()

struct ProjectConfigurationFinder {
    func findProjectOptions(onCompletion: @escaping (Options?) -> Void) {
        let service = connection.remoteObjectProxyWithErrorHandler { _ in } as! ConfigurationFinderServiceProtocol
        service.findConfiguration {
            if let c = $0, let options = try? Options(c, in: "") {
                return onCompletion(options)
            }

            return onCompletion(nil)
        }
    }
}
