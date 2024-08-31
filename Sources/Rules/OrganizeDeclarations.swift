//
//  OrganizeDeclarations.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 8/16/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    static let organizeDeclarations = FormatRule(
        help: "Organize declarations within class, struct, enum, actor, and extension bodies.",
        runOnceOnly: true,
        disabledByDefault: true,
        orderAfter: [.extensionAccessControl, .redundantFileprivate],
        options: [
            "categorymark", "markcategories", "beforemarks",
            "lifecycle", "organizetypes", "structthreshold", "classthreshold",
            "enumthreshold", "extensionlength", "organizationmode",
            "visibilityorder", "typeorder", "visibilitymarks", "typemarks",
            "groupblanklines", "sortswiftuiprops",
        ],
        sharedOptions: ["sortedpatterns", "lineaftermarks"]
    ) { formatter in
        guard !formatter.options.fragment else { return }

        formatter.mapRecursiveDeclarations { declaration in
            switch declaration {
            // Organize the body of type declarations
            case let .type(kind, open, body, close, originalRange):
                let organizedType = formatter.organizeDeclaration((kind, open, body, close))
                return .type(
                    kind: organizedType.kind,
                    open: organizedType.open,
                    body: organizedType.body,
                    close: organizedType.close,
                    originalRange: originalRange
                )

            case .conditionalCompilation, .declaration:
                return declaration
            }
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
    func typeLengthExceedsOrganizationThreshold(_ typeDeclaration: TypeDeclaration) -> Bool {
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
            .flatMap(\.tokens)
            .filter(\.isLinebreak)
            .count

        return lineCount >= organizationThreshold
    }

    typealias CategorizedDeclaration = (declaration: Declaration, category: Category)

    /// Sorts the given categorized declarations based on the defined category ordering
    func sortCategorizedDeclarations(
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

    func sortDeclarations(
        _ categorizedDeclarations: [CategorizedDeclaration],
        sortAlphabeticallyWithinSubcategories: Bool
    ) -> [CategorizedDeclaration] {
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

                if options.alphabetizeSwiftUIPropertyTypes,
                   lhs.category.type == rhs.category.type,
                   let lhsSwiftUIProperty = lhs.declaration.swiftUIPropertyWrapper,
                   let rhsSwiftUIProperty = rhs.declaration.swiftUIPropertyWrapper
                {
                    return lhsSwiftUIProperty.localizedCompare(rhsSwiftUIProperty) == .orderedAscending
                }

                // Respect the original declaration ordering when the categories and types are the same
                return lhsOriginalIndex < rhsOriginalIndex
            })
            .map(\.element)
    }

    /// Whether or not type members should additionally be sorted alphabetically
    /// within individual subcategories
    func shouldSortAlphabeticallyWithinSubcategories(in typeDeclaration: TypeDeclaration) -> Bool {
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
    func affectsSynthesizedMemberwiseInitializer(
        _ declaration: Declaration,
        _ category: Category
    ) -> Bool {
        switch category.type {
        case .swiftUIPropertyWrapper, .instanceProperty:
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
    func preservesSynthesizedMemberwiseInitializer(
        _ lhs: [CategorizedDeclaration],
        _ rhs: [CategorizedDeclaration]
    ) -> Bool {
        let lhsPropertiesOrder = lhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.category) }
            .map(\.declaration)

        let rhsPropertiesOrder = rhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration, $0.category) }
            .map(\.declaration)

        return lhsPropertiesOrder == rhsPropertiesOrder
    }

    // Finds all of the consecutive groups of property declarations in the type body
    func consecutivePropertyDeclarationGroups(in body: [Declaration]) -> [[Declaration]] {
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
    func addCategorySeparators(
        to typeDeclaration: TypeDeclaration,
        sortedDeclarations: [CategorizedDeclaration]
    ) -> TypeDeclaration {
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
    func removeExistingCategorySeparators(
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
        let visibility = declaration.visibility() ?? .internal

        let type = declaration.declarationType(
            allowlist: order.map(\.type),
            beforeMarks: options.beforeMarks,
            lifecycleMethods: options.lifecycleMethods
        )

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

    func parseMarks<T: RawRepresentable>(
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
