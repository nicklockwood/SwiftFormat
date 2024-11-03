//
//  DeclarationV2.swift
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
protocol DeclarationV2: AnyObject {
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
    var parent: DeclarationV2? { get set }
}

enum DeclarationKind {
    /// A simple declaration without any child declarations, representing a property, function, etc.
    case declaration(SimpleDeclaration)
    /// A type with a body, representing a class, struct, enum, extension, etc.
    case type(TypeDeclaration)
    /// A conditional compilation condition with a body.
    case conditionalCompilation(ConditionalCompilationDeclaration)
}

extension DeclarationV2 {
    /// The tokens that make up this declaration
    var tokens: ArraySlice<Token> {
        formatter.tokens[range]
    }

    /// The index of this declaration's keyword in the associated formatter.
    /// Assumes that the declaration has not been invalidated, and still contains its `keyword`.
    var keywordIndex: Int {
        let expectedKeywordToken: Token
        switch kind {
        case .declaration, .type:
            expectedKeywordToken = .keyword(keyword)
        case .conditionalCompilation:
            expectedKeywordToken = .startOfScope("#if")
        }

        guard let keywordIndex = formatter.index(of: expectedKeywordToken, after: range.lowerBound - 1) else {
            assertionFailure("Declaration \(self) is no longer valid.")
            return range.lowerBound
        }

        return keywordIndex
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
    var body: [DeclarationV2]? {
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
    var asPropertyDeclaration: Formatter.PropertyDeclaration? {
        guard keyword == "let" || keyword == "var" else { return nil }
        return formatter.parsePropertyDeclaration(atIntroducerIndex: keywordIndex)
    }

    /// The `TypeDeclaration` for this declaration, if it's a type with a body.
    var asTypeDeclaration: TypeDeclaration? {
        self as? TypeDeclaration
    }

    /// A list of all declarations that are a parent of this declaration
    var parentDeclarations: [DeclarationV2] {
        guard let parent = parent else { return [] }
        return parent.parentDeclarations + [parent]
    }

    /// Removes this declaration from the source file.
    /// After this point, this declaration reference is no longer valid.
    func remove() {
        formatter.unregisterDeclaration(self)
        formatter.removeTokens(in: range)
    }
}

/// A simple declaration without any child declarations, representing a property, function, etc.
final class SimpleDeclaration: DeclarationV2 {
    init(keyword: String, range: ClosedRange<Int>, formatter: Formatter) {
        assert(!keyword.isEmpty)
        self.keyword = keyword
        self.range = range
        self.formatter = formatter
        formatter.registerDeclaration(self)
    }

    var keyword: String
    var range: ClosedRange<Int>
    weak var parent: DeclarationV2?
    let formatter: Formatter

    var kind: DeclarationKind {
        .declaration(self)
    }
}

/// A type with a body, representing a class, struct, enum, extension, etc.
final class TypeDeclaration: DeclarationV2 {
    init(keyword: String, range: ClosedRange<Int>, body: [DeclarationV2], formatter: Formatter) {
        assert(!keyword.isEmpty)
        self.keyword = keyword
        self.range = range
        self.body = body
        self.formatter = formatter

        formatter.registerDeclaration(self)
        for child in body {
            child.parent = self
        }
    }

    var keyword: String
    var range: ClosedRange<Int>
    var body: [DeclarationV2]
    weak var parent: DeclarationV2?
    let formatter: Formatter

    var kind: DeclarationKind {
        .type(self)
    }

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
final class ConditionalCompilationDeclaration: DeclarationV2 {
    init(range: ClosedRange<Int>, body: [DeclarationV2], formatter: Formatter) {
        self.range = range
        self.body = body
        self.formatter = formatter

        formatter.registerDeclaration(self)
        for child in body {
            child.parent = self
        }
    }

    let keyword = "#if"
    var range: ClosedRange<Int>
    var body: [DeclarationV2]
    weak var parent: DeclarationV2?
    let formatter: Formatter

    var kind: DeclarationKind {
        .conditionalCompilation(self)
    }
}

extension Collection where Element == DeclarationV2 {
    /// Performs the given operation for each declaration in this tree of declarations.
    func forEachRecursiveDeclaration(_ operation: (DeclarationV2) -> Void) {
        for declaration in self {
            operation(declaration)
            (declaration.body ?? []).forEachRecursiveDeclaration(operation)
        }
    }
}

extension DeclarationV2 {
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

/// We want to avoid including a Hashable requirement on DeclarationV2,
/// so instead you can use this container type if you need a Hashable declaration.
/// Uses reference identity of the `DeclarationV2` class value.
struct HashableDeclaration: Hashable {
    let declaration: DeclarationV2

    static func == (lhs: HashableDeclaration, rhs: HashableDeclaration) -> Bool {
        lhs.declaration === rhs.declaration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(declaration))
    }
}
