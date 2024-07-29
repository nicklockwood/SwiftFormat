//
//  FileHeader.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Strip header comments from the file
    static let fileHeader = FormatRule(
        help: "Use specified source file header template for all files.",
        runOnceOnly: true,
        options: ["header", "dateformat", "timezone"],
        sharedOptions: ["linebreaks"]
    ) { formatter in
        var headerTokens = [Token]()
        var directives = [String]()
        switch formatter.options.fileHeader {
        case .ignore:
            return
        case var .replace(string):
            let file = formatter.options.fileInfo
            let options = ReplacementOptions(
                dateFormat: formatter.options.dateFormat,
                timeZone: formatter.options.timeZone
            )

            for (key, replacement) in formatter.options.fileInfo.replacements {
                if let replacementStr = replacement.resolve(file, options) {
                    while let range = string.range(of: "{\(key.rawValue)}") {
                        string.replaceSubrange(range, with: replacementStr)
                    }
                }
            }
            headerTokens = tokenize(string)
            directives = headerTokens.compactMap {
                guard case let .commentBody(body) = $0 else {
                    return nil
                }
                return body.commentDirective
            }
        }

        guard let headerRange = formatter.headerCommentTokenRange(includingDirectives: directives) else {
            return
        }

        if headerTokens.isEmpty {
            formatter.removeTokens(in: headerRange)
            return
        }

        var lastHeaderTokenIndex = headerRange.endIndex - 1
        let endIndex = lastHeaderTokenIndex + headerTokens.count
        if formatter.tokens.endIndex > endIndex, headerTokens == Array(formatter.tokens[
            lastHeaderTokenIndex + 1 ... endIndex
        ]) {
            lastHeaderTokenIndex += headerTokens.count
        }
        let headerLinebreaks = headerTokens.reduce(0) { result, token -> Int in
            result + (token.isLinebreak ? 1 : 0)
        }
        if lastHeaderTokenIndex < formatter.tokens.count - 1 {
            headerTokens.append(.linebreak(formatter.options.linebreak, headerLinebreaks + 1))
            if lastHeaderTokenIndex < formatter.tokens.count - 2,
               !formatter.tokens[lastHeaderTokenIndex + 1 ... lastHeaderTokenIndex + 2].allSatisfy({
                   $0.isLinebreak
               })
            {
                headerTokens.append(.linebreak(formatter.options.linebreak, headerLinebreaks + 2))
            }
        }
        if let index = formatter.index(of: .nonSpace, after: lastHeaderTokenIndex, if: {
            $0.isLinebreak
        }) {
            lastHeaderTokenIndex = index
        }
        formatter.replaceTokens(in: headerRange.startIndex ..< lastHeaderTokenIndex + 1, with: headerTokens)
    }
}
