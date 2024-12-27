//
//  DeclarationV1.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/20/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

// MARK: - Declaration

/// A declaration, like a property, function, or type.
/// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/declarations/
///
/// Forms a tree of declarations, since `type` declarations have a body
/// that contains child declarations.
enum Declaration: Hashable {
    /// A type-like declaration with body of additional declarations (`class`, `struct`, etc)
    indirect case type(
        kind: String,
        open: [Token],
        body: [Declaration],
        close: [Token],
        originalRange: ClosedRange<Int>
    )

    /// A simple declaration (like a property or function)
    case declaration(
        kind: String,
        tokens: [Token],
        originalRange: ClosedRange<Int>
    )

    /// A #if ... #endif conditional compilation block with a body of additional declarations
    indirect case conditionalCompilation(
        open: [Token],
        body: [Declaration],
        close: [Token],
        originalRange: ClosedRange<Int>
    )

    /// The tokens in this declaration
    var tokens: [Token] {
        switch self {
        case let .declaration(_, tokens, _):
            return tokens
        case let .type(_, openTokens, bodyDeclarations, closeTokens, _),
             let .conditionalCompilation(openTokens, bodyDeclarations, closeTokens, _):
            return openTokens + bodyDeclarations.flatMap(\.tokens) + closeTokens
        }
    }

    /// The opening tokens of the declaration (before the body)
    var openTokens: [Token] {
        switch self {
        case .declaration:
            return tokens
        case let .type(_, open, _, _, _),
             let .conditionalCompilation(open, _, _, _):
            return open
        }
    }

    /// The body of this declaration, if applicable
    var body: [Declaration]? {
        switch self {
        case .declaration:
            return nil
        case let .type(_, _, body, _, _),
             let .conditionalCompilation(_, body, _, _):
            return body
        }
    }

    /// The closing tokens of the declaration (after the body)
    var closeTokens: [Token] {
        switch self {
        case .declaration:
            return []
        case let .type(_, _, _, close, _),
             let .conditionalCompilation(_, _, close, _):
            return close
        }
    }

    /// The keyword that determines the specific type of declaration that this is
    /// (`class`, `func`, `let`, `var`, etc.)
    var keyword: String {
        switch self {
        case let .declaration(kind, _, _),
             let .type(kind, _, _, _, _):
            return kind
        case .conditionalCompilation:
            return "#if"
        }
    }

    /// Whether or not this declaration defines a type (a class, enum, etc, but not an extension)
    var definesType: Bool {
        var typeKeywords = Token.swiftTypeKeywords
        typeKeywords.remove("extension")
        return typeKeywords.contains(keyword)
    }

    /// Whether or not this is a simple `declaration` (not a `type` or `conditionalCompilation`)
    var isSimpleDeclaration: Bool {
        switch self {
        case .declaration:
            return true
        case .type, .conditionalCompilation:
            return false
        }
    }

    /// The name of this type or variable
    var name: String? {
        let parser = Formatter(openTokens)
        guard let keywordIndex = openTokens.firstIndex(of: .keyword(keyword)) else { return nil }
        return parser.declarationName(keywordIndex: keywordIndex)
    }

    /// The original range of the tokens of this declaration in the original source file
    var originalRange: ClosedRange<Int> {
        switch self {
        case let .type(_, _, _, _, originalRange),
             let .declaration(_, _, originalRange),
             let .conditionalCompilation(_, _, _, originalRange):
            return originalRange
        }
    }

    var modifiers: [String] {
        let parser = Formatter(openTokens)
        guard let keywordIndex = parser.index(of: .keyword(keyword), after: 0) else {
            return []
        }

        var allModifiers = [String]()
        _ = parser.modifiersForDeclaration(at: keywordIndex, contains: { _, modifier in
            allModifiers.append(modifier)
            return false
        })
        return allModifiers
    }

    /// Whether or not this declaration represents a stored instance property
    var isStoredInstanceProperty: Bool {
        // A static property is not an instance property
        !modifiers.contains("static") && isStoredProperty
    }

