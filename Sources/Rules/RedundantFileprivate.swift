//
//  RedundantFileprivate.swift
//  SwiftFormat
//
//  Created by Cal Stephens on 7/28/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Replace `fileprivate` with `private` where possible
    static let redundantFileprivate = FormatRule(
        help: "Prefer `private` over `fileprivate` where equivalent.",
        examples: """
        ```diff
        -  fileprivate let someConstant = "someConstant"
        +  private let someConstant = "someConstant"
        ```

        In Swift 4 and above, `fileprivate` can also be replaced with `private` for
        members that are only accessed from extensions in the same file:

        ```diff
          class Foo {
        -   fileprivate var foo = "foo"
        +   private var foo = "foo"
          }

          extension Foo {
            func bar() {
              print(self.foo)
            }
          }
        ```
        """
    ) { formatter in
        guard !formatter.options.fragment else { return }

        var hasUnreplacedFileprivates = false
        formatter.forEach(.keyword("fileprivate")) { i, _ in
            // check if definition is at file-scope
            if formatter.index(of: .startOfScope, before: i) == nil {
                formatter.replaceToken(at: i, with: .keyword("private"))
            } else {
                hasUnreplacedFileprivates = true
            }
        }
        guard hasUnreplacedFileprivates else {
            return
        }
        let importRanges = formatter.parseImports()
        var fileJustContainsOneType: Bool?

        formatter.forEach(.keyword("fileprivate")) { i, _ in
            // Check if definition is a member of a file-scope type
            guard formatter.options.swiftVersion >= "4",
                  let scopeIndex = formatter.index(of: .startOfScope, before: i, if: {
                      $0 == .startOfScope("{")
                  }), let typeIndex = formatter.index(of: .keyword, before: scopeIndex, if: {
                      ["class", "actor", "struct", "enum", "extension"].contains($0.string)
                  }), let nameIndex = formatter.index(of: .identifier, in: typeIndex ..< scopeIndex),
                  formatter.next(.nonSpaceOrCommentOrLinebreak, after: nameIndex)?.isOperator(".") == false,
                  case let .identifier(typeName) = formatter.tokens[nameIndex],
                  let endIndex = formatter.index(of: .endOfScope, after: scopeIndex),
                  formatter.currentScope(at: typeIndex) == nil
            else {
                return
            }
            // Get member type
            guard let keywordIndex = formatter.index(of: .keyword, in: i + 1 ..< endIndex),
                  let memberType = formatter.declarationType(at: keywordIndex),
                  // TODO: check if member types are exposed in the interface, otherwise convert them too
                  ["let", "var", "func", "init"].contains(memberType)
            else {
                return
            }
            // Check that type doesn't (potentially) conform to a protocol
            // TODO: use a whitelist of known protocols to make this check less blunt
            guard !formatter.tokens[typeIndex ..< scopeIndex].contains(.delimiter(":")) else {
                return
            }
            // Check for code outside of main type definition
            let startIndex = formatter.startOfModifiers(at: typeIndex, includingAttributes: true)
            if fileJustContainsOneType == nil {
                fileJustContainsOneType = !formatter.ifCodeInRange(0 ..< startIndex, importRanges: importRanges) &&
                    !formatter.ifCodeInRange(endIndex + 1 ..< formatter.tokens.count, importRanges: importRanges)
            }
            if fileJustContainsOneType == true {
                formatter.replaceToken(at: i, with: .keyword("private"))
                return
            }
            // Check if type name is initialized outside type, and if so don't
            // change any fileprivate members in case we break memberwise initializer
            // TODO: check if struct contains an overridden init; if so we can skip this check
            if formatter.tokens[typeIndex] == .keyword("struct"),
               formatter.isTypeInitialized(typeName, in: 0 ..< startIndex) ||
               formatter.isTypeInitialized(typeName, in: endIndex + 1 ..< formatter.tokens.count)
            {
                return
            }
            // Check if member is referenced outside type
            if memberType == "init" {
                // Make initializer private if it's not called anywhere
                if !formatter.isTypeInitialized(typeName, in: 0 ..< startIndex),
                   !formatter.isTypeInitialized(typeName, in: endIndex + 1 ..< formatter.tokens.count),
                   !formatter.isInitOverridden(for: typeName, in: 0 ..< startIndex),
                   !formatter.isInitOverridden(for: typeName, in: endIndex + 1 ..< formatter.tokens.count)
                {
                    formatter.replaceToken(at: i, with: .keyword("private"))
                }
            } else if let _names = formatter.namesInDeclaration(at: keywordIndex),
                      case let names = _names + _names.map({ "$\($0)" }),
                      !formatter.areMembers(names, of: typeName, referencedIn: 0 ..< startIndex),
                      !formatter.areMembers(names, of: typeName, referencedIn: endIndex + 1 ..< formatter.tokens.count)
            {
                formatter.replaceToken(at: i, with: .keyword("private"))
            }
        }
    }
}

