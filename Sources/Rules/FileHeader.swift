//
//  FileHeader.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 3/7/17.
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
               !formatter.tokens[lastHeaderTokenIndex + 1 ... lastHeaderTokenIndex + 2].allSatisfy(\.isLinebreak)
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
    } examples: {
        """
        You can use the following tokens in the text:

        Token | Description
        --- | ---
        `{file}` | File name
        `{year}` | Current year
        `{created}` | File creation date
        `{created.year}` | File creation year
        `{author}` | Name and email of the user who first committed the file
        `{author.name}` | Name of the user who first committed the file
        `{author.email}` | Email of the user who first committed the file

        **Example**:

        `--header \\n {file}\\n\\n Copyright © {created.year} {author.name}.\\n`

        ```diff
        - // SomeFile.swift

        + //
        + //  SomeFile.swift
        + //  Copyright © 2023 Tim Apple.
        + //
        ```

        You can use the following built-in formats for `--dateformat`:

        Token | Description
        --- | ---
        system | Use the local system locale
        iso | ISO 8601 (yyyy-MM-dd)
        dmy | Date/Month/Year (dd/MM/yyyy)
        mdy | Month/Day/Year (MM/dd/yyyy)

        Custom formats are defined using
        [Unicode symbols](https://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Field_Symbol_Table).

        `--dateformat iso`

        ```diff
        - // Created {created}
        + // Created 2023-08-10
        ```

        `--dateformat dmy`

        ```diff
        - // Created {created}
        + // Created 10/08/2023
        ```

        `--dateformat mdy`

        ```diff
        - // Created {created}
        + // Created 08/10/2023
        ```

        `--dateformat 'yyyy.MM.dd.HH.mm'`

        ```diff
        - // Created {created}
        + // Created 2023.08.10.11.00
        ```

        Setting a time zone enforces consistent date formatting across environments
        around the world. By default the local system locale is used and for convenience
        `gmt` and `utc` can be used. The time zone can be further customized by
        setting it to a abbreviation/time zone identifier supported by the Swift
        standard library.

        `--dateformat 'yyyy-MM-dd HH:mm ZZZZ' --timezone utc`

        ```diff
        - // Created {created}
        + // Created 2023-08-10 11:00 GMT
        ```

        `--dateformat 'yyyy-MM-dd HH:mm ZZZZ' --timezone Pacific/Fiji`

        ```diff
        - // Created 2023-08-10 11:00 GMT
        + // Created 2023-08-10 23:00 GMT+12:00
        ```
        """
    }
}