    /// Whether or not this declaration represents a static stored instance property
    var isStaticStoredProperty: Bool {
        modifiers.contains("static") && isStoredProperty
    }

    var isStoredProperty: Bool {
        guard keyword == "let" || keyword == "var" else { return false }

        let formatter = Formatter(tokens)
        guard let keywordIndex = formatter.index(of: .keyword(keyword), after: -1) else { return false }
        return formatter.isStoredProperty(atIntroducerIndex: keywordIndex)
    }

    /// The original index of this declaration's primary keyword in the given formatter
    func originalKeywordIndex(in formatter: Formatter) -> Int? {
        formatter.index(of: .keyword(keyword), after: originalRange.lowerBound - 1)
    }

    /// Computes the fully qualified name of this declaration, given the array of parent declarations.
    func fullyQualifiedName(parentDeclarations: [Declaration]) -> String? {
        guard let name = name else { return nil }
        let typeNames = parentDeclarations.compactMap(\.name) + [name]
        return typeNames.joined(separator: ".")
    }
}

extension Formatter {
    /// Parses all of the declarations in the file
    func parseDeclarationsV2() -> [DeclarationV2] {
        parseDeclarations().compactMap { v1Declaration in
            v1Declaration.makeDeclarationV2(formatter: self)
        }
    }

    /// Parses all of the declarations in the file
    func parseDeclarations() -> [Declaration] {
        guard !tokens.isEmpty else { return [] }
        return parseDeclarations(in: ClosedRange(0 ..< tokens.count))
    }

    /// Parses the declarations in the given range.
    func parseDeclarations(in range: ClosedRange<Int>) -> [Declaration] {
        var declarations = [Declaration]()
        var startOfDeclaration = range.lowerBound
        forEachToken(onlyWhereEnabled: false) { i, token in
            guard range.contains(i),
                  i >= startOfDeclaration,
                  token.isDeclarationTypeKeyword || token == .startOfScope("#if")
            else {
                return
            }

            let declarationKeyword = declarationType(at: i) ?? "#if"
            let endOfDeclaration = self.endOfDeclaration(atDeclarationKeyword: i, fallBackToEndOfScope: false)

            let declarationRange = startOfDeclaration ... min(endOfDeclaration ?? .max, range.upperBound)
            startOfDeclaration = declarationRange.upperBound + 1

            declarations.append(.declaration(
                kind: isEnabled ? declarationKeyword : "",
                tokens: Array(tokens[declarationRange]),
                originalRange: declarationRange
            ))
        }
        if startOfDeclaration < range.upperBound {
            let declarationRange = startOfDeclaration ... range.upperBound
            declarations.append(.declaration(
                kind: "",
                tokens: Array(tokens[declarationRange]),
                originalRange: declarationRange
            ))
        }

        return declarations.map { declaration in
            // Parses this declaration into a body of declarations separate from the start and end tokens
            func parseBody(in bodyRange: Range<Int>) -> (start: [Token], body: [Declaration], end: [Token]) {
                var startTokens = Array(tokens[declaration.originalRange.lowerBound ..< bodyRange.lowerBound])
                var endTokens = Array(tokens[bodyRange.upperBound ... declaration.originalRange.upperBound])

                guard !bodyRange.isEmpty else {
                    return (start: startTokens, body: [], end: endTokens)
                }

                var bodyRange = ClosedRange(bodyRange)

                // Move the leading newlines from the `body` into the `start` tokens
                // so the first body token is the start of the first declaration
                while tokens[bodyRange].first?.isLinebreak == true {
                    startTokens.append(tokens[bodyRange.lowerBound])

                    if bodyRange.count > 1 {
                        bodyRange = (bodyRange.lowerBound + 1) ... bodyRange.upperBound
                    } else {
                        // If this was the last remaining token in the body, just return now.
                        // We can't have an empty `bodyRange`.
                        return (start: startTokens, body: [], end: endTokens)
                    }
                }

                // Move the closing brace's indentation token from the `body` into the `end` tokens
                if tokens[bodyRange].last?.isSpace == true {
                    endTokens.insert(tokens[bodyRange.upperBound], at: endTokens.startIndex)

                    if bodyRange.count > 1 {
                        bodyRange = bodyRange.lowerBound ... (bodyRange.upperBound - 1)
                    } else {
                        // If this was the last remaining token in the body, just return now.
                        // We can't have an empty `bodyRange`.
                        return (start: startTokens, body: [], end: endTokens)
                    }
                }

                // Parse the inner body declarations of the type
                let bodyDeclarations = parseDeclarations(in: bodyRange)

                return (startTokens, bodyDeclarations, endTokens)
            }

            // If this declaration represents a type, we need to parse its inner declarations as well.
            let typelikeKeywords = ["class", "actor", "struct", "enum", "protocol", "extension"]

            if typelikeKeywords.contains(declaration.keyword),
               let declarationTypeKeywordIndex = index(
                   in: Range(declaration.originalRange),
                   where: { $0.string == declaration.keyword }
               ),
               let bodyOpenBrace = index(of: .startOfScope("{"), after: declarationTypeKeywordIndex),
               let bodyClosingBrace = endOfScope(at: bodyOpenBrace)
            {
                let bodyRange = (bodyOpenBrace + 1) ..< bodyClosingBrace
                let (startTokens, bodyDeclarations, endTokens) = parseBody(in: bodyRange)

                return .type(
                    kind: declaration.keyword,
                    open: startTokens,
                    body: bodyDeclarations,
                    close: endTokens,
                    originalRange: declaration.originalRange
                )
            }

            // If this declaration represents a conditional compilation block,
            // we also have to parse its inner declarations.
            else if declaration.keyword == "#if",
                    let declarationTypeKeywordIndex = index(
                        in: Range(declaration.originalRange),
                        where: { $0.string == "#if" }
                    ),
                    let endOfBody = endOfScope(at: declarationTypeKeywordIndex)
            {
                let startOfBody = endOfLine(at: declarationTypeKeywordIndex)
                let (startTokens, bodyDeclarations, endTokens) = parseBody(in: startOfBody ..< endOfBody)

                return .conditionalCompilation(
                    open: startTokens,
                    body: bodyDeclarations,
                    close: endTokens,
                    originalRange: declaration.originalRange
                )
            } else {
                return declaration
            }
        }
    }

