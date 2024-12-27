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

        formatter.parseDeclarationsV2().forEachRecursiveDeclaration { declaration in
            // Organize the body of type declarations
            guard let typeDeclaration = declaration.asTypeDeclaration else { return }
            formatter.organizeDeclaration(typeDeclaration)
        }
    } examples: {
        """
        Default value for `--visibilityorder` when using `--organizationmode visibility`:
        `\(VisibilityCategory.defaultOrdering(for: .visibility).map(\.rawValue).joined(separator: ", "))`

        Default value for `--visibilityorder` when using `--organizationmode type`:
        `\(VisibilityCategory.defaultOrdering(for: .type).map(\.rawValue).joined(separator: ", "))`

        **NOTE:** When providing custom arguments for `--visibilityorder` the following entries must be included:
        `\(VisibilityCategory.essentialCases.map(\.rawValue).joined(separator: ", "))`

        Default value for `--typeorder` when using `--organizationmode visibility`:
        `\(DeclarationType.defaultOrdering(for: .visibility).map(\.rawValue).joined(separator: ", "))`

        Default value for `--typeorder` when using `--organizationmode type`:
        `\(DeclarationType.defaultOrdering(for: .type).map(\.rawValue).joined(separator: ", "))`

        **NOTE:** The follow declaration types must be included in either `--typeorder` or `--visibilityorder`:
        `\(DeclarationType.essentialCases.map(\.rawValue).joined(separator: ", "))`

        **NOTE:** The Swift compiler automatically synthesizes a memberwise `init` for `struct` types.

        To allow SwiftFormat to reorganize your code effectively, you must explicitly declare an `init`.
        Without this declaration, only functions will be reordered, while properties will remain in their original order. 

        `--organizationmode visibility` (default)

        ```diff
          public class Foo {
        -     public func c() -> String {}
        -
        -     public let a: Int = 1
        -     private let g: Int = 2
        -     let e: Int = 2
        -     public let b: Int = 3
        -
        -     public func d() {}
        -     func f() {}
        -     init() {}
        -     deinit() {}
         }

          public class Foo {
        +
        +     // MARK: Lifecycle
        +
        +     init() {}
        +     deinit() {}
        +
        +     // MARK: Public
        +
        +     public let a: Int = 1
        +     public let b: Int = 3
        +
        +     public func c() -> String {}
        +     public func d() {}
        +
        +     // MARK: Internal
        +
        +     let e: Int = 2
        +
        +     func f() {}
        +
        +     // MARK: Private
        +
        +     private let g: Int = 2
        +
         }
        ```

        `--organizationmode type`

        ```diff
          public class Foo {
        -     public func c() -> String {}
        -
        -     public let a: Int = 1
        -     private let g: Int = 2
        -     let e: Int = 2
        -     public let b: Int = 3
        -
        -     public func d() {}
        -     func f() {}
        -     init() {}
        -     deinit() {}
         }

          public class Foo {
        +
        +     // MARK: Properties
        +
        +     public let a: Int = 1
        +     public let b: Int = 3
        +
        +     let e: Int = 2
        +
        +     private let g: Int = 2
        +
        +     // MARK: Lifecycle
        +
        +     init() {}
        +     deinit() {}
        +
        +     // MARK: Functions
        +
        +     public func c() -> String {}
        +     public func d() {}
        +
         }
        ```
        """
    }
}

// MARK: - organizeDeclaration

extension Formatter {
    /// Organizes the given type declaration into sorted categories
    func organizeDeclaration(_ typeDeclaration: TypeDeclaration) {
        guard !typeDeclaration.body.isEmpty,
              options.organizeTypes.contains(typeDeclaration.keyword),
              typeLengthExceedsOrganizationThreshold(typeDeclaration)
        else { return }

        // Parse category order from options
        let categoryOrder = self.categoryOrder(for: options.organizationMode)

        // Adjust the ranges of the type's body declarations so that any
        // existing MARK comment is the first tokens in any declaration.
        adjustBodyDeclarationRanges(in: typeDeclaration, order: categoryOrder)

        // Track the consecutive groups of property declarations so we can avoid inserting
        // blank lines between elements in the group if possible.
        let consecutivePropertyGroups = consecutivePropertyDeclarationGroups(in: typeDeclaration)
            .filter { group in
                // Only track declaration groups where the group as a whole is followed by a
                // blank line, since otherwise the declarations can be reordered without issues.
                guard let lastDeclarationInGroup = group.last else { return false }
                return lastDeclarationInGroup.tokens.numberOfTrailingLinebreaks() > 1
            }

        // Categorize each of the declarations into their primary groups
        let categorizedDeclarations = typeDeclaration.body.map { declaration in
            let declarationCategory = category(
                of: declaration,
                for: options.organizationMode,
                using: categoryOrder
            )

            return (declaration: declaration, category: declarationCategory)
        }

        // Sort the declarations based on their category and type
        guard let sortedTypeBody = sortCategorizedDeclarations(
            categorizedDeclarations,
            in: typeDeclaration
        ) else { return }

        typeDeclaration.updateBody(to: sortedTypeBody.map(\.declaration))

        // Add a mark comment for each top-level category
        addCategorySeparators(to: sortedTypeBody, in: typeDeclaration, order: categoryOrder)

        // Preserve the expected spacing for any groups of properties that were
        // conseutive in the original declaration ordering.
        preserveConsecutivePropertyGroupSpacing(
            in: typeDeclaration,
            groups: consecutivePropertyGroups,
            order: categoryOrder
        )
    }

