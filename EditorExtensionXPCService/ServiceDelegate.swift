//
//  ServiceDelegate.swift
//  EditorExtensionXPCService
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Foundation

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(
        _: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(
            with: ConfigurationFinderServiceProtocol.self
        )

        let exportedObject = ConfigurationFinderService()
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