    /// Returns the end index of the `Declaration` containing `declarationKeywordIndex`.
    ///  - `declarationKeywordIndex.isDeclarationTypeKeyword` must be `true`
    ///    (e.g. it must be a keyword like `let`, `var`, `func`, `class`, etc.
    ///  - Parameter `fallBackToEndOfScope`: whether or not to return the end of the current
    ///    scope if this is the last declaration in the current scope. If `false`,
    ///    returns `nil` if this declaration is not followed by some other declaration.
    func endOfDeclaration(
        atDeclarationKeyword declarationKeywordIndex: Int,
        fallBackToEndOfScope: Bool = true
    ) -> Int? {
        assert(tokens[declarationKeywordIndex].isDeclarationTypeKeyword
            || tokens[declarationKeywordIndex] == .startOfScope("#if"))

        // Get declaration keyword
        var searchIndex = declarationKeywordIndex
        let declarationKeyword = declarationType(at: declarationKeywordIndex) ?? "#if"
        switch tokens[declarationKeywordIndex] {
        case .startOfScope("#if"):
            // For conditional compilation blocks, the `declarationKeyword` _is_ the `startOfScope`
            // so we can immediately skip to the corresponding #endif
            if let endOfConditionalCompilationScope = endOfScope(at: declarationKeywordIndex) {
                searchIndex = endOfConditionalCompilationScope
            }
        case .keyword("class") where declarationKeyword != "class":
            // Most declarations will include exactly one token that `isDeclarationTypeKeyword` in
            //  - `class func` methods will have two (and the first one will be incorrect!)
            searchIndex = index(of: .keyword(declarationKeyword), after: declarationKeywordIndex) ?? searchIndex
        case .keyword("import"):
            // Symbol imports (like `import class Module.Type`) will have an extra `isDeclarationTypeKeyword`
            // immediately following their `declarationKeyword`, so we need to skip them.
            if let symbolTypeKeywordIndex = index(of: .nonSpaceOrComment, after: declarationKeywordIndex),
               tokens[symbolTypeKeywordIndex].isDeclarationTypeKeyword
            {
                searchIndex = symbolTypeKeywordIndex
            }
        case .keyword("protocol"), .keyword("struct"), .keyword("actor"),
             .keyword("enum"), .keyword("extension"):
            if let scopeStart = index(of: .startOfScope("{"), after: declarationKeywordIndex) {
                searchIndex = endOfScope(at: scopeStart) ?? searchIndex
            }
        default:
            break
        }

        // Search for the next declaration so we know where this declaration ends.
        let nextDeclarationKeywordIndex = index(after: searchIndex, where: {
            $0.isDeclarationTypeKeyword || $0 == .startOfScope("#if")
        })

        // Search backward from the next declaration keyword to find where declaration begins.
        var endOfDeclaration = nextDeclarationKeywordIndex.flatMap {
            index(before: startOfModifiers(at: $0, includingAttributes: true), where: {
                !$0.isSpaceOrCommentOrLinebreak
            }).map { endOfLine(at: $0) }
        }

        // Prefer keeping linebreaks at the end of a declaration's tokens,
        // instead of the start of the next delaration's tokens.
        //  - This includes any spaces on blank lines, but doesn't include the
        //    indentation associated with the next declaration.
        while let linebreakSearchIndex = endOfDeclaration,
              token(at: linebreakSearchIndex + 1)?.isSpaceOrLinebreak == true
        {
            // Only spaces between linebreaks (e.g. spaces on blank lines) are included
            if token(at: linebreakSearchIndex + 1)?.isSpace == true {
                guard token(at: linebreakSearchIndex)?.isLinebreak == true,
                      token(at: linebreakSearchIndex + 2)?.isLinebreak == true
                else { break }
            }

            endOfDeclaration = linebreakSearchIndex + 1
        }

        // If there was another declaration after this one in the same scope,
        // then we know this declaration ends before that one starts
        if let endOfDeclaration = endOfDeclaration {
            return endOfDeclaration
        }

        // Otherwise this is the last declaration in the scope.
        // To know where this declaration ends we just have to know where
        // the parent scope ends.
        //  - We don't do this inside `parseDeclarations` itself since it handles this cases
        if fallBackToEndOfScope,
           declarationKeywordIndex != 0,
           let endOfParentScope = endOfScope(at: declarationKeywordIndex - 1),
           let endOfDeclaration = index(of: .nonSpaceOrLinebreak, before: endOfParentScope)
        {
            return endOfDeclaration
        }

        return nil
    }
}

