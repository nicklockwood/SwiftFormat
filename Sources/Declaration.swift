//
//  Declaration.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 10/27/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

/// A declaration, like a property, function, or type.
/// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/declarations/
///
/// Forms a tree of declarations, since `type` declarations have a body
/// that contains child declarations.
///
/// Tracks a specific range in the associated formatter. Declarations are
/// automatically kept up-to-date as tokens are added, removed, or modified
/// in the associated formatter.
///
protocol Declaration: AnyObject, CustomDebugStringConvertible {
    /// The keyword of this declaration (`class`, `struct`, `func`, `let`, `var`, etc.)
    var keyword: String { get }

    /// The range of this declaration in the associated formatter.
    /// Updates automatically when adding or removing tokens in the associated formatter.
    var range: ClosedRange<Int> { get set }

    /// The formatter that this declaration is associated with.
    /// Modifications in this formatter automatically update the `range` of this declaration.
    var formatter: Formatter { get }

    /// The concrete kind of declaration represented by this value.
    var kind: DeclarationKind { get }

    /// This declaration's parent declaration, if this isn't a top-level declaration.
    var parent: Declaration? { get set }
}

enum DeclarationKind {
    /// A simple declaration without any child declarations, representing a property, function, etc.
    case declaration(SimpleDeclaration)
    /// A type with a body, representing a class, struct, enum, extension, etc.
    case type(TypeDeclaration)
    /// A conditional compilation condition with a body.
    case conditionalCompilation(ConditionalCompilationDeclaration)
}

extension Declaration {
    /// The tokens that make up this declaration
    var tokens: ArraySlice<Token> {
        formatter.tokens[range]
    }

    /// Whether or not this declaration reference is still valid
    var isValid: Bool {
        _keywordIndex != nil
    }

    /// The index of this declaration's keyword in the associated formatter.
    /// Assumes that the declaration has not been invalidated, and still contains its `keyword`.
    var keywordIndex: Int {
        guard let keywordIndex = _keywordIndex else {
            assertionFailure("Declaration \(self) is no longer valid.")
            return range.lowerBound
        }

        return keywordIndex
    }

    /// The index of this declaration's keyword token, if the declaration is still valid.
    var _keywordIndex: Int? {
        let expectedKeywordToken: Token
        switch kind {
        case .declaration, .type:
            expectedKeywordToken = .keyword(keyword)
        case .conditionalCompilation:
            expectedKeywordToken = .startOfScope("#if")
        }

        return formatter.index(of: expectedKeywordToken, after: range.lowerBound - 1)
    }

    /// The name of this declaration, which is always the identifier or type following the primary keyword.
    var name: String? {
        formatter.declarationName(keywordIndex: keywordIndex)
    }

    /// The fully qualified name of this declaration, including the name of each parent declaration.
    var fullyQualifiedName: String? {
        guard let name = name else { return nil }
        let typeNames = parentDeclarations.compactMap(\.name) + [name]
        return typeNames.joined(separator: ".")
    }

    /// A `Hashable` reference to this declaration.
    var identity: AnyHashable {
        ObjectIdentifier(self)
    }

    /// The child declarations of this declaration's body, if present.
    @_disfavoredOverload
    var body: [Declaration]? {
        switch kind {
        case .declaration:
            return nil
        case let .type(type):
            return type.body
        case let .conditionalCompilation(conditionalCompilation):
            return conditionalCompilation.body
        }
    }

    /// Whether or not this declaration defines a type (a class, enum, etc, but not an extension)
    var definesType: Bool {
        var typeKeywords = Token.swiftTypeKeywords
        typeKeywords.remove("extension")
        return typeKeywords.contains(keyword)
    }

    /// The start index of this declaration's modifiers,
    /// which represents the first non-space / non-comment token in the declaration.
    var startOfModifiersIndex: Int {
        formatter.startOfModifiers(at: keywordIndex, includingAttributes: true)
    }

