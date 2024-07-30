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
/// Forms a tree of declaratons, since `type` declarations have a body
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
            return openTokens + bodyDeclarations.flatMap { $0.tokens } + closeTokens
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
        guard let keywordIndex = openTokens.firstIndex(of: .keyword(keyword)),
              let nameIndex = parser.index(of: .nonSpaceOrCommentOrLinebreak, after: keywordIndex),
              parser.tokens[nameIndex].isIdentifierOrKeyword
        else {
            return nil
        }

        return parser.fullyQualifiedName(startingAt: nameIndex).name
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
        // instead of the start of the next delaration's tokens
        while let linebreakSearchIndex = endOfDeclaration,
              token(at: linebreakSearchIndex + 1)?.isLinebreak == true
        {
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

extension Formatter {
    /// The `DeclarationType` of the given `Declaration`
    func type(
        of declaration: Declaration,
        allowlist availableTypes: [DeclarationType]
    ) -> DeclarationType {
        switch declaration {
        case let .type(keyword, _, _, _, _):
            return options.beforeMarks.contains(keyword) ? .beforeMarks : .nestedType

        case let .declaration(keyword, tokens, _):
            return declarationType(of: keyword, with: tokens, allowlist: availableTypes)

        case let .conditionalCompilation(_, body, _, _):
            // Prefer treating conditional compilation blocks as having
            // the property type of the first declaration in their body.
            guard let firstDeclarationInBlock = body.first else {
                // It's unusual to have an empty conditional compilation block.
                // Pick an arbitrary declaration type as a fallback.
                return .nestedType
            }

            return type(of: firstDeclarationInBlock, allowlist: availableTypes)
        }
    }

    /// The `DeclarationType` of the declaration with the given keyword and tokens
    func declarationType(
        of keyword: String,
        with tokens: [Token],
        allowlist availableTypes: [DeclarationType]
    ) -> DeclarationType {
        guard let declarationTypeTokenIndex = tokens.firstIndex(of: .keyword(keyword)) else {
            return .beforeMarks
        }

        let declarationParser = Formatter(tokens)
        let declarationTypeToken = declarationParser.tokens[declarationTypeTokenIndex]

        if keyword == "case" || options.beforeMarks.contains(keyword) {
            return .beforeMarks
        }

        for token in declarationParser.tokens {
            if options.beforeMarks.contains(token.string) { return .beforeMarks }
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

        let isDeclarationWithBody: Bool = {
            // If there is a code block at the end of the declaration that is _not_ a closure,
            // then this declaration has a body.
            if let lastClosingBraceIndex = declarationParser.index(of: .endOfScope("}"), before: declarationParser.tokens.count),
               let lastOpeningBraceIndex = declarationParser.index(of: .startOfScope("{"), before: lastClosingBraceIndex),
               declarationTypeTokenIndex < lastOpeningBraceIndex,
               declarationTypeTokenIndex < lastClosingBraceIndex,
               !declarationParser.isStartOfClosure(at: lastOpeningBraceIndex) { return true }

            return false
        }()

        let isViewDeclaration: Bool = {
            guard let someKeywordIndex = declarationParser.index(
                of: .identifier("some"), after: declarationTypeTokenIndex
            ) else { return false }

            return declarationParser.index(of: .identifier("View"), after: someKeywordIndex) != nil
        }()

        let isSwiftUIPropertyWrapper = declarationParser
            .modifiersForDeclaration(at: declarationTypeTokenIndex) { _, modifier in
                swiftUIPropertyWrappers.contains(modifier)
            }

        switch declarationTypeToken {
        // Properties and property-like declarations
        case .keyword("let"), .keyword("var"),
             .keyword("operator"), .keyword("precedencegroup"):

            if isOverriddenDeclaration && availableTypes.contains(.overriddenProperty) {
                return .overriddenProperty
            }
            if isStaticDeclaration && isDeclarationWithBody && availableTypes.contains(.staticPropertyWithBody) {
                return .staticPropertyWithBody
            }
            if isStaticDeclaration && availableTypes.contains(.staticProperty) {
                return .staticProperty
            }
            if isClassDeclaration && availableTypes.contains(.classPropertyWithBody) {
                // Interestingly, Swift does not support stored class properties
                // so there's no such thing as a class property without a body.
                // https://forums.swift.org/t/class-properties/16539/11
                return .classPropertyWithBody
            }
            if isViewDeclaration && availableTypes.contains(.swiftUIProperty) {
                return .swiftUIProperty
            }
            if !isDeclarationWithBody && isSwiftUIPropertyWrapper && availableTypes.contains(.swiftUIPropertyWrapper) {
                return .swiftUIPropertyWrapper
            }
            if isDeclarationWithBody && availableTypes.contains(.instancePropertyWithBody) {
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
            if let methodName = methodName, options.lifecycleMethods.contains(methodName.string) {
                return .instanceLifecycle
            }
            if isOverriddenDeclaration && availableTypes.contains(.overriddenMethod) {
                return .overriddenMethod
            }
            if isStaticDeclaration && availableTypes.contains(.staticMethod) {
                return .staticMethod
            }
            if isClassDeclaration && availableTypes.contains(.classMethod) {
                return .classMethod
            }
            if isViewDeclaration && availableTypes.contains(.swiftUIMethod) {
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

    /// Represents all the native SwiftUI property wrappers that conform to `DynamicProperty` and cause a SwiftUI view to re-render.
    /// Most of these are listed here: https://developer.apple.com/documentation/swiftui/dynamicproperty
    private var swiftUIPropertyWrappers: Set<String> {
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

extension Formatter {
    /// The `Visibility` of the given `Declaration`
    func visibility(of declaration: Declaration) -> Visibility? {
        switch declaration {
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
                return visibility(of: firstDeclarationInBlock)
            } else {
                return nil
            }
        }
    }
}

// MARK: - Category

/// A category of declarations used by the `organizeDeclarations` rule
struct Category: Equatable, Hashable {
    var visibility: VisibilityCategory
    var type: DeclarationType
    var order: Int
    var comment: String? = nil

    /// The comment tokens that should precede all declarations in this category
    func markComment(from template: String, with mode: DeclarationOrganizationMode) -> String? {
        "// " + template
            .replacingOccurrences(
                of: "%c",
                with: comment ?? (mode == .type ? type.markComment : visibility.markComment)
            )
    }

    /// Whether or not a mark comment should be added for this category,
    /// given the set of existing categories with existing mark comments
    func shouldBeMarked(in categoriesWithMarkComment: Set<Category>, for mode: DeclarationOrganizationMode) -> Bool {
        guard type != .beforeMarks else {
            return false
        }

        switch mode {
        case .type:
            return !categoriesWithMarkComment.contains(where: { $0.type == type || $0.visibility == .explicit(type) })
        case .visibility:
            return !categoriesWithMarkComment.contains(where: { $0.visibility == visibility })
        }
    }
}

/// The visibility category of a declaration
///
/// - Note: When adding a new visibility type, remember to also update the list in `Examples.swift`.
enum VisibilityCategory: CaseIterable, Hashable, RawRepresentable {
    case visibility(Visibility)
    case explicit(DeclarationType)

    init?(rawValue: String) {
        if let visibility = Visibility(rawValue: rawValue) {
            self = .visibility(visibility)
        } else if let type = DeclarationType(rawValue: rawValue) {
            self = .explicit(type)
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case let .visibility(visibility):
            return visibility.rawValue
        case let .explicit(declarationType):
            return declarationType.rawValue
        }
    }

    var markComment: String {
        switch self {
        case let .visibility(type):
            return type.rawValue.capitalized
        case let .explicit(type):
            return type.markComment
        }
    }

    static var allCases: [VisibilityCategory] {
        Visibility.allCases.map { .visibility($0) }
    }

    static var essentialCases: [VisibilityCategory] {
        Visibility.allCases.map { .visibility($0) }
    }

    static func defaultOrdering(for mode: DeclarationOrganizationMode) -> [VisibilityCategory] {
        switch mode {
        case .type:
            return allCases
        case .visibility:
            return [
                .explicit(.beforeMarks),
                .explicit(.instanceLifecycle),
            ] + allCases
        }
    }
}

extension Formatter {
    /// The `Category` of the given `Declaration`
    func category(
        of declaration: Declaration,
        for mode: DeclarationOrganizationMode,
        using order: ParsedOrder
    ) -> Category {
        let visibility = self.visibility(of: declaration) ?? .internal
        let type = self.type(of: declaration, allowlist: order.map(\.type))

        let visibilityCategory: VisibilityCategory
        switch mode {
        case .visibility:
            guard VisibilityCategory.allCases.contains(.explicit(type)) else {
                fallthrough
            }

            visibilityCategory = .explicit(type)
        case .type:
            visibilityCategory = .visibility(visibility)
        }

        return category(from: order, for: visibilityCategory, with: type)
    }

    typealias ParsedOrder = [Category]

    /// The ordering of categories to use for the given `DeclarationOrganizationMode`
    func categoryOrder(for mode: DeclarationOrganizationMode) -> ParsedOrder {
        typealias ParsedVisibilityMarks = [VisibilityCategory: String]
        typealias ParsedTypeMarks = [DeclarationType: String]

        let VisibilityCategorys = options.visibilityOrder?.compactMap { VisibilityCategory(rawValue: $0) }
            ?? VisibilityCategory.defaultOrdering(for: mode)

        let declarationTypes = options.typeOrder?.compactMap { DeclarationType(rawValue: $0) }
            ?? DeclarationType.defaultOrdering(for: mode)

        // Validate that every essential declaration type is included in either `declarationTypes` or `VisibilityCategorys`.
        // Otherwise, we will just crash later when we find a declaration with this type.
        for essentialDeclarationType in DeclarationType.essentialCases {
            guard declarationTypes.contains(essentialDeclarationType)
                || VisibilityCategorys.contains(.explicit(essentialDeclarationType))
            else {
                Swift.fatalError("\(essentialDeclarationType.rawValue) must be included in either --typeorder or --visibilityorder")
            }
        }

        let customVisibilityMarks = options.customVisibilityMarks
        let customTypeMarks = options.customTypeMarks

        let parsedVisibilityMarks: ParsedVisibilityMarks = parseMarks(for: customVisibilityMarks)
        let parsedTypeMarks: ParsedTypeMarks = parseMarks(for: customTypeMarks)

        switch mode {
        case .visibility:
            let categoryPairings = VisibilityCategorys.flatMap { VisibilityCategory -> [(VisibilityCategory, DeclarationType)] in
                switch VisibilityCategory {
                case let .visibility(visibility):
                    // Each visibility / access control level pairs with all of the declaration types
                    return declarationTypes.compactMap { declarationType in
                        (.visibility(visibility), declarationType)
                    }

                case let .explicit(explicitDeclarationType):
                    // Each top-level declaration category pairs with all of the visibility types
                    return VisibilityCategorys.map { VisibilityCategory in
                        (VisibilityCategory, explicitDeclarationType)
                    }
                }
            }

            return categoryPairings.enumerated().map { offset, element in
                Category(
                    visibility: element.0,
                    type: element.1,
                    order: offset,
                    comment: parsedVisibilityMarks[element.0]
                )
            }

        case .type:
            let categoryPairings = declarationTypes.flatMap { declarationType -> [(VisibilityCategory, DeclarationType)] in
                VisibilityCategorys.map { VisibilityCategory in
                    (VisibilityCategory, declarationType)
                }
            }

            return categoryPairings.enumerated().map { offset, element in
                Category(
                    visibility: element.0,
                    type: element.1,
                    order: offset,
                    comment: parsedTypeMarks[element.1]
                )
            }
        }
    }

    /// The `Category` of a declaration with the given `VisibilityCategory` and `DeclarationType`
    func category(
        from order: ParsedOrder,
        for visibility: VisibilityCategory,
        with type: DeclarationType
    ) -> Category {
        guard let category = order.first(where: { entry in
            entry.visibility == visibility && entry.type == type
                || (entry.visibility == .explicit(type) && entry.type == type)
        })
        else {
            Swift.fatalError("Cannot determine ordering for declaration with visibility=\(visibility.rawValue) and type=\(type.rawValue).")
        }

        return category
    }

    private func parseMarks<T: RawRepresentable>(
        for options: Set<String>
    ) -> [T: String] where T.RawValue == String {
        options.map { customMarkEntry -> (T, String)? in
            let split = customMarkEntry.split(separator: ":", maxSplits: 1)

            guard split.count == 2,
                  let rawValue = split.first,
                  let mark = split.last,
                  let concreteType = T(rawValue: String(rawValue))
            else { return nil }

            return (concreteType, String(mark))
        }
        .compactMap { $0 }
        .reduce(into: [:]) { dictionary, option in
            dictionary[option.0] = option.1
        }
    }
}

// MARK: - organizeDeclaration

extension Formatter {
    /// A `Declaration` that represents a Swift type
    typealias TypeDeclaration = (kind: String, open: [Token], body: [Declaration], close: [Token])

    /// Organizes the given type declaration into sorted categories
    func organizeDeclaration(_ typeDeclaration: TypeDeclaration) -> TypeDeclaration {
        guard options.organizeTypes.contains(typeDeclaration.kind),
              typeLengthExceedsOrganizationThreshold(typeDeclaration)
        else { return typeDeclaration }

        // Parse category order from options
        let categoryOrder = self.categoryOrder(for: options.organizationMode)

        // Remove all of the existing category separators, so they can be re-added
        // at the correct location after sorting the declarations.
        var typeBody = removeExistingCategorySeparators(
            from: typeDeclaration.body,
            with: options.organizationMode,
            using: categoryOrder
        )

        // Track the consecutive groups of property declarations so we can avoid inserting
        // blank lines between elements in the group if possible.
        var consecutivePropertyGroups = consecutivePropertyDeclarationGroups(in: typeDeclaration.body)
            .filter { group in
                // Only track declaration groups where the group as a whole is followed by a
                // blank line, since otherwise the declarations can be reordered without issues.
                guard let lastDeclarationInGroup = group.last else { return false }
                return lastDeclarationInGroup.tokens.numberOfTrailingLinebreaks() > 1
            }

        // Remove the trailing blank line from the last declaration in each consecutive group
        for (groupIndex, consecutivePropertyGroup) in consecutivePropertyGroups.enumerated() {
            guard let lastDeclarationInGroup = consecutivePropertyGroup.last,
                  let indexOfDeclaration = typeBody.firstIndex(of: lastDeclarationInGroup)
            else { continue }

            let updatedDeclaration = lastDeclarationInGroup.endingWithoutBlankLine()
            let indexInGroup = consecutivePropertyGroup.indices.last!

            typeBody[indexOfDeclaration] = updatedDeclaration
            consecutivePropertyGroups[groupIndex][indexInGroup] = updatedDeclaration
        }

        // Categorize each of the declarations into their primary groups
        let categorizedDeclarations: [CategorizedDeclaration] = typeBody
            .map { declaration in
                let declarationCategory = category(
                    of: declaration,
                    for: options.organizationMode,
                    using: categoryOrder
                )

                return (declaration: declaration, category: declarationCategory)
            }

        // Sort the declarations based on their category and type
        guard var sortedTypeBody = sortCategorizedDeclarations(
            categorizedDeclarations,
            in: typeDeclaration
        )
        else { return typeDeclaration }

        // Insert a blank line after the last declaration in each original group
        for consecutivePropertyGroup in consecutivePropertyGroups {
            let propertiesInGroup = Set(consecutivePropertyGroup)

            guard let lastDeclarationInSortedBody = sortedTypeBody.lastIndex(where: { propertiesInGroup.contains($0.declaration) })
            else { continue }

            sortedTypeBody[lastDeclarationInSortedBody].declaration =
                sortedTypeBody[lastDeclarationInSortedBody].declaration.endingWithBlankLine()
        }

        // Add a mark comment for each top-level category
        let sortedAndMarkedType = addCategorySeparators(
            to: typeDeclaration,
            sortedDeclarations: sortedTypeBody
        )

        return sortedAndMarkedType
    }

    /// Whether or not the length of this types exceeds the minimum threshold to be organized
    private func typeLengthExceedsOrganizationThreshold(_ typeDeclaration: TypeDeclaration) -> Bool {
        let organizationThreshold: Int
        switch typeDeclaration.kind {
        case "class", "actor":
            organizationThreshold = options.organizeClassThreshold
        case "struct":
            organizationThreshold = options.organizeStructThreshold
        case "enum":
            organizationThreshold = options.organizeEnumThreshold
        case "extension":
            organizationThreshold = options.organizeExtensionThreshold
        default:
            organizationThreshold = 0
        }

        guard organizationThreshold != 0 else {
            return true
        }

        let lineCount = typeDeclaration.body
            .flatMap { $0.tokens }
            .filter { $0.isLinebreak }
            .count

        return lineCount >= organizationThreshold
    }

    private typealias CategorizedDeclaration = (declaration: Declaration, category: Category)

    /// Sorts the given categorized declarations based on the defined category ordering
    private func sortCategorizedDeclarations(
        _ categorizedDeclarations: [CategorizedDeclaration],
        in typeDeclaration: TypeDeclaration
    ) -> [CategorizedDeclaration]? {
        let sortAlphabeticallyWithinSubcategories = shouldSortAlphabeticallyWithinSubcategories(in: typeDeclaration)

        var sortedDeclarations = sortDeclarations(
            categorizedDeclarations,
            sortAlphabeticallyWithinSubcategories: sortAlphabeticallyWithinSubcategories
        )

        // The compiler will synthesize a memberwise init for `struct`
        // declarations that don't have an `init` declaration.
        // We have to take care to not reorder any properties (but reordering functions etc is ok!)
        if !sortAlphabeticallyWithinSubcategories, typeDeclaration.kind == "struct",
           !typeDeclaration.body.contains(where: { $0.keyword == "init" }),
           !preservesSynthesizedMemberwiseInitializer(categorizedDeclarations, sortedDeclarations)
        {
            // If sorting by category and by type could cause compilation failures
            // by not correctly preserving the synthesized memberwise initializer,
            // try to sort _only_ by category (so we can try to preserve the correct category separators)
            sortedDeclarations = sortDeclarations(categorizedDeclarations, sortAlphabeticallyWithinSubcategories: false)

            // If sorting _only_ by category still changes the synthesized memberwise initializer,
            // then there's nothing we can do to organize this struct.
            if !preservesSynthesizedMemberwiseInitializer(categorizedDeclarations, sortedDeclarations) {
                return nil
            }
        }

        return sortedDeclarations
    }

    private func sortDeclarations(
        _ categorizedDeclarations: [CategorizedDeclaration],
        sortAlphabeticallyWithinSubcategories: Bool
    )
        -> [CategorizedDeclaration]
    {
        categorizedDeclarations.enumerated()
            .sorted(by: { lhs, rhs in
                let (lhsOriginalIndex, lhs) = lhs
                let (rhsOriginalIndex, rhs) = rhs

                if lhs.category.order != rhs.category.order {
                    return lhs.category.order < rhs.category.order
                }

                // If this type had a :sort directive, we sort alphabetically
                // within the subcategories (where ordering is otherwise undefined)
                if sortAlphabeticallyWithinSubcategories,
                   let lhsName = lhs.declaration.name,
                   let rhsName = rhs.declaration.name,
                   lhsName != rhsName
                {
                    return lhsName.localizedCompare(rhsName) == .orderedAscending
                }

                // Respect the original declaration ordering when the categories and types are the same
                return lhsOriginalIndex < rhsOriginalIndex
            })
            .map { $0.element }
    }

    /// Whether or not type members should additionally be sorted alphabetically
    /// within individual subcategories
    private func shouldSortAlphabeticallyWithinSubcategories(in typeDeclaration: TypeDeclaration) -> Bool {
        // If this type has a leading :sort directive, we sort alphabetically
        // within the subcategories (where ordering is otherwise undefined)
        let shouldSortAlphabeticallyBySortingMark = typeDeclaration.open.contains(where: {
            $0.isCommentBody && $0.string.contains("swiftformat:sort") && !$0.string.contains(":sort:")
        })

        // If this type declaration name contains pattern — sort as well
        let shouldSortAlphabeticallyByDeclarationPattern: Bool = {
            let parser = Formatter(typeDeclaration.open)

            guard let kindIndex = parser.index(of: .keyword(typeDeclaration.kind), in: 0 ..< typeDeclaration.open.count),
                  let identifier = parser.next(.identifier, after: kindIndex)
            else {
                return false
            }

            return options.alphabeticallySortedDeclarationPatterns.contains {
                identifier.string.contains($0)
            }
        }()

        return shouldSortAlphabeticallyBySortingMark
            || shouldSortAlphabeticallyByDeclarationPattern
    }

    // Whether or not this declaration is an instance property that can affect
    // the parameters struct's synthesized memberwise initializer
    private func affectsSynthesizedMemberwiseInitializer(
        _ declaration: Declaration,
        _ category: Category
    ) -> Bool {
        switch category.type {
        case .swiftUIPropertyWrapper:
            return true

        case .instanceProperty:
            return true

        case .instancePropertyWithBody:
            // `instancePropertyWithBody` represents some stored properties,
            // but also computed properties. Only stored properties,
            // not computed properties, affect the synthesized init.
            //
            // This is a stored property if and only if
            // the declaration body has a `didSet` or `willSet` keyword,
            // based on the grammar for a variable declaration:
            // https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#grammar_variable-declaration
            let parser = Formatter(declaration.tokens)

            if let bodyOpenBrace = parser.index(of: .startOfScope("{"), after: -1),
               let nextToken = parser.next(.nonSpaceOrCommentOrLinebreak, after: bodyOpenBrace),
               [.identifier("willSet"), .identifier("didSet")].contains(nextToken)
            {
                return true
            }

            return false

        default:
            return false
        }
    }

    // Whether or not the two given declaration orderings preserve
    // the same synthesized memberwise initializer
    private func preservesSynthesizedMemberwiseInitializer(
        _ lhs: [CategorizedDeclaration],
        _ rhs: [CategorizedDeclaration]
    ) -> Bool {
        let lhsPropertiesOrder = lhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.category) }
            .map { $0.declaration }

        let rhsPropertiesOrder = rhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.category) }
            .map { $0.declaration }

        return lhsPropertiesOrder == rhsPropertiesOrder
    }

    // Finds all of the consecutive groups of property declarations in the type body
    private func consecutivePropertyDeclarationGroups(in body: [Declaration]) -> [[Declaration]] {
        var declarationGroups: [[Declaration]] = []
        var currentGroup: [Declaration] = []

        /// Ends the current group, ensuring that groups are only recorded
        /// when they contain two or more declarations.
        func endCurrentGroup(addingToExistingGroup declarationToAdd: Declaration? = nil) {
            if let declarationToAdd = declarationToAdd {
                currentGroup.append(declarationToAdd)
            }

            if currentGroup.count >= 2 {
                declarationGroups.append(currentGroup)
            }

            currentGroup = []
        }

        for declaration in body {
            guard declaration.keyword == "let" || declaration.keyword == "var" else {
                endCurrentGroup()
                continue
            }

            let hasTrailingBlankLine = declaration.tokens.numberOfTrailingLinebreaks() > 1

            if hasTrailingBlankLine {
                endCurrentGroup(addingToExistingGroup: declaration)
            } else {
                currentGroup.append(declaration)
            }
        }

        endCurrentGroup()
        return declarationGroups
    }

    /// Adds MARK category separates to the given type
    private func addCategorySeparators(
        to typeDeclaration: TypeDeclaration,
        sortedDeclarations: [CategorizedDeclaration]
    )
        -> TypeDeclaration
    {
        let numberOfCategories: Int = {
            switch options.organizationMode {
            case .visibility:
                return Set(sortedDeclarations.map(\.category).map(\.visibility)).count
            case .type:
                return Set(sortedDeclarations.map(\.category).map(\.type)).count
            }
        }()

        var typeDeclaration = typeDeclaration
        var formattedCategories: [Category] = []
        var markedDeclarations: [Declaration] = []

        for (index, (declaration, category)) in sortedDeclarations.enumerated() {
            if options.markCategories,
               numberOfCategories > 1,
               let markComment = category.markComment(from: options.categoryMarkComment, with: options.organizationMode),
               category.shouldBeMarked(in: Set(formattedCategories), for: options.organizationMode)
            {
                formattedCategories.append(category)

                let declarationParser = Formatter(declaration.tokens)
                let indentation = declarationParser.currentIndentForLine(at: 0)

                let endMarkDeclaration = options.lineAfterMarks ? "\n\n" : "\n"
                let markDeclaration = tokenize("\(indentation)\(markComment)\(endMarkDeclaration)")

                // If this declaration is the first declaration in the type scope,
                // make sure the type's opening sequence of tokens ends with
                // at least one blank line so the category separator appears balanced
                if markedDeclarations.isEmpty {
                    typeDeclaration.open = typeDeclaration.open.endingWithBlankLine()
                }

                markedDeclarations.append(.declaration(
                    kind: "comment",
                    tokens: markDeclaration,
                    originalRange: 0 ... 1 // placeholder value
                ))
            }

            if options.blankLineAfterSubgroups,
               let lastIndexOfSameDeclaration = sortedDeclarations.map(\.category).lastIndex(of: category),
               lastIndexOfSameDeclaration == index,
               lastIndexOfSameDeclaration != sortedDeclarations.indices.last
            {
                markedDeclarations.append(declaration.endingWithBlankLine())
            } else {
                markedDeclarations.append(declaration)
            }
        }

        typeDeclaration.body = markedDeclarations
        return typeDeclaration
    }

    /// Removes any existing category separators from the given declarations
    private func removeExistingCategorySeparators(
        from typeBody: [Declaration],
        with mode: DeclarationOrganizationMode,
        using order: ParsedOrder
    ) -> [Declaration] {
        var typeBody = typeBody

        for (declarationIndex, declaration) in typeBody.enumerated() {
            let tokensToInspect: [Token]
            switch declaration {
            case let .declaration(_, tokens, _):
                tokensToInspect = tokens
            case let .type(_, open, _, _, _), let .conditionalCompilation(open, _, _, _):
                // Only inspect the opening tokens of declarations with a body
                tokensToInspect = open
            }

            // Current amount of variants to pair visibility-type is over 300,
            // so we take only categories that could provide typemark that we want to erase
            let potentialCategorySeparators = (
                VisibilityCategory.allCases.map { Category(visibility: $0, type: .classMethod, order: 0) }
                    + DeclarationType.allCases.map { Category(visibility: .visibility(.open), type: $0, order: 0) }
                    + DeclarationType.allCases.map { Category(visibility: .explicit($0), type: .classMethod, order: 0) }
                    + order.filter { $0.comment != nil }
            ).flatMap {
                Array(Set([
                    // The user's specific category separator template
                    $0.markComment(from: options.categoryMarkComment, with: mode),
                    // Other common variants that we would want to replace with the correct variant
                    $0.markComment(from: "%c", with: mode),
                    $0.markComment(from: "// MARK: %c", with: mode),
                ]))
            }.compactMap { $0 }

            let parser = Formatter(tokensToInspect)

            parser.forEach(.startOfScope("//")) { commentStartIndex, _ in
                // Only look at top-level comments inside of the type body
                guard parser.currentScope(at: commentStartIndex) == nil else {
                    return
                }

                // Check if this comment matches an expected category separator comment
                for potentialSeparatorComment in potentialCategorySeparators {
                    let potentialCategorySeparator = tokenize(potentialSeparatorComment)
                    let potentialSeparatorRange = commentStartIndex ..< (commentStartIndex + potentialCategorySeparator.count)

                    guard parser.tokens.indices.contains(potentialSeparatorRange.upperBound),
                          let nextNonwhitespaceIndex = parser.index(of: .nonSpaceOrLinebreak, after: potentialSeparatorRange.upperBound)
                    else { continue }

                    // Check the edit distance of this existing comment with the potential
                    // valid category separators for this category. If they are similar or identical,
                    // we'll want to replace the existing comment with the correct comment.
                    let existingComment = sourceCode(for: Array(parser.tokens[potentialSeparatorRange]))
                    let minimumEditDistance = Int(0.2 * Float(existingComment.count))

                    guard existingComment.lowercased().editDistance(from: potentialSeparatorComment.lowercased())
                        <= minimumEditDistance
                    else { continue }

                    // Makes sure there are only whitespace or other comments before this comment.
                    // Otherwise, we don't want to remove it.
                    let tokensBeforeComment = parser.tokens[0 ..< commentStartIndex]
                    guard !tokensBeforeComment.contains(where: { !$0.isSpaceOrCommentOrLinebreak }) else {
                        continue
                    }

                    // If we found a matching comment, remove it and all subsequent empty lines
                    let startOfCommentLine = parser.startOfLine(at: commentStartIndex)
                    let startOfNextDeclaration = parser.startOfLine(at: nextNonwhitespaceIndex)
                    parser.removeTokens(in: startOfCommentLine ..< startOfNextDeclaration)

                    // Move any tokens from before the category separator into the previous declaration.
                    // This makes sure that things like comments stay grouped in the same category.
                    if declarationIndex != 0, startOfCommentLine != 0 {
                        // Remove the tokens before the category separator from this declaration...
                        let rangeBeforeComment = 0 ..< startOfCommentLine
                        let tokensBeforeCommentLine = Array(parser.tokens[rangeBeforeComment])
                        parser.removeTokens(in: rangeBeforeComment)

                        // ... and append them to the end of the previous declaration
                        typeBody[declarationIndex - 1] = typeBody[declarationIndex - 1].mapClosingTokens {
                            $0 + tokensBeforeCommentLine
                        }
                    }

                    // Apply the updated tokens back to this declaration
                    typeBody[declarationIndex] = typeBody[declarationIndex].mapOpeningTokens { _ in
                        parser.tokens
                    }
                }
            }
        }

        return typeBody
    }
}

// MARK: - Helpers

extension Formatter {
    /// Recursively calls the `operation` for every declaration in the source file
    func forEachRecursiveDeclaration(_ operation: (Declaration) -> Void) {
        forEachRecursiveDeclarations(parseDeclarations(), operation)
    }

    /// Applies `operation` to every recursive declaration of the given declarations
    func forEachRecursiveDeclarations(
        _ declarations: [Declaration],
        _ operation: (Declaration) -> Void
    ) {
        for declaration in declarations {
            operation(declaration)
            if let body = declaration.body {
                forEachRecursiveDeclarations(body, operation)
            }
        }
    }

    /// Applies `mapRecursiveDeclarations` in place
    func mapRecursiveDeclarations(with transform: (Declaration) -> Declaration) {
        let updatedDeclarations = mapRecursiveDeclarations(parseDeclarations()) { declaration, _ in
            transform(declaration)
        }
        let updatedTokens = updatedDeclarations.flatMap { $0.tokens }
        replaceTokens(in: tokens.indices, with: updatedTokens)
    }

    /// Applies `transform` to every recursive declaration of the given declarations
    func mapRecursiveDeclarations(
        _ declarations: [Declaration], in stack: [Declaration] = [],
        with transform: (Declaration, _ stack: [Declaration]) -> Declaration
    ) -> [Declaration] {
        declarations.map { declaration in
            let mapped = transform(declaration, stack)
            switch mapped {
            case let .type(kind, open, body, close, originalRange):
                return .type(
                    kind: kind,
                    open: open,
                    body: mapRecursiveDeclarations(body, in: stack + [mapped], with: transform),
                    close: close,
                    originalRange: originalRange
                )

            case let .conditionalCompilation(open, body, close, originalRange):
                return .conditionalCompilation(
                    open: open,
                    body: mapRecursiveDeclarations(body, in: stack + [mapped], with: transform),
                    close: close,
                    originalRange: originalRange
                )

            case .declaration:
                return declaration
            }
        }
    }

    /// Performs some declaration mapping for each body declaration in this declaration
    /// (including any declarations nested in conditional compilation blocks,
    ///  but not including declarations dested within child types).
    func mapBodyDeclarations(
        in declaration: Declaration,
        with transform: (Declaration) -> Declaration
    ) -> Declaration {
        switch declaration {
        case let .type(kind, open, body, close, originalRange):
            return .type(
                kind: kind,
                open: open,
                body: mapBodyDeclarations(body, with: transform),
                close: close,
                originalRange: originalRange
            )

        case let .conditionalCompilation(open, body, close, originalRange):
            return .conditionalCompilation(
                open: open,
                body: mapBodyDeclarations(body, with: transform),
                close: close,
                originalRange: originalRange
            )

        case .declaration:
            // No work to do, because plain declarations don't have bodies
            return declaration
        }
    }

    private func mapBodyDeclarations(
        _ body: [Declaration],
        with transform: (Declaration) -> Declaration
    ) -> [Declaration] {
        body.map { bodyDeclaration in
            // Apply `mapBodyDeclaration` to each declaration in the body
            switch bodyDeclaration {
            case .declaration, .type:
                return transform(bodyDeclaration)

            // Recursively step through conditional compilation blocks
            // since their body tokens are effectively body tokens of the parent type
            case .conditionalCompilation:
                return mapBodyDeclarations(in: bodyDeclaration, with: transform)
            }
        }
    }

    /// Performs some generic mapping for each declaration in the given array,
    /// stepping through conditional compilation blocks (but not into the body
    /// of other nested types)
    func mapDeclarations<T>(
        _ declarations: [Declaration],
        with transform: (Declaration) -> T
    ) -> [T] {
        declarations.flatMap { declaration -> [T] in
            switch declaration {
            case .declaration, .type:
                return [transform(declaration)]
            case let .conditionalCompilation(_, body, _, _):
                return mapDeclarations(body, with: transform)
            }
        }
    }

    /// Removes the given visibility keyword from the given declaration
    func remove(_ visibilityKeyword: Visibility, from declaration: Declaration) -> Declaration {
        declaration.mapOpeningTokens { openTokens in
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

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func add(_ visibilityKeyword: Visibility, to declaration: Declaration) -> Declaration {
        var declaration = declaration

        if let existingVisibilityKeyword = visibility(of: declaration) {
            declaration = remove(existingVisibilityKeyword, from: declaration)
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

        var numberOfTrailingLinebreaks = self.numberOfTrailingLinebreaks()

        // Make sure there are at least two newlines,
        // so we get a blank line between individual declaration types
        while numberOfTrailingLinebreaks < 2 {
            parser.insertLinebreak(at: parser.tokens.count)
            numberOfTrailingLinebreaks += 1
        }

        return parser.tokens
    }

    /// Updates the given tokens so it ends with no blank lines
    /// (e.g. so it ends with one newline)
    func endingWithoutBlankLine() -> [Token] {
        let parser = Formatter(self)

        var numberOfTrailingLinebreaks = self.numberOfTrailingLinebreaks()

        // Make sure there are at least two newlines,
        // so we get a blank line between individual declaration types
        while numberOfTrailingLinebreaks > 1 {
            parser.removeLastToken()
            numberOfTrailingLinebreaks -= 1
        }

        return parser.tokens
    }

    // The number of trailing line breaks in this array of tokens
    func numberOfTrailingLinebreaks() -> Int {
        let parser = Formatter(self)

        var numberOfTrailingLinebreaks = 0
        var searchIndex = parser.tokens.count - 1

        while searchIndex > 0,
              let token = parser.token(at: searchIndex),
              token.isSpaceOrCommentOrLinebreak
        {
            if token.isLinebreak {
                numberOfTrailingLinebreaks += 1
            }

            searchIndex -= 1
        }

        return numberOfTrailingLinebreaks
    }
}