private extension Formatter {
    /// The open `{` for given property declaration's body, if present
    func startOfPropertyBody(at introducerIndex: Int, endOfPropertyIndex: Int) -> Int? {
        guard tokens[introducerIndex] == .keyword("let") || tokens[introducerIndex] == .keyword("var") else {
            return nil
        }

        // If there is a code block at the end of the declaration that is _not_ a closure,
        // then this declaration has a body.
        guard let lastClosingBraceIndex = index(of: .endOfScope("}"), before: endOfPropertyIndex),
              let lastOpeningBraceIndex = index(of: .startOfScope("{"), before: lastClosingBraceIndex),
              introducerIndex < lastOpeningBraceIndex,
              introducerIndex < lastClosingBraceIndex,
              !isStartOfClosure(at: lastOpeningBraceIndex)
        else { return nil }

        return lastOpeningBraceIndex
    }
}

// MARK: - Visibility

/// The visibility of a declaration
enum Visibility: String, CaseIterable, Comparable {
    case open
    case `public`
    case package
    case `internal`
    case `fileprivate`
    case `private`

    static func < (lhs: Visibility, rhs: Visibility) -> Bool {
        allCases.firstIndex(of: lhs)! > allCases.firstIndex(of: rhs)!
    }
}

extension Declaration {
    /// The explicit `Visibility` of this `Declaration`
    func visibility() -> Visibility? {
        switch self {
        case let .declaration(keyword, tokens, _), let .type(keyword, open: tokens, _, _, _):
            guard let keywordIndex = tokens.firstIndex(of: .keyword(keyword)) else {
                return nil
            }

            return Formatter(tokens).declarationVisibility(keywordIndex: keywordIndex)

        case let .conditionalCompilation(_, body, _, _):
            // Conditional compilation blocks themselves don't have a category or visbility-level,
            // but we still have to assign them a category for the sorting algorithm to function.
            // A reasonable heuristic here is to simply use the category of the first declaration
            // inside the conditional compilation block.
            if let firstDeclarationInBlock = body.first {
                return firstDeclarationInBlock.visibility()
            } else {
                return nil
            }
        }
    }

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func add(_ visibilityKeyword: Visibility) -> Declaration {
        mapOpeningTokens { openTokens in
            guard let indexOfKeyword = openTokens.firstIndex(of: .keyword(keyword)) else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            openTokensFormatter.addDeclarationVisibility(visibilityKeyword, declarationKeywordIndex: indexOfKeyword)
            return openTokensFormatter.tokens
        }
    }

