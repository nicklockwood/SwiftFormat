//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

func rename(_ old: String, to new: String, in files: [String]) -> [FormatError] {
    var errors = [Error]()
    for path in files {
        let url = expandPath(path)
        errors += enumerateFiles(withInputURL: url) { inputURL, outputURL in
            do {
                if let xml = try parseLayoutXML(inputURL) {
                    let output = try format(rename(old, to: new, in: xml))
                    try output.write(to: outputURL, atomically: true, encoding: .utf8)
                }
                return {}
            } catch {
                return { throw error }
            }
        }
    }
    return errors.map(FormatError.init)
}

func rename(_ old: String, to new: String, in xml: String) throws -> String {
    guard let data = xml.data(using: .utf8, allowLossyConversion: true) else {
        throw FormatError.parsing("Invalid xml string")
    }
    let xml = try XMLParser.parse(data: data)
    return try format(rename(old, to: new, in: xml))
}

private let stringExpressions: Set<String> = [
    "id", "udid", "uuid", "guid",
    "title", "text", "label", "name", "identifier",
    "key", "font", "image", "icon", "path", "url",
    "touchDown",
    "touchDownRepeat",
    "touchDragInside",
    "touchDragOutside",
    "touchDragEnter",
    "touchDragExit",
    "touchUpInside",
    "touchUpOutside",
    "touchCancel",
    "valueChanged",
    "primaryActionTriggered",
    "editingDidBegin",
    "editingChanged",
    "editingDidEnd",
    "editingDidEndOnExit",
    "allTouchEvents",
    "allEditingEvents",
    "allEvents",
]

func rename(_ old: String, to new: String, in xml: [XMLNode]) -> [XMLNode] {
    return xml.map {
        switch $0 {
        case .comment:
            return $0
        case let .text(text):
            guard let parts = try? parseStringExpression(text) else {
                return $0
            }
            return .text(rename(old, to: new, in: parts) ?? text)
        case .node(var name, var attributes, let children):
            for (key, value) in attributes {
                var isString = false
                if value.contains("{"), value.contains("}") {
                    isString = true // May not actually be a string, but we can parse it as one
                } else if attributeIsString(key, inNode: $0) ?? stringExpressions.contains(key) {
                    isString = true
                } else {
                    isString = [
                        "ID", "Id", "Url", "URL", "Path",
                        "Title", "Text", "String", "Label",
                        "Name", "Identifier", "Key",
                        "Font", "Image", "Icon",
                    ].contains { key.hasSuffix($0) }
                }
                if !isString, let expression = try? parseExpression(value) {
                    if let renamed = rename(old, to: new, in: expression) {
                        attributes[key] = renamed
                    }
                } else if let parts = try? parseStringExpression(value),
                    let result = rename(old, to: new, in: parts)
                {
                    attributes[key] = result
                }
            }
            if name == old, name.lowercased() != name {
                // Only rename non-HTML elements
                name = new
            }
            return .node(
                name: name,
                attributes: attributes,
                children: rename(old, to: new, in: children)
            )
        }
    }
}

private func rename(_ old: String, to new: String, in parts: [ParsedExpressionPart]) -> String? {
    var changed = false
    let parts: [String] = parts.map {
        switch $0 {
        case .string,
             .comment:
            return $0.description
        case let .expression(expression):
            if let renamed = rename(old, to: new, in: expression) {
                changed = true
                return "{\(renamed)}"
            }
            return $0.description
        }
    }
    return changed ? parts.joined() : nil
}

private func rename(_ old: String, to new: String, in expression: ParsedLayoutExpression) -> String? {
    guard expression.symbols.contains(.variable(old)) else {
        return nil
    }
    return expression.description.replacingOccurrences(of: "\\b\(old)\\b", with: new, options: .regularExpression)
}