    /// Whether or not the length of this types exceeds the minimum threshold to be organized
    func typeLengthExceedsOrganizationThreshold(_ typeDeclaration: TypeDeclaration) -> Bool {
        let organizationThreshold: Int
        switch typeDeclaration.keyword {
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

    typealias CategorizedDeclaration = (declaration: DeclarationV2, category: Category)

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
        if !sortAlphabeticallyWithinSubcategories, typeDeclaration.keyword == "struct",
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
        let customDeclarationSortOrder = customDeclarationSortOrderList(from: categorizedDeclarations)
        return categorizedDeclarations.enumerated()
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

                if lhs.category.type == rhs.category.type,
                   let lhs = lhs.declaration.swiftUIPropertyWrapper,
                   let rhs = rhs.declaration.swiftUIPropertyWrapper
                {
                    switch options.swiftUIPropertiesSortMode {
                    case .none:
                        break
                    case .alphabetize:
                        return lhs.localizedCompare(rhs) == .orderedAscending
                    case .firstAppearanceSort:
                        return customDeclarationSortOrder.areInRelativeOrder(lhs: lhs, rhs: rhs)
                    }
                }

                // Respect the original declaration ordering when the categories and types are the same
                return lhsOriginalIndex < rhsOriginalIndex
            })
            .map(\.element)
    }

    func customDeclarationSortOrderList(from categorizedDeclarations: [CategorizedDeclaration]) -> [String] {
        guard options.swiftUIPropertiesSortMode == .firstAppearanceSort else { return [] }
        return categorizedDeclarations
            .compactMap(\.declaration.swiftUIPropertyWrapper)
            .firstElementAppearanceOrder()
    }

    /// Whether or not type members should additionally be sorted alphabetically
    /// within individual subcategories
    func shouldSortAlphabeticallyWithinSubcategories(in typeDeclaration: TypeDeclaration) -> Bool {
        let rangeBeforeKeyword = typeDeclaration.range.lowerBound ..< typeDeclaration.keywordIndex
        // If this type has a leading :sort directive, we sort alphabetically
        // within the subcategories (where ordering is otherwise undefined)
        let shouldSortAlphabeticallyBySortingMark = tokens[rangeBeforeKeyword].contains(where: {
            $0.isCommentBody && $0.string.contains("swiftformat:sort") && !$0.string.contains(":sort:")
        })

        // If this type declaration name contains pattern — sort as well
        let shouldSortAlphabeticallyByDeclarationPattern: Bool = {
            guard let name = typeDeclaration.name else { return false }

            return options.alphabeticallySortedDeclarationPatterns.contains {
                name.contains($0)
            }
        }()

        return shouldSortAlphabeticallyBySortingMark
            || shouldSortAlphabeticallyByDeclarationPattern
    }

    // Whether or not this declaration is an instance property that can affect
    // the parameters struct's synthesized memberwise initializer
    func affectsSynthesizedMemberwiseInitializer(_ declaration: DeclarationV2) -> Bool {
        declaration.isStoredInstanceProperty
    }

    // Whether or not the two given declaration orderings preserve
    // the same synthesized memberwise initializer
    func preservesSynthesizedMemberwiseInitializer(
        _ lhs: [CategorizedDeclaration],
        _ rhs: [CategorizedDeclaration]
    ) -> Bool {
        let lhsPropertiesOrder = lhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration) }
            .map(\.declaration)

        let rhsPropertiesOrder = rhs
            .filter { affectsSynthesizedMemberwiseInitializer($0.declaration) }
            .map(\.declaration)

        return lhsPropertiesOrder.elementsEqual(rhsPropertiesOrder, by: { lhs, rhs in
            lhs === rhs
        })
    }

    // Adjust the ranges of the type's body declarations so that any existing MARK comment
    // is the first token in any declaration. This makes it so that any comment _before_
    // the MARK comment is treated as part of the previous declaration.
    func adjustBodyDeclarationRanges(in typeDeclaration: TypeDeclaration, order: ParsedOrder) {
        for (index, declaration) in typeDeclaration.body.enumerated() {
            guard index != 0 else { continue }

            let matchingComments = matchingCategorySeparatorComments(in: declaration.leadingCommentRange, order: order)
            guard let markCommentRange = matchingComments.first,
                  let newlineBeforeMarkComment = self.index(of: .linebreak, before: markCommentRange.lowerBound)
            else { continue }

            let previousDeclaration = typeDeclaration.body[index - 1]

            previousDeclaration.range = previousDeclaration.range.lowerBound ... newlineBeforeMarkComment
            declaration.range = (newlineBeforeMarkComment + 1) ... declaration.range.upperBound
        }
    }

    /// Adds MARK category separates to the given type
    func addCategorySeparators(
        to sortedDeclarations: [CategorizedDeclaration],
        in typeDeclaration: TypeDeclaration,
        order: ParsedOrder
    ) {
        let numberOfCategories: Int = {
            switch options.organizationMode {
            case .visibility:
                return Set(sortedDeclarations.map(\.category).map(\.visibility)).count
            case .type:
                return Set(sortedDeclarations.map(\.category).map(\.type)).count
            }
        }()

        var formattedCategories: [Category] = []

        for (index, (declaration, category)) in sortedDeclarations.enumerated() {
            if options.markCategories,
               numberOfCategories > 1,
               let markCommentBody = category.markCommentBody(from: options.categoryMarkComment, with: options.organizationMode),
               category.shouldBeMarked(in: Set(formattedCategories), for: options.organizationMode)
            {
                formattedCategories.append(category)

                let indentation = currentIndentForLine(at: declaration.range.lowerBound)
                let markDeclaration = tokenize("\(indentation)// \(markCommentBody)")
                let eligibleCommentRange = declaration.range.lowerBound ..< self.index(of: .nonSpaceOrCommentOrLinebreak, after: declaration.range.lowerBound - 1)!

                let matchingComments = singleLineComments(in: eligibleCommentRange, matching: { commentBody in
                    commentBody == markCommentBody
                })

                if matchingComments.count == 1, let matchingComment = matchingComments.first {
                    // The declaration already has the expetced mark comment.
                    // However, we need to make sure it also has a trailing blank line.
                    if options.lineAfterMarks,
                       let tokenAfterComment = self.index(of: .nonSpaceOrComment, after: matchingComment.upperBound),
                       tokens[tokenAfterComment].isLinebreak,
                       let nextToken = self.index(of: .nonSpaceOrComment, after: tokenAfterComment),
                       !tokens[nextToken].isLinebreak
                    {
                        insertLinebreak(at: tokenAfterComment)
                    }
                } else {
                    removeExistingCategorySeparators(
                        from: declaration,
                        previousDeclaration: index == 0 ? nil : sortedDeclarations[index - 1].declaration,
                        order: order
                    )

                    insertLinebreak(at: declaration.range.lowerBound)
                    if options.lineAfterMarks {
                        insertLinebreak(at: declaration.range.lowerBound)
                    }

                    insert(markDeclaration, at: declaration.range.lowerBound)
                }

                // If this declaration is the first declaration in the type scope,
                // make sure the type's body starts with at least one blank line
                // so the category separator appears balanced
                if index == 0 {
                    var tokensBetweenStartOfScopeAndFirstDeclaration: ArraySlice<Token> {
                        tokens[typeDeclaration.openBraceIndex ..< typeDeclaration.body[0].range.lowerBound]
                    }

                    while tokensBetweenStartOfScopeAndFirstDeclaration.numberOfTrailingLinebreaks() < 2 {
                        insertLinebreak(at: typeDeclaration.openBraceIndex + 1)
                    }
                }
            } else {
                // Otherwise, this declaration shouldn't have separators
                removeExistingCategorySeparators(
                    from: declaration,
                    previousDeclaration: index == 0 ? nil : sortedDeclarations[index - 1].declaration,
                    order: order
                )
            }

            if options.blankLineAfterSubgroups,
               let lastIndexOfSameDeclaration = sortedDeclarations.map(\.category).lastIndex(of: category),
               lastIndexOfSameDeclaration == index,
               lastIndexOfSameDeclaration != sortedDeclarations.indices.last
            {
                declaration.addTrailingBlankLineIfNeeded()
            }
        }
    }

    /// Removes any existing category separators from the given declarations
    func removeExistingCategorySeparators(
        from declaration: DeclarationV2,
        previousDeclaration: DeclarationV2?,
        order: ParsedOrder
    ) {
        var matchingComments = matchingCategorySeparatorComments(in: declaration.leadingCommentRange, order: order)

        while !matchingComments.isEmpty {
            let commentRange = matchingComments.removeFirst()

            // Makes sure there are only whitespace or other comments before this comment.
            // Otherwise, we don't want to remove it.
            let tokensBeforeComment = tokens[declaration.range.lowerBound ..< commentRange.lowerBound]
            guard !tokensBeforeComment.contains(where: { !$0.isSpaceOrCommentOrLinebreak }),
                  let nextNonwhitespaceIndex = index(of: .nonSpaceOrLinebreak, after: commentRange.upperBound)
            else {
                continue
            }

            // If we found a matching comment, remove it and all subsequent empty lines
            let startOfCommentLine = startOfLine(at: commentRange.lowerBound)
            let startOfNextDeclaration = startOfLine(at: nextNonwhitespaceIndex)
            let rangeToRemove = startOfCommentLine ..< startOfNextDeclaration
            removeTokens(in: rangeToRemove)

            // We specifically iterate from start to end here, instead of in reverse,
            // so we have to manually keep the existing inidices up to date.
            matchingComments = matchingComments.map { commentRange in
                (commentRange.lowerBound - rangeToRemove.count)
                    ... (commentRange.upperBound - rangeToRemove.count)
            }

            // Move any tokens from before the category separator into the previous declaration.
            // This makes sure that things like comments stay grouped in the same category.
            if let previousDeclaration = previousDeclaration, startOfCommentLine != 0 {
                // Remove the tokens before the category separator from this declaration...
                let rangeBeforeComment = min(startOfCommentLine, declaration.range.lowerBound) ..< startOfCommentLine
                let tokensBeforeCommentLine = Array(tokens[rangeBeforeComment])
                removeTokens(in: rangeBeforeComment)

                // ... and append them to the end of the previous declaration
                previousDeclaration.append(tokensBeforeCommentLine)
            }
        }
    }

    /// Finds the set of single-line comments in the given range matching the given closure
    func singleLineComments(
        in range: Range<Int>,
        matching isMatch: (_ commentBody: String) -> Bool
    ) -> [ClosedRange<Int>] {
        var matches = [ClosedRange<Int>]()

        for commentStartIndex in range {
            guard tokens[commentStartIndex] == .startOfScope("//"),
                  let commentBodyIndex = index(after: commentStartIndex, where: \.isCommentBody)
            else { continue }

            if isMatch(tokens[commentBodyIndex].string) {
                matches.append(commentStartIndex ... commentBodyIndex)
            }
        }

        return matches
    }

    /// The set of category separate comments like `// MARK: - Public` in the given range.
    /// Looks for approximate matches using edit distance, not exact matches.
    func matchingCategorySeparatorComments(in range: Range<Int>, order: ParsedOrder) -> [ClosedRange<Int>] {
        // Current amount of variants to pair visibility-type is over 300,
        // so we take only categories that could provide typemark that we want to erase
        let potentialCategorySeparatorCommentBodies = (
            VisibilityCategory.allCases.map { Category(visibility: $0, type: .classMethod, order: 0) }
                + DeclarationType.allCases.map { Category(visibility: .visibility(.open), type: $0, order: 0) }
                + DeclarationType.allCases.map { Category(visibility: .explicit($0), type: .classMethod, order: 0) }
                + order.filter { $0.comment != nil }
        ).flatMap {
            Array(Set([
                // The user's specific category separator template
                $0.markCommentBody(from: options.categoryMarkComment, with: options.organizationMode),
                // Other common variants that we would want to replace with the correct variant
                $0.markCommentBody(from: "%c", with: options.organizationMode),
                $0.markCommentBody(from: "MARK: %c", with: options.organizationMode),
            ]))
        }.compactMap { $0 }

        return singleLineComments(in: range, matching: { commentBody in
            // Check if this comment matches an expected category separator comment
            for potentialSeparatorCommentBody in potentialCategorySeparatorCommentBodies {
                let existingComment = "// \(commentBody)".lowercased()
                let potentialMatch = "// \(potentialSeparatorCommentBody)".lowercased()

                // Check the edit distance of this existing comment with the potential
                // valid category separators for this category. If they are similar or identical,
                // we'll want to replace the existing comment with the correct comment.
                let minimumEditDistance = Int(0.2 * Float(existingComment.count))

                if existingComment.editDistance(from: potentialMatch) <= minimumEditDistance {
                    return true
                }
            }

            return false
        })
    }

    // Preserves the original spacing for groups of properties that were originally consecutive.
    // After sorting, only the final declaration in the group should be followed by a blank line.
    func preserveConsecutivePropertyGroupSpacing(
        in typeDeclaration: TypeDeclaration,
        groups consecutiveGroups: [[DeclarationV2]],
        order: ParsedOrder
    ) {
        for consecutiveGroup in consecutiveGroups {
            guard let lastDeclarationInOriginalOrder = consecutiveGroup.last,
                  let lastDeclarationInSortedBody = typeDeclaration.body.last(where: { declaration in
                      consecutiveGroup.contains(where: { $0 === declaration })
                  }),
                  // If the last declaration was the same both before and after sorting,
                  // then the spacing doesn't need to be updated.
                  lastDeclarationInOriginalOrder !== lastDeclarationInSortedBody
            else { continue }

            // Ensure the group as a whole ends in a trailing blank line
            lastDeclarationInSortedBody.addTrailingBlankLineIfNeeded()

            // The last declaration in the original ordering might have a
            // trailing blank line which is no longer necessary.
            if let declarationIndex = typeDeclaration.body.firstIndex(where: { $0 === lastDeclarationInOriginalOrder }),
               declarationIndex != typeDeclaration.body.indices.last
            {
                let followingDeclaration = typeDeclaration.body[declarationIndex + 1]

                let thisCategory = category(of: lastDeclarationInOriginalOrder, for: options.organizationMode, using: order)
                let followingCategory = category(of: followingDeclaration, for: options.organizationMode, using: order)

                // A trailing blank line is still necessary if the following
                // declaration belongs to a different subgroup or category.
                let mustPreserveBlankLine: Bool
                if options.blankLineAfterSubgroups {
                    mustPreserveBlankLine = thisCategory != followingCategory
                } else {
                    switch options.organizationMode {
                    case .visibility:
                        mustPreserveBlankLine = thisCategory.visibility != followingCategory.visibility
                    case .type:
                        mustPreserveBlankLine = thisCategory.type != followingCategory.type
                    }
                }

                if !mustPreserveBlankLine {
                    lastDeclarationInOriginalOrder.removeTrailingBlankLinesIfPresent()
                }
            }
        }
    }

    // Finds all of the consecutive groups of property declarations in the type body
    func consecutivePropertyDeclarationGroups(in typeDeclaration: TypeDeclaration) -> [[DeclarationV2]] {
        var declarationGroups: [[DeclarationV2]] = []
        var currentGroup: [DeclarationV2] = []

        /// Ends the current group, ensuring that groups are only recorded
        /// when they contain two or more declarations.
        func endCurrentGroup(addingToExistingGroup declarationToAdd: DeclarationV2? = nil) {
            if let declarationToAdd = declarationToAdd {
                currentGroup.append(declarationToAdd)
            }

            if currentGroup.count >= 2 {
                declarationGroups.append(currentGroup)
            }

            currentGroup = []
        }

        for declaration in typeDeclaration.body {
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
}

// MARK: - Category

/// A category of declarations used by the `organizeDeclarations` rule
struct Category: Equatable, Hashable {
    var visibility: VisibilityCategory
    var type: DeclarationType
    var order: Int
    var comment: String? = nil

    /// The comment tokens that should precede all declarations in this category
    func markCommentBody(from template: String, with mode: DeclarationOrganizationMode) -> String? {
        template.replacingOccurrences(
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
        of declaration: DeclarationV2,
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

extension Array where Element: Equatable & Hashable {
    /// Sort function to sort an array based on the order of the elements on Self
    /// - Parameters:
    ///   - lhs: Sort closure left hand side element
    ///   - rhs: Sort closure right hand side element
    /// - Returns: Whether the elements are sorted or not.
    func areInRelativeOrder(lhs: Element, rhs: Element) -> Bool {
        guard let lhsIndex = firstIndex(of: lhs) else { return false }
        guard let rhsIndex = firstIndex(of: rhs) else { return true }
        return lhsIndex < rhsIndex
    }

    /// Creates a list without duplicates and ordered by the first time the element appeared in Self
    /// For example, this function would transform [1,2,3,1,2] into [1,2,3]
    func firstElementAppearanceOrder() -> [Element] {
        var appeared: Set<Element> = []
        var appearedList: [Element] = []

        for element in self {
            if !appeared.contains(element) {
                appeared.insert(element)
                appearedList.append(element)
            }
        }
        return appearedList
    }
}