    /// Removes the given visibility keyword from the given declaration
    func remove(_ visibilityKeyword: Visibility) -> Declaration {
        mapOpeningTokens { openTokens in
            guard let indexOfKeyword = openTokens.firstIndex(of: .keyword(keyword)) else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            openTokensFormatter.removeDeclarationVisibility(visibilityKeyword, declarationKeywordIndex: indexOfKeyword)
            return openTokensFormatter.tokens
        }
    }
}

// MARK: - Helpers

extension Array where Element == Declaration {
    /// Applies `operation` to every recursive declaration of this array of declarations
    func forEachRecursiveDeclaration(
        operation: (Declaration, _ parents: [Declaration]) -> Void,
        parents: [Declaration] = []
    ) {
        for declaration in self {
            operation(declaration, parents)
            if let body = declaration.body {
                body.forEachRecursiveDeclaration(operation: operation, parents: parents + [declaration])
            }
        }
    }

    /// Applies `transform` to every recursive declaration of this array of declarations
    func mapRecursiveDeclarations(_ transform: (Declaration) -> Declaration) -> [Declaration] {
        map { declaration in
            transform(declaration).mapRecursiveBodyDeclarations(transform)
        }
    }
}

extension Declaration {
    /// Maps the first group of tokens in this declaration
    ///  - For declarations with a body, this maps the `open` tokens
    ///  - For declarations without a body, this maps the entire declaration's tokens
    func mapOpeningTokens(with transform: ([Token]) -> [Token]) -> Declaration {
        switch self {
        case let .type(kind, open, body, close, originalRange):
            return .type(
                kind: kind,
                open: transform(open),
                body: body,
                close: close,
                originalRange: originalRange
            )

        case let .conditionalCompilation(open, body, close, originalRange):
            return .conditionalCompilation(
                open: transform(open),
                body: body,
                close: close,
                originalRange: originalRange
            )

        case let .declaration(kind, tokens, originalRange):
            return .declaration(
                kind: kind,
                tokens: transform(tokens),
                originalRange: originalRange
            )
        }
    }

    /// Maps the tokens of this simple `declaration`
    func mapDeclarationTokens(with transform: ([Token]) -> [Token]) -> Declaration {
        switch self {
        case let .declaration(kind, originalTokens, originalRange):
            return .declaration(
                kind: kind,
                tokens: transform(originalTokens),
                originalRange: originalRange
            )

        case .type, .conditionalCompilation:
            assertionFailure("`mapDeclarationTokens` only supports `declaration`s.")
            return self
        }
    }

