//
//  CommonTypos.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 9/28/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Correct common, unambiguous spelling mistakes in comments and non-public declarations.
    static let commonTypos = FormatRule(
        help: "Correct common spelling mistakes in comments and identifiers.",
        disabledByDefault: true,
        options: ["typo-visibility", "typos", "ignore-typos"]
    ) { formatter in
        let ignoredTypos = Set(formatter.options.ignoredTypos.map { $0.lowercased() })
        var typoCorrections = commonTypoCorrections
        for (typo, correction) in formatter.options.typos where typoCorrections[typo.lowercased()] == nil {
            typoCorrections[typo.lowercased()] = correction
        }
        let declarations = formatter.parseDeclarations()
        var declaredNames = Set<String>()
        var protectedNames = Set<String>()
        var eligibleNames = Set<String>()

        declarations.forEachRecursiveDeclaration { declaration in
            let names = formatter.namesInDeclaration(at: declaration.keywordIndex)
                ?? declaration.name.map { [$0] }
                ?? []
            declaredNames.formUnion(names)

            guard formatter.declarationCanHaveTyposCorrected(declaration) else {
                protectedNames.formUnion(names)
                if let function = formatter.commonTyposFunctionDeclaration(for: declaration) {
                    let argumentNames = function.arguments.flatMap { argument in
                        [argument.externalLabel, argument.internalLabel].compactMap { $0 }
                    }
                    declaredNames.formUnion(argumentNames)
                    protectedNames.formUnion(argumentNames)
                }
                return
            }

            eligibleNames.formUnion(names)
            if let function = formatter.commonTyposFunctionDeclaration(for: declaration) {
                let argumentNames = function.arguments.flatMap { argument in
                    [argument.externalLabel, argument.internalLabel].compactMap { $0 }
                }
                declaredNames.formUnion(argumentNames)
                eligibleNames.formUnion(argumentNames)
            }
        }

        // Local declarations aren't included in the declaration tree, but are safe to rename.
        formatter.forEachToken { index, token in
            guard case .keyword = token,
                  formatter.declarationScope(at: index) == .local,
                  let names = formatter.namesInDeclaration(at: index)
            else { return }
            declaredNames.formUnion(names)
            eligibleNames.formUnion(names)
            if ["func", "init", "subscript"].contains(token.string),
               let function = formatter.parseFunctionDeclaration(keywordIndex: index)
            {
                let argumentNames = function.arguments.flatMap { argument in
                    [argument.externalLabel, argument.internalLabel].compactMap { $0 }
                }
                declaredNames.formUnion(argumentNames)
                eligibleNames.formUnion(argumentNames)
            }
        }

        var renames = [String: String]()
        var correctedNames = [String: [String]]()
        for name in eligibleNames.subtracting(protectedNames) {
            let correctedName = formatter.correctingCommonTypos(
                in: name,
                using: typoCorrections,
                ignoring: ignoredTypos
            )
            guard correctedName != name else { continue }
            correctedNames[correctedName, default: []].append(name)
        }

        // Avoid introducing an ambiguous reference or combining two distinct declarations.
        for (correctedName, names) in correctedNames where names.count == 1 && !declaredNames.contains(correctedName) {
            renames[names[0]] = correctedName
        }

        formatter.forEachToken { index, token in
            switch token {
            case let .identifier(name):
                guard let correctedName = renames[name] else { return }
                formatter.replaceToken(at: index, with: .identifier(correctedName))
            case let .commentBody(comment):
                let correctedComment = formatter.correctingCommonTypos(
                    in: comment,
                    using: typoCorrections,
                    ignoring: ignoredTypos
                )
                guard correctedComment != comment else { return }
                formatter.replaceToken(at: index, with: .commentBody(correctedComment))
            default:
                break
            }
        }
    } examples: {
        """
        ```diff
        - // Retreive the cached value if it exists
        - private func retreiveCachedValue() -> Value? { ... }
        + // Retrieve the cached value if it exists
        + private func retrieveCachedValue() -> Value? { ... }
        ```
        """
    }
}