    /// The modifiers before this declaration's keyword, including any attributes.
    var modifiers: [String] {
        var allModifiers = [String]()
        _ = formatter.modifiersForDeclaration(at: keywordIndex, contains: { _, modifier in
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

    /// Whether or not this declaration represents a static stored property
    var isStaticStoredProperty: Bool {
        modifiers.contains("static") && isStoredProperty
    }

    /// Whether or not this declaration represents a stored property
    var isStoredProperty: Bool {
        formatter.isStoredProperty(atIntroducerIndex: keywordIndex)
    }

    /// Full information about this `let` or `var` property declaration.
    func parsePropertyDeclaration() -> Formatter.PropertyDeclaration? {
        guard keyword == "let" || keyword == "var" else { return nil }
        return formatter.parsePropertyDeclaration(atIntroducerIndex: keywordIndex)
    }

    /// The `TypeDeclaration` for this declaration, if it's a type with a body.
    var asTypeDeclaration: TypeDeclaration? {
        self as? TypeDeclaration
    }

    /// A list of all declarations that are a parent of this declaration
    var parentDeclarations: [Declaration] {
        guard let parent = parent else { return [] }
        return parent.parentDeclarations + [parent]
    }

    /// The `CustomDebugStringConvertible` representation of this declaration
    var debugDescription: String {
        guard isValid else {
            return "Invalid \(keyword) declaration reference at \(range)"
        }

        let indentation = formatter.currentIndentForLine(at: range.lowerBound)
        return """
        \(indentation)/* \(keyword) declaration at \(range) */
        \(tokens.string)
        """
    }

    /// Removes this declaration from the source file.
    /// After this point, this declaration reference is no longer valid.
    func remove() {
        formatter.unregisterDeclaration(self)
        formatter.removeTokens(in: range)
    }

    /// Appends the given tokens to the end of this declaration.
    func append(_ tokens: [Token]) {
        formatter.insert(tokens, at: range.upperBound)
    }
}

/// A simple declaration without any child declarations, representing a property, function, etc.
final class SimpleDeclaration: Declaration {
    init(keyword: String, range: ClosedRange<Int>, formatter: Formatter) {
        self.keyword = keyword
        self.range = range
        self.formatter = formatter
        formatter.registerDeclaration(self)
    }

    deinit {
        formatter.unregisterDeclaration(self)
    }

    var keyword: String
    var range: ClosedRange<Int>
    let formatter: Formatter
    weak var parent: Declaration?

    var kind: DeclarationKind {
        .declaration(self)
    }
}

/// A type with a body, representing a class, struct, enum, extension, etc.
final class TypeDeclaration: Declaration {
    init(keyword: String, range: ClosedRange<Int>, body: [Declaration], formatter: Formatter) {
        self.keyword = keyword
        self.range = range
        self.body = body
        self.formatter = formatter

        formatter.registerDeclaration(self)
        for child in body {
            child.parent = self
        }
    }

    deinit {
        formatter.unregisterDeclaration(self)
    }

    var keyword: String
    var range: ClosedRange<Int>
    var body: [Declaration]
    let formatter: Formatter
    weak var parent: Declaration?

    var kind: DeclarationKind {
        .type(self)
    }

    /// Replaces the body declarations of this type.
    /// The updated array must contain the same set of declarations, just in a different order.
    func updateBody(to newBody: [Declaration]) {
        assert(!body.isEmpty)

        // Store the expected tokens associated with each declaration.
        // This is necessary since the declarations' range values will temporarily be invalid.
        var declarationTokens: [AnyHashable: [Token]] = [:]
        var childDeclarationsNeedingUpdate = [AnyHashable: (originalIndexInParent: Int, originalTokens: [Token])]()

        for declaration in newBody {
            declarationTokens[declaration.identity] = Array(declaration.tokens)

            // The body of this declaration won't be modified, but since we're update its range
            // we have to also update the range of any children. Record the relative index of each child declaration
            // so we can restore it later.
            declaration.body?.forEachRecursiveDeclaration { childDeclaration in
                let parent = declaration
                let indexInParent = childDeclaration.range.lowerBound - parent.range.lowerBound
                childDeclarationsNeedingUpdate[childDeclaration.identity] = (originalIndexInParent: indexInParent, originalTokens: Array(childDeclaration.tokens))
                formatter.unregisterDeclaration(childDeclaration)
            }
        }

        // Unlink the declarations and the formatter while we reorder the tokens
        for declaration in body + newBody {
            formatter.unregisterDeclaration(declaration)
        }

        // Replace the contents of this declaration's body in the underlying formatter
        let oldBodyRange = body.first!.range.lowerBound ... body.last!.range.upperBound
        let newBodyTokens = newBody.flatMap(\.tokens)
        formatter.diffAndReplaceTokens(in: oldBodyRange, with: newBodyTokens)

        // Re-register each of the declarations in the body
        var currentBodyIndex = oldBodyRange.lowerBound
        for declaration in newBody {
            let tokens = declarationTokens[declaration.identity]!
            declaration.range = ClosedRange(currentBodyIndex ..< (currentBodyIndex + tokens.count))
            currentBodyIndex += tokens.count

            formatter.registerDeclaration(declaration)
            assert(Array(declaration.tokens) == tokens)
            assert(declaration.isValid)

            // Re-register each of the child declarations of this declaration
            declaration.body?.forEachRecursiveDeclaration { childDeclaration in
                guard let (originalIndexInParent, originalTokens) = childDeclarationsNeedingUpdate[childDeclaration.identity] else { return }
                let parent = declaration
                let newIndexInFile = parent.range.lowerBound + originalIndexInParent
                let newRangeInFile = ClosedRange(newIndexInFile ..< (newIndexInFile + originalTokens.count))
                childDeclaration.range = newRangeInFile

                formatter.registerDeclaration(childDeclaration)
                assert(Array(childDeclaration.tokens) == originalTokens)
                assert(childDeclaration.isValid)
            }
        }

        body = newBody
    }
}

extension TypeDeclaration {
    /// The index of the open brace (`{`) before the type's body.
    /// Assumes that the declaration has not been invalidated.
    var openBraceIndex: Int {
        guard let openBraceIndex = formatter.index(of: .startOfScope("{"), in: keywordIndex ..< range.upperBound) else {
            assertionFailure("Declaration \(self) is no longer valid.")
            return keywordIndex
        }

        return openBraceIndex
    }

    /// The list of conformances of this type, not including any constraints following a `where` clause.
    var conformances: [(conformance: String, index: Int)] {
        formatter.parseConformancesOfType(atKeywordIndex: keywordIndex)
    }
}

/// A conditional compilation condition with a body.
final class ConditionalCompilationDeclaration: Declaration {
    init(range: ClosedRange<Int>, body: [Declaration], formatter: Formatter) {
        self.range = range
        self.body = body
        self.formatter = formatter

        formatter.registerDeclaration(self)
        for child in body {
            child.parent = self
        }
    }

    deinit {
        formatter.unregisterDeclaration(self)
    }

    let keyword = "#if"
    var range: ClosedRange<Int>
    var body: [Declaration]
    let formatter: Formatter
    weak var parent: Declaration?

    var kind: DeclarationKind {
        .conditionalCompilation(self)
    }
}

// MARK: - Helpers

extension Collection where Element == Declaration {
    /// Performs the given operation for each declaration in this tree of declarations.
    func forEachRecursiveDeclaration(_ operation: (Declaration) -> Void) {
        for declaration in self {
            operation(declaration)
            (declaration.body ?? []).forEachRecursiveDeclaration(operation)
        }
    }
}

extension Declaration {
    /// The range of tokens before the first `nonSpaceOrCommentOrLinebreak` token
    /// where leading comments like MARKs, directives, and documentation are located.
    var leadingCommentRange: Range<Int> {
        let firstTokenIndex = formatter.index(
            of: .nonSpaceOrCommentOrLinebreak,
            after: range.lowerBound - 1
        ) ?? range.lowerBound

        return range.lowerBound ..< firstTokenIndex
    }

    /// Ensures that this declaration ends with at least one trailing blank line,
    /// by a blank like to the end of this declaration if not already present.
    func addTrailingBlankLineIfNeeded() {
        while tokens.numberOfTrailingLinebreaks() < 2 {
            formatter.insertLinebreak(at: range.upperBound)
        }
    }

    /// Ensures that this declaration doesn't end with a trailing blank line
    /// by removing any trailing blank lines.
    func removeTrailingBlankLinesIfPresent() {
        while tokens.numberOfTrailingLinebreaks() > 1 {
            guard let lastNewlineIndex = formatter.lastIndex(of: .linebreak, in: Range(range)) else { break }
            formatter.removeTokens(in: lastNewlineIndex ... range.upperBound)
        }
    }
}

extension RandomAccessCollection where Element == Token, Index == Int {
    // The number of trailing newlines in this array of tokens,
    // taking into account any spaces that may be between the linebreaks.
    func numberOfTrailingLinebreaks() -> Int {
        guard !isEmpty else { return 0 }

        var numberOfTrailingLinebreaks = 0
        var searchIndex = indices.last!

        while searchIndex >= indices.first!,
              self[searchIndex].isSpaceOrLinebreak
        {
            if self[searchIndex].isLinebreak {
                numberOfTrailingLinebreaks += 1
            }

            searchIndex -= 1
        }

        return numberOfTrailingLinebreaks
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
        switch kind {
        case .declaration, .type:
            return formatter.declarationVisibility(keywordIndex: keywordIndex)

        case let .conditionalCompilation(conditionalCompilation):
            // Conditional compilation blocks themselves don't have a category or visbility-level,
            // but we still have to assign them a category for the sorting algorithm to function.
            // A reasonable heuristic here is to simply use the category of the first declaration
            // inside the conditional compilation block.
            return conditionalCompilation.body.first?.visibility()
        }
    }

    /// Adds the given visibility keyword to the given declaration,
    /// replacing any existing visibility keyword.
    func addVisibility(_ visibilityKeyword: Visibility) {
        formatter.addDeclarationVisibility(visibilityKeyword, declarationKeywordIndex: keywordIndex)
    }

    /// Removes the given visibility keyword from the given declaration
    func removeVisibility(_ visibilityKeyword: Visibility) {
        formatter.removeDeclarationVisibility(visibilityKeyword, declarationKeywordIndex: keywordIndex)
    }
}