    /// Maps the last group of tokens in this declaration
    ///  - For declarations with a body, this maps the `close` tokens
    ///  - For declarations without a body, this maps the entire declaration's tokens
    func mapClosingTokens(with transform: ([Token]) -> [Token]) -> Declaration {
        switch self {
        case let .type(kind, open, body, close, originalRange):
            return .type(
                kind: kind,
                open: open,
                body: body,
                close: transform(close),
                originalRange: originalRange
            )

        case let .conditionalCompilation(open, body, close, originalRange):
            return .conditionalCompilation(
                open: open,
                body: body,
                close: transform(close),
                originalRange: originalRange
            )

        case let .declaration(kind, tokens, originalRange):
            return .declaration(
                kind: kind,
                tokens: transform(tokens),
                originalRange: originalRange
            )
        }
    }

    /// Performs some declaration mapping for each body declaration in this declaration
    func mapRecursiveBodyDeclarations(_ transform: (Declaration) -> Declaration) -> Declaration {
        switch self {
        case let .type(kind, open, body, close, originalRange):
            return .type(
                kind: kind,
                open: open,
                body: body.mapRecursiveDeclarations(transform),
                close: close,
                originalRange: originalRange
            )

        case let .conditionalCompilation(open, body, close, originalRange):
            return .conditionalCompilation(
                open: open,
                body: body.mapRecursiveDeclarations(transform),
                close: close,
                originalRange: originalRange
            )

        case .declaration:
            // No work to do, because plain declarations don't have bodies
            return self
        }
    }

    /// Updates the given declaration tokens so it ends with at least one blank like
    /// (e.g. so it ends with at least two newlines)
    func endingWithBlankLine() -> Declaration {
        mapClosingTokens { tokens in
            tokens.endingWithBlankLine()
        }
    }

    /// Updates the given declaration tokens so it ends with no blank lines
    /// (e.g. so it ends with one newline)
    func endingWithoutBlankLine() -> Declaration {
        mapClosingTokens { tokens in
            tokens.endingWithoutBlankLine()
        }
    }
}

extension Array where Element == Token {
    /// Updates the given declaration tokens so it ends with at least one blank like
    /// (e.g. so it ends with at least two newlines)
    func endingWithBlankLine() -> [Token] {
        let parser = Formatter(self)

        while parser.tokens.numberOfTrailingLinebreaks() < 2 {
            parser.insertLinebreak(at: parser.tokens.count)
        }

        return parser.tokens
    }

    /// Updates the given tokens so it ends with no blank lines
    /// (e.g. so it ends with one newline)
    func endingWithoutBlankLine() -> [Token] {
        let parser = Formatter(self)

        while parser.tokens.numberOfTrailingLinebreaks() > 1 {
            guard let lastNewlineIndex = parser.lastIndex(
                of: .linebreak,
                in: 0 ..< parser.tokens.count
            )
            else { break }

            parser.removeTokens(in: lastNewlineIndex ..< parser.tokens.count)
        }

        return parser.tokens
    }
}

extension Declaration {
    /// Initializes a `DeclarationV2` from this legacy `DeclarationV1` value.
    func makeDeclarationV2(formatter: Formatter) -> DeclarationV2? {
        // DeclarationV2 requires that every declaration has a valid keyword.
        // DeclarationV1 handles disabling rules by setting the keyword to an empty string.
        guard !keyword.isEmpty else { return nil }

        let declaration: DeclarationV2
        switch self {
        case let .type(kind, _, body, _, originalRange):
            declaration = TypeDeclaration(
                keyword: kind,
                range: originalRange,
                body: body.compactMap { $0.makeDeclarationV2(formatter: formatter) },
                formatter: formatter
            )

        case let .declaration(kind, _, originalRange):
            declaration = SimpleDeclaration(
                keyword: kind,
                range: originalRange,
                formatter: formatter
            )

        case let .conditionalCompilation(_, body, _, originalRange):
            declaration = ConditionalCompilationDeclaration(
                range: originalRange,
                body: body.compactMap { $0.makeDeclarationV2(formatter: formatter) },
                formatter: formatter
            )
        }

        guard declaration.isValid else {
            return nil
        }

        return declaration
    }
}
