//
//  CommonTypos.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 9/28/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Correct common, unambiguous spelling mistakes in comments and eligible declarations.
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
        formatter.renameIdentifiersAndComments(upTo: formatter.options.typoVisibility) { text in
            formatter.correctingCommonTypos(in: text, using: typoCorrections, ignoring: ignoredTypos)
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
