//
//  NumberFormatting.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Standardize formatting of numeric literals
    static let numberFormatting = FormatRule(
        help: """
        Use consistent grouping for numeric literals. Groups will be separated by `_`
        delimiters to improve readability. For each numeric type you can specify a group
        size (the number of digits in each group) and a threshold (the minimum number of
        digits in a number before grouping is applied).
        """,
        options: ["decimalgrouping", "binarygrouping", "octalgrouping", "hexgrouping",
                  "fractiongrouping", "exponentgrouping", "hexliteralcase", "exponentcase"]
    ) { formatter in
        formatter.forEachToken { i, token in
            guard case let .number(number, type) = token else {
                return
            }
            let grouping: Grouping
            let prefix: String, exponentSeparator: String, parts: [String]
            switch type {
            case .integer, .decimal:
                grouping = formatter.options.decimalGrouping
                prefix = ""
                exponentSeparator = formatter.options.uppercaseExponent ? "E" : "e"
                parts = number.components(separatedBy: CharacterSet(charactersIn: ".eE"))
            case .binary:
                grouping = formatter.options.binaryGrouping
                prefix = "0b"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .octal:
                grouping = formatter.options.octalGrouping
                prefix = "0o"
                exponentSeparator = ""
                parts = [String(number[prefix.endIndex...])]
            case .hex:
                grouping = formatter.options.hexGrouping
                prefix = "0x"
                exponentSeparator = formatter.options.uppercaseExponent ? "P" : "p"
                parts = number[prefix.endIndex...].components(separatedBy: CharacterSet(charactersIn: ".pP")).map {
                    formatter.options.uppercaseHex ? $0.uppercased() : $0.lowercased()
                }
            }
            var main = parts[0], fraction = "", exponent = ""
            switch parts.count {
            case 2 where number.contains("."):
                fraction = parts[1]
            case 2:
                exponent = parts[1]
            case 3:
                fraction = parts[1]
                exponent = parts[2]
            default:
                break
            }
            formatter.applyGrouping(grouping, to: &main)
            if formatter.options.fractionGrouping {
                formatter.applyGrouping(grouping, to: &fraction)
            }
            if formatter.options.exponentGrouping {
                formatter.applyGrouping(grouping, to: &exponent)
            }
            var result = prefix + main
            if !fraction.isEmpty {
                result += "." + fraction
            }
            if !exponent.isEmpty {
                result += exponentSeparator + exponent
            }
            formatter.replaceToken(at: i, with: .number(result, type))
        }
    }
}

extension Formatter {
    func applyGrouping(_ grouping: Grouping, to number: inout String) {
        switch grouping {
        case .none, .group:
            number = number.replacingOccurrences(of: "_", with: "")
        case .ignore:
            return
        }
        guard case let .group(group, threshold) = grouping, group > 0, number.count >= threshold else {
            return
        }
        var output = Substring()
        var index = number.endIndex
        var count = 0
        repeat {
            index = number.index(before: index)
            if count > 0, count % group == 0 {
                output.insert("_", at: output.startIndex)
            }
            count += 1
            output.insert(number[index], at: output.startIndex)
        } while index != number.startIndex
        number = String(output)
    }
}
