//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

private let stringsPrefix = "strings."

private func strings(in parsedExpressionPart: ParsedExpressionPart) throws -> [String] {
    switch parsedExpressionPart {
    case let .expression(expression):
        var strings = Set<String>()
        for symbol in expression.symbols {
            switch symbol {
            case var .variable(name),
                 var .function(name, _):
                if name.hasPrefix("`"), name.hasSuffix("`") {
                    name = String(name[name.index(after: name.startIndex) ..< name.index(before: name.endIndex)])
                }
                if name.hasPrefix(stringsPrefix) {
                    strings.insert(String(name[stringsPrefix.endIndex...]))
                }
            default:
                break
            }
        }
        return strings.sorted()
    default:
        return []
    }
}

func strings(in xml: String) throws -> [String] {
    guard let data = xml.data(using: .utf8, allowLossyConversion: true) else {
        throw FormatError.parsing("Invalid xml string")
    }
    let xml = try FormatError.wrap { try XMLParser.parse(data: data) }
    return try strings(in: xml)
}

func strings(in xml: [XMLNode]) throws -> [String] {
    return try xml.flatMap(strings(in:))
}

func strings(in xml: XMLNode) throws -> [String] {
    var results = Set<String>()
    switch xml {
    case let .text(string):
        for part in try parseStringExpression(string) {
            try results.formUnion(strings(in: part))
        }
    case let .node(name, attributes, children):
        if name.isCapitalized {
            for string in attributes.values {
                for part in try parseStringExpression(string) {
                    try results.formUnion(strings(in: part))
                }
            }
        }
        for child in children {
            try results.formUnion(strings(in: child))
        }
    case .comment:
        break
    }
    return results.sorted()
}

func listStrings(in files: [String]) -> [FormatError] {
    var errors = [Error]()
    var results = Set<String>()
    for path in files {
        let url = expandPath(path)
        errors += enumerateFiles(withInputURL: url, concurrent: false) { inputURL, _ in
            do {
                if let xml = try parseLayoutXML(inputURL) {
                    try results.formUnion(strings(in: xml))
                }
                return {}
            } catch let FormatError.parsing(error) {
                return { throw FormatError.parsing("\(error) in \(inputURL.path)") }
            } catch {
                return { throw error }
            }
        }
    }
    for string in results.sorted() {
        print(string)
    }
    return errors.map(FormatError.init)
}