extension Formatter {
    /// Whether renaming this declaration cannot affect a public or serialized API contract.
    func declarationCanHaveTyposCorrected(_ declaration: Declaration) -> Bool {
        guard declaration.keyword != "extension",
              !["case", "import", "operator", "precedencegroup"].contains(declaration.keyword),
              effectiveVisibility(of: declaration) <= options.typoVisibility
        else { return false }

        let contractModifiers = [
            "@IBAction", "@IBInspectable", "@IBOutlet", "@NSManaged", "@GKInspectable",
            "@_cdecl", "@_silgen_name", "@inlinable", "@usableFromInline", "@objc",
            "dynamic", "override",
        ]
        let modifiers = Set(declaration.modifiers)
        guard contractModifiers.allSatisfy({ !modifiers.contains($0) }),
              !declaration.parentDeclarations.contains(where: { parent in
                  parent.keyword == "protocol" ||
                      parent.name == "CodingKeys" ||
                      parent.modifiers.contains("@objcMembers")
              })
        else { return false }

        if declaration.isStoredProperty {
            // A property wrapper can expose projected/backing names or persist the property.
            guard declaration.attributes.isEmpty else { return false }

            // Renaming a synthesized Codable field changes its serialized key.
            if declaration.parentType?.conformances.contains(where: {
                let name = $0.conformance.string.split(separator: ".").last.map(String.init)
                return ["Codable", "Decodable", "Encodable"].contains(name)
            }) == true {
                return false
            }
        }

        return true
    }

    /// The declaration's visibility after accounting for enclosing types and extensions.
    func effectiveVisibility(of declaration: Declaration) -> Visibility {
        let inheritedVisibility: Visibility?
        if declaration.visibility() == nil, declaration.parent?.keyword == "extension" {
            inheritedVisibility = declaration.parent?.visibility()
        } else {
            inheritedVisibility = nil
        }
        let visibility = declaration.visibility() ?? inheritedVisibility ?? .internal
        guard let parent = declaration.parent else { return visibility }
        return min(visibility, effectiveVisibility(of: parent))
    }

    func commonTyposFunctionDeclaration(for declaration: Declaration) -> FunctionDeclaration? {
        guard ["func", "init", "subscript"].contains(declaration.keyword) else { return nil }
        return parseFunctionDeclaration(keywordIndex: declaration.keywordIndex)
    }

    /// Corrects typo dictionary matches while preserving camel case and capitalization.
    func correctingCommonTypos(
        in text: String,
        using typoCorrections: [String: String],
        ignoring ignoredTypos: Set<String>
    ) -> String {
        var result = ""
        var letters = ""

        func appendLetters() {
            guard !letters.isEmpty else { return }
            result += correctingCommonTyposInWord(
                letters,
                using: typoCorrections,
                ignoring: ignoredTypos
            )
            letters = ""
        }

        for character in text {
            if character.isLetter {
                letters.append(character)
            } else {
                appendLetters()
                result.append(character)
            }
        }
        appendLetters()
        return result
    }

    func correctingCommonTyposInWord(
        _ word: String,
        using typoCorrections: [String: String],
        ignoring ignoredTypos: Set<String>
    ) -> String {
        let lowercaseWord = word.lowercased()
        if !ignoredTypos.contains(lowercaseWord), let correction = typoCorrections[lowercaseWord] {
            return correction.applyingCapitalization(of: word)
        }

        let characters = Array(word)
        guard characters.count > 1 else { return word }
        var components = [String]()
        var componentStart = 0

        for index in characters.indices.dropFirst() {
            let previous = characters[index - 1]
            let current = characters[index]
            let next = index < characters.index(before: characters.endIndex) ? characters[index + 1] : nil
            if previous.isLowercase && current.isUppercase ||
                previous.isUppercase && current.isUppercase && next?.isLowercase == true
            {
                components.append(String(characters[componentStart ..< index]))
                componentStart = index
            }
        }
        components.append(String(characters[componentStart...]))

        return components.map { component in
            let lowercaseComponent = component.lowercased()
            guard !ignoredTypos.contains(lowercaseComponent),
                  let correction = typoCorrections[lowercaseComponent]
            else { return component }
            return correction.applyingCapitalization(of: component)
        }.joined()
    }
}