extension Formatter {
    func ifCodeInRange(_ range: CountableRange<Int>, importRanges: [[ImportRange]]) -> Bool {
        var index = range.lowerBound
        while index < range.upperBound, let nextIndex =
            self.index(of: .nonSpaceOrCommentOrLinebreak, in: index ..< range.upperBound)
        {
            guard let importRange = importRanges.first(where: {
                $0.contains(where: { $0.range.contains(nextIndex) })
            }) else {
                return true
            }
            index = importRange.last!.range.upperBound + 1
        }
        return false
    }

    func isTypeInitialized(_ name: String, in range: CountableRange<Int>) -> Bool {
        for i in range {
            switch tokens[i] {
            case .identifier(name):
                guard let nextIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i) else {
                    break
                }
                switch tokens[nextIndex] {
                case .operator(".", .infix):
                    if next(.nonSpaceOrCommentOrLinebreak, after: nextIndex) == .identifier("init") {
                        return true
                    }
                case .startOfScope("("):
                    return true
                case .startOfScope("{"):
                    if isStartOfClosure(at: nextIndex) {
                        return true
                    }
                default:
                    break
                }
            case .identifier("init"):
                // TODO: this will return true if *any* type is initialized using type inference.
                // Is there a way to narrow this down a bit?
                if last(.nonSpaceOrCommentOrLinebreak, before: i) == .operator(".", .prefix) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }

    // TODO: improve this logic to handle shadowing
    func areMembers(_ names: [String], of type: String,
                    referencedIn range: CountableRange<Int>) -> Bool
    {
        var i = range.lowerBound
        while i < range.upperBound {
            switch tokens[i] {
            case .keyword("struct"), .keyword("extension"), .keyword("enum"), .keyword("actor"),
                 .keyword("class") where declarationType(at: i) == "class":
                guard let startIndex = index(of: .startOfScope("{"), after: i),
                      let endIndex = endOfScope(at: startIndex)
                else {
                    break
                }
                guard let nameIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: i),
                      tokens[nameIndex] != .identifier(type)
                else {
                    i = endIndex
                    break
                }
                for case let .identifier(name) in tokens[startIndex ..< endIndex]
                    where names.contains(name)
                {
                    return true
                }
                i = endIndex
            case let .identifier(name) where names.contains(name):
                if let dotIndex = index(of: .nonSpaceOrCommentOrLinebreak, before: i, if: {
                    $0 == .operator(".", .infix)
                }), last(.nonSpaceOrCommentOrLinebreak, before: dotIndex)
                    != .identifier("self")
                {
                    return true
                }
            default:
                break
            }
            i += 1
        }
        return false
    }

    func isInitOverridden(for type: String, in range: CountableRange<Int>) -> Bool {
        for i in range {
            if case .keyword("init") = tokens[i],
               let scopeStart = index(of: .startOfScope("{"), after: i),
               index(of: .identifier("super"), after: scopeStart) != nil,
               let scopeIndex = index(of: .startOfScope("{"), before: i),
               let colonIndex = index(of: .delimiter(":"), before: scopeIndex),
               next(
                   .nonSpaceOrCommentOrLinebreak,
                   in: colonIndex + 1 ..< scopeIndex
               ) == .identifier(type)
            {
                return true
            }
        }
        return false
    }
}
