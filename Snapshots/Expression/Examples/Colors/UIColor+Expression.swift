//
//  UIColor+Expression.swift
//  Colors
//
//  Created by Nick Lockwood on 30/09/2016.
//  Copyright © 2016 Nick Lockwood. All rights reserved.
//

import Expression
import UIKit

private let colors: [String: UIColor] = [
    "red": .red,
    "green": .green,
    "blue": .blue,
    "yellow": .yellow,
    "purple": .purple,
    "cyan": .cyan,
    "pink": UIColor(rgba: 0xFF7F7FFF),
    "orange": .orange,
    "gray": .gray,
    "black": .black,
    "white": .white,
]

private let functions: [AnyExpression.Symbol: AnyExpression.SymbolEvaluator] = [
    .function("rgb", arity: 3): { args in
        guard let r = args[0] as? Double,
              let g = args[1] as? Double,
              let b = args[2] as? Double
        else {
            throw AnyExpression.Error.message("Type mismatch")
        }
        return UIColor(
            red: CGFloat(r / 255),
            green: CGFloat(g / 255),
            blue: CGFloat(b / 255),
            alpha: 1
        )
    },
    .function("rgba", arity: 4): { args in
        guard let r = args[0] as? Double,
              let g = args[1] as? Double,
              let b = args[2] as? Double,
              let a = args[3] as? Double
        else {
            throw Expression.Error.message("Type mismatch")
        }
        return UIColor(
            red: CGFloat(r / 255),
            green: CGFloat(g / 255),
            blue: CGFloat(b / 255),
            alpha: CGFloat(a)
        )
    },
]

public extension UIColor {
    convenience init(rgba: UInt32) {
        let red = CGFloat((rgba & 0xFF000000) >> 24) / 255
        let green = CGFloat((rgba & 0x00FF0000) >> 16) / 255
        let blue = CGFloat((rgba & 0x0000FF00) >> 8) / 255
        let alpha = CGFloat((rgba & 0x000000FF) >> 0) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(expression: String) throws {
        let parsedExpression = Expression.parse(expression)
        var constants = [String: Any]()

        for symbol in parsedExpression.symbols {
            if case let .variable(name) = symbol {
                if name.hasPrefix("#") {
                    var string = String(name.dropFirst())
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
                        // unsupported format
                        continue
                    }
                    guard let rgba = Double("0x" + string).flatMap({ UInt32(exactly: $0) }) else {
                        throw Expression.Error.message("Unsupported color format")
                    }
                    constants[name] = UIColor(rgba: rgba)
                } else if let color = colors[name.lowercased()] {
                    constants[name] = color
                }
            }
        }
        let expression = AnyExpression(
            expression,
            constants: constants,
            symbols: functions
        )
        let color: UIColor = try expression.evaluate()
        self.init(cgColor: color.cgColor)
    }
}
