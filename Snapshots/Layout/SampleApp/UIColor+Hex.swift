//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

public extension UIColor {
    convenience init?(hexString: String) {
        if hexString.hasPrefix("#") {
            var string = String(hexString.dropFirst())
            switch string.count {
            case 3:
                string += "f"
                fallthrough
            case 4:
                let chars = Array(string)
                let red = chars[0]
                let green = chars[1]
                let blue = chars[2]
                let alpha = chars[3]
                string = "\(red)\(red)\(green)\(green)\(blue)\(blue)\(alpha)\(alpha)"
            case 6:
                string += "ff"
            case 8:
                break
            default:
                return nil
            }
            if let rgba = Double("0x" + string).flatMap({ UInt32(exactly: $0) }) {
                let red = CGFloat((rgba & 0xFF00_0000) >> 24) / 255
                let green = CGFloat((rgba & 0x00FF_0000) >> 16) / 255
                let blue = CGFloat((rgba & 0x0000_FF00) >> 8) / 255
                let alpha = CGFloat((rgba & 0x0000_00FF) >> 0) / 255
                self.init(red: red, green: green, blue: blue, alpha: alpha)
                return
            }
        }
        return nil
    }
}
