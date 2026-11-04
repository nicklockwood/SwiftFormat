//
//  NumberFormatting.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 1/17/17.
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
        options: ["decimal-grouping", "binary-grouping", "octal-grouping", "hex-grouping",
                  "fraction-grouping", "exponent-grouping", "hex-literal-case", "exponent-case"]
    ) { formatter in
        let availabilityRanges = formatter.availabilityArgumentRanges()
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
            // Versions in availability attributes, like `@available(iOS, deprecated: 100000)`, can't contain `_`
            let updatedToken = Token.number(result, type)
            guard updatedToken != token, !availabilityRanges.contains(where: { $0.contains(i) }) else { return }
            formatter.replaceToken(at: i, with: updatedToken)
        }
    } examples: {
        """
        ```diff
        - let color = 0xFF77A5
        + let color = 0xff77a5
        ```

        ```diff
        - let big = 123456.123
        + let big = 123_456.123
        ```
        """
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

    /// The ranges of the arguments of availability attributes and conditions, like `@available(...)`
    func availabilityArgumentRanges() -> [ClosedRange<Int>] {
        let availabilityKeywords: [Token] = [
            .keyword("@available"), .keyword("@backDeployed"), .keyword("@_backDeploy"),
            .keyword("@_originallyDefinedIn"), .keyword("@_spi_available"), .keyword("@_specialize"),
            .keyword("#available"), .keyword("#unavailable"),
        ]
        var ranges = [ClosedRange<Int>]()
        forEach(.startOfScope("(")) { i, _ in
            guard let prevIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i),
                  availabilityKeywords.contains(tokens[prevIndex]),
                  let endOfScope = endOfScope(at: i)
            else { return }
            ranges.append(i ... endOfScope)
        }
        return ranges
    }
}