extension String {
    func applyingCapitalization(of source: String) -> String {
        if source.allSatisfy(\.isUppercase) {
            return uppercased()
        }
        if source.first?.isUppercase == true, source.dropFirst().allSatisfy(\.isLowercase) {
            return prefix(1).uppercased() + dropFirst()
        }
        return self
    }
}

/// A deliberately conservative subset of unambiguous corrections inspired by codespell.
let commonTypoCorrections = [
    "acheive": "achieve",
    "acheived": "achieved",
    "acheives": "achieves",
    "acheiving": "achieving",
    "accomodate": "accommodate",
    "accomodated": "accommodated",
    "accomodates": "accommodates",
    "accomodating": "accommodating",
    "accross": "across",
    "addtion": "addition",
    "adress": "address",
    "adresses": "addresses",
    "allign": "align",
    "alligned": "aligned",
    "allignment": "alignment",
    "apparant": "apparent",
    "arguement": "argument",
    "arguements": "arguments",
    "assigment": "assignment",
    "assigments": "assignments",
    "asyncronous": "asynchronous",
    "availabe": "available",
    "begining": "beginning",
    "calender": "calendar",
    "calulated": "calculated",
    "catagory": "category",
    "catagories": "categories",
    "commited": "committed",
    "commiting": "committing",
    "compatability": "compatibility",
    "concious": "conscious",
    "consistant": "consistent",
    "contian": "contain",
    "contians": "contains",
    "definately": "definitely",
    "dependancy": "dependency",
    "dependancies": "dependencies",
    "depricated": "deprecated",
    "destory": "destroy",
    "detatch": "detach",
    "developement": "development",
    "dissapear": "disappear",
    "documantation": "documentation",
    "efficent": "efficient",
    "existance": "existence",
    "existant": "existent",
    "explicitely": "explicitly",
    "failue": "failure",
    "foward": "forward",
    "freind": "friend",
    "hieght": "height",
    "heigth": "height",
    "identifer": "identifier",
    "immediatly": "immediately",
    "implemenation": "implementation",
    "inital": "initial",
    "initalize": "initialize",
    "initalized": "initialized",
    "initalizer": "initializer",
    "intial": "initial",
    "lenght": "length",
    "maintainance": "maintenance",
    "maxiumum": "maximum",
    "millisecondes": "milliseconds",
    "mispell": "misspell",
    "mispelled": "misspelled",
    "mispelling": "misspelling",
    "neccessary": "necessary",
    "occurance": "occurrence",
    "occurances": "occurrences",
    "occured": "occurred",
    "occuring": "occurring",
    "paramater": "parameter",
    "paramaters": "parameters",
    "paramter": "parameter",
    "paramters": "parameters",
    "persistant": "persistent",
    "prefered": "preferred",
    "propogate": "propagate",
    "recieve": "receive",
    "recieved": "received",
    "reciever": "receiver",
    "recieves": "receives",
    "recieving": "receiving",
    "refered": "referred",
    "refering": "referring",
    "reponse": "response",
    "retreive": "retrieve",
    "retreived": "retrieved",
    "retreives": "retrieves",
    "retreiving": "retrieving",
    "seperate": "separate",
    "seperated": "separated",
    "seperately": "separately",
    "seperates": "separates",
    "seperating": "separating",
    "seperator": "separator",
    "similiar": "similar",
    "succesful": "successful",
    "succesfully": "successfully",
    "synchronus": "synchronous",
    "teh": "the",
    "threashold": "threshold",
    "transfered": "transferred",
    "transfering": "transferring",
    "untill": "until",
    "useage": "usage",
    "validitiy": "validity",
    "visiblity": "visibility",
    "widht": "width",
]
