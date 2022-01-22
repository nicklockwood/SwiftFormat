//
//  main.swift
//  EditorExtensionXPCService
//
//  Created by Shangxin Guo on 2022/1/1.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Foundation

let listener = NSXPCListener.service()
let delegate = ServiceDelegate()
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
