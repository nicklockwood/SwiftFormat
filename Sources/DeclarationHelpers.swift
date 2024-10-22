//
//  DeclarationHelpers.swift
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
        // Conditional compilation blocks don't have a "name"
        guard keyword != "#if" else { return nil }

        let parser = Formatter(openTokens)
        guard let keywordIndex = openTokens.firstIndex(of: .keyword(keyword)),
              let nameIndex = parser.index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex)
        else {
            return nil
        }

        // An extension can refer to complicated types like `Foo.Bar`, `[Foo]`, `Collection<Foo>`, etc.
        // Every other declaration type just uses a simple identifier.
        if keyword == "extension" {
            return parser.parseType(at: nameIndex)?.name
        } else {
            return parser.tokens[nameIndex].string
        }
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

    var swiftUIPropertyWrapper: String? {
        modifiers.first(where: Declaration.swiftUIPropertyWrappers.contains)
    }

    /// Whether or not this declaration represents a stored instance property
    var isStoredInstanceProperty: Bool {
        guard keyword == "let" || keyword == "var" else { return false }

        // A static property is not an instance property
        if modifiers.contains("static") {
            return false
        }

        // If this property has a body, then it's a stored property
        // if and only if the declaration body has a `didSet` or `willSet` keyword,
        // based on the grammar for a variable declaration:
        // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_variable-declaration
        let formatter = Formatter(tokens)
        if let keywordIndex = formatter.index(of: .keyword(keyword), after: -1),
           let startOfPropertyBody = formatter.startOfPropertyBody(
               at: keywordIndex,
               endOfPropertyIndex: formatter.tokens.count
           ),
           let nextToken = formatter.next(.nonSpaceOrCommentOrLinebreak, after: startOfPropertyBody)
        {
            return [.identifier("willSet"), .identifier("didSet")].contains(nextToken)
        }

        // Otherwise, if the property doesn't have a body, then it must not be a computed property.
        return true
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

// MARK: - DeclarationType

/// The type of a declaration.
enum DeclarationType: String, CaseIterable {
    case beforeMarks
    case nestedType
    case staticProperty
    case staticPropertyWithBody
    case classPropertyWithBody
    case overriddenProperty
    case swiftUIPropertyWrapper
    case instanceProperty
    case instancePropertyWithBody
    case instanceLifecycle
    case swiftUIProperty
    case swiftUIMethod
    case overriddenMethod
    case staticMethod
    case classMethod
    case instanceMethod

    var markComment: String {
        switch self {
        case .beforeMarks:
            return "Before Marks"
        case .nestedType:
            return "Nested Types"
        case .staticProperty:
            return "Static Properties"
        case .staticPropertyWithBody:
            return "Static Computed Properties"
        case .classPropertyWithBody:
            return "Class Properties"
        case .overriddenProperty:
            return "Overridden Properties"
        case .instanceLifecycle:
            return "Lifecycle"
        case .overriddenMethod:
            return "Overridden Functions"
        case .swiftUIProperty:
            return "Content Properties"
        case .swiftUIMethod:
            return "Content Methods"
        case .swiftUIPropertyWrapper:
            return "SwiftUI Properties"
        case .instanceProperty:
            return "Properties"
        case .instancePropertyWithBody:
            return "Computed Properties"
        case .staticMethod:
            return "Static Functions"
        case .classMethod:
            return "Class Functions"
        case .instanceMethod:
            return "Functions"
        }
    }

    static var essentialCases: [DeclarationType] {
        [
            .beforeMarks,
            .nestedType,
            .instanceLifecycle,
            .instanceProperty,
            .instanceMethod,
        ]
    }

    static func defaultOrdering(for mode: DeclarationOrganizationMode) -> [DeclarationType] {
        switch mode {
        case .type:
            return allCases
        case .visibility:
            return allCases.filter { type in
                // Exclude beforeMarks and instanceLifecycle, since by default
                // these are instead treated as top-level categories
                type != .beforeMarks && type != .instanceLifecycle
            }
        }
    }
}

extension Declaration {
    /// The `DeclarationType` of the given `Declaration`
    func declarationType(
        allowlist availableTypes: [DeclarationType],
        beforeMarks: Set<String>,
        lifecycleMethods: Set<String>
    ) -> DeclarationType {
        switch self {
        case let .type(keyword, _, _, _, _):
            return beforeMarks.contains(keyword) ? .beforeMarks : .nestedType

        case let .conditionalCompilation(_, body, _, _):
            // Prefer treating conditional compilation blocks as having
            // the property type of the first declaration in their body.
            guard let firstDeclarationInBlock = body.first else {
                // It's unusual to have an empty conditional compilation block.
                // Pick an arbitrary declaration type as a fallback.
                return .nestedType
            }

            return firstDeclarationInBlock.declarationType(
                allowlist: availableTypes,
                beforeMarks: beforeMarks,
                lifecycleMethods: lifecycleMethods
            )

        case let .declaration(keyword, tokens, _):
            guard let declarationTypeTokenIndex = tokens.firstIndex(of: .keyword(keyword)) else {
                return .beforeMarks
            }

            let declarationParser = Formatter(tokens)
            let declarationTypeToken = declarationParser.tokens[declarationTypeTokenIndex]

            if keyword == "case" || beforeMarks.contains(keyword) {
                return .beforeMarks
            }

            for token in declarationParser.tokens {
                if beforeMarks.contains(token.string) { return .beforeMarks }
            }

            let isStaticDeclaration = declarationParser.index(
                of: .keyword("static"),
                before: declarationTypeTokenIndex
            ) != nil

            let isClassDeclaration = declarationParser.index(
                of: .keyword("class"),
                before: declarationTypeTokenIndex
            ) != nil

            let isOverriddenDeclaration = declarationParser.index(
                of: .identifier("override"),
                before: declarationTypeTokenIndex
            ) != nil

            let isDeclarationWithBody = declarationParser.startOfPropertyBody(
                at: declarationTypeTokenIndex,
                endOfPropertyIndex: declarationParser.tokens.count
            ) != nil

            let isViewDeclaration: Bool = {
                guard let someKeywordIndex = declarationParser.index(
                    of: .identifier("some"), after: declarationTypeTokenIndex
                ) else { return false }

                return declarationParser.index(of: .identifier("View"), after: someKeywordIndex) != nil
            }()

            let isSwiftUIPropertyWrapper = declarationParser
                .modifiersForDeclaration(at: declarationTypeTokenIndex) { _, modifier in
                    Declaration.swiftUIPropertyWrappers.contains(modifier)
                }

            switch declarationTypeToken {
            // Properties and property-like declarations
            case .keyword("let"), .keyword("var"),
                 .keyword("operator"), .keyword("precedencegroup"):

                if isOverriddenDeclaration, availableTypes.contains(.overriddenProperty) {
                    return .overriddenProperty
                }
                if isStaticDeclaration, isDeclarationWithBody, availableTypes.contains(.staticPropertyWithBody) {
                    return .staticPropertyWithBody
                }
                if isStaticDeclaration, availableTypes.contains(.staticProperty) {
                    return .staticProperty
                }
                if isClassDeclaration, availableTypes.contains(.classPropertyWithBody) {
                    // Interestingly, Swift does not support stored class properties
                    // so there's no such thing as a class property without a body.
                    // https://forums.swift.org/t/class-properties/16539/11
                    return .classPropertyWithBody
                }
                if isViewDeclaration, availableTypes.contains(.swiftUIProperty) {
                    return .swiftUIProperty
                }
                if !isDeclarationWithBody, isSwiftUIPropertyWrapper, availableTypes.contains(.swiftUIPropertyWrapper) {
                    return .swiftUIPropertyWrapper
                }
                if isDeclarationWithBody, availableTypes.contains(.instancePropertyWithBody) {
                    return .instancePropertyWithBody
                }

                return .instanceProperty

            // Functions and function-like declarations
            case .keyword("func"), .keyword("subscript"):
                // The user can also provide specific instance method names to place in Lifecycle
                //  - In the function declaration grammar, the function name always
                //    immediately follows the `func` keyword:
                //    https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_function-name
                let methodName = declarationParser.next(.nonSpaceOrCommentOrLinebreak, after: declarationTypeTokenIndex)
                if let methodName = methodName, lifecycleMethods.contains(methodName.string) {
                    return .instanceLifecycle
                }
                if isOverriddenDeclaration, availableTypes.contains(.overriddenMethod) {
                    return .overriddenMethod
                }
                if isStaticDeclaration, availableTypes.contains(.staticMethod) {
                    return .staticMethod
                }
                if isClassDeclaration, availableTypes.contains(.classMethod) {
                    return .classMethod
                }
                if isViewDeclaration, availableTypes.contains(.swiftUIMethod) {
                    return .swiftUIMethod
                }

                return .instanceMethod

            case .keyword("init"), .keyword("deinit"):
                return .instanceLifecycle

            // Type-like declarations
            case .keyword("typealias"):
                return .nestedType

            case .keyword("case"):
                return .beforeMarks

            default:
                return .beforeMarks
            }
        }
    }

    /// Represents all the native SwiftUI property wrappers that conform to `DynamicProperty` and cause a SwiftUI view to re-render.
    /// Most of these are listed here: https://developer.apple.com/documentation/swiftui/dynamicproperty
    fileprivate static var swiftUIPropertyWrappers: Set<String> {
        [
            "@AccessibilityFocusState",
            "@AppStorage",
            "@Binding",
            "@Environment",
            "@EnvironmentObject",
            "@NSApplicationDelegateAdaptor",
            "@FetchRequest",
            "@FocusedBinding",
            "@FocusState",
            "@FocusedValue",
            "@FocusedObject",
            "@GestureState",
            "@Namespace",
            "@ObservedObject",
            "@PhysicalMetric",
            "@Query",
            "@ScaledMetric",
            "@SceneStorage",
            "@SectionedFetchRequest",
            "@State",
            "@StateObject",
            "@UIApplicationDelegateAdaptor",
            "@WKExtensionDelegateAdaptor",
        ]
    }
}

extension Formatter {
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

            // Search for a visibility keyword in the tokens before the primary keyword,
            // making sure we exclude groups like private(set).
            var searchIndex = 0
            let parser = Formatter(tokens)
            while searchIndex < keywordIndex {
                if let visibility = Visibility(rawValue: parser.tokens[searchIndex].string),
                   parser.next(.nonSpaceOrComment, after: searchIndex) != .startOfScope("(")
                {
                    return visibility
                }

                searchIndex += 1
            }

            return nil
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
        var declaration = self

        if let existingVisibilityKeyword = declaration.visibility() {
            declaration = declaration.remove(existingVisibilityKeyword)
        }

        return declaration.mapOpeningTokens { openTokens in
            guard let indexOfKeyword = openTokens
                .firstIndex(of: .keyword(declaration.keyword))
            else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            let startOfModifiers = openTokensFormatter
                .startOfModifiers(at: indexOfKeyword, includingAttributes: false)

            openTokensFormatter.insert(
                tokenize("\(visibilityKeyword.rawValue) "),
                at: startOfModifiers
            )

            return openTokensFormatter.tokens
        }
    }

    /// Removes the given visibility keyword from the given declaration
    func remove(_ visibilityKeyword: Visibility) -> Declaration {
        mapOpeningTokens { openTokens in
            guard let visibilityKeywordIndex = openTokens
                .firstIndex(of: .keyword(visibilityKeyword.rawValue))
            else {
                return openTokens
            }

            let openTokensFormatter = Formatter(openTokens)
            openTokensFormatter.removeToken(at: visibilityKeywordIndex)

            while openTokensFormatter.token(at: visibilityKeywordIndex)?.isSpace == true {
                openTokensFormatter.removeToken(at: visibilityKeywordIndex)
            }

            return openTokensFormatter.tokens
        }
    }
}

