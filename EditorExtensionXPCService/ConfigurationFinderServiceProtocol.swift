//
//  ConfigurationFinderServiceProtocol.swift
//  EditorExtensionXPCService
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Foundation

@objc(ConfigurationFinderServiceProtocol) protocol ConfigurationFinderServiceProtocol {
    /// Find the configuration file for the currently opening Xcode project if possible.
    /// Returns the parsed configuration file if found.
    func findConfiguration(withReply reply: @escaping ([String: String]?) -> Void)
}