// MARK: - Helpers

extension Formatter {
    /// Recursively calls the `operation` for every declaration in the source file
    func forEachRecursiveDeclaration(_ operation: (Declaration, _ parents: [Declaration]) -> Void) {
        parseDeclarations().forEachRecursiveDeclaration(operation: operation, parents: [])
    }

    /// Applies `mapRecursiveDeclarations` in place
    func mapRecursiveDeclarations(_ transform: (Declaration) -> Declaration) {
        let updatedDeclarations = parseDeclarations().mapRecursiveDeclarations { declaration in
            transform(declaration)
        }

        let updatedTokens = updatedDeclarations.flatMap(\.tokens)

        // Only apply the updated tokens if the source representation changes.
        if tokens.string != updatedTokens.string {
            replaceAllTokens(with: updatedTokens)
        }
    }
}

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

    // The number of trailing newlines in this array of tokens,
    // taking into account any spaces that may be between the linebreaks.
    func numberOfTrailingLinebreaks() -> Int {
        let parser = Formatter(self)

        var numberOfTrailingLinebreaks = 0
        var searchIndex = parser.tokens.count - 1

        while searchIndex > 0,
              let token = parser.token(at: searchIndex),
              token.isSpaceOrLinebreak
        {
            if token.isLinebreak {
                numberOfTrailingLinebreaks += 1
            }

            searchIndex -= 1
        }

        return numberOfTrailingLinebreaks
    }
}
