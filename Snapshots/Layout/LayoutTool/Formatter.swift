//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

func format(_ files: [String]) -> (filesChecked: Int, filesUpdated: Int, errors: [FormatError]) {
    var filesChecked = 0, filesUpdated = 0, errors = [Error]()
    for path in files {
        let url = expandPath(path)
        errors += enumerateFiles(withInputURL: url, concurrent: false) { inputURL, outputURL in
            var checked = false, updated = false
            do {
                let data = try Data(contentsOf: inputURL)
                if let input = String(data: data, encoding: .utf8),
                    let xml = try parseLayoutXML(data, for: inputURL)
                {
                    checked = true
                    let output = try format(xml)
                    if output != input {
                        try output.write(to: outputURL, atomically: true, encoding: .utf8)
                        updated = true
                    }
                }
                return {
                    if checked { filesChecked += 1 }
                    if updated { filesUpdated += 1 }
                }
            } catch let FormatError.parsing(error) {
                return {
                    if checked { filesChecked += 1 }
                    throw FormatError.parsing("\(error) in \(inputURL.path)")
                }
            } catch {
                return {
                    if checked { filesChecked += 1 }
                    throw error
                }
            }
        }
    }
    return (filesChecked, filesUpdated, errors.map(FormatError.init))
}

func format(_ xml: String) throws -> String {
    guard let data = xml.data(using: .utf8, allowLossyConversion: true) else {
        throw FormatError.parsing("Invalid xml string")
    }
    let xml = try FormatError.wrap { try XMLParser.parse(data: data) }
    return try format(xml)
}

func format(_ xml: [XMLNode]) throws -> String {
    return try xml.toString(withIndent: "")
}

extension Collection where Iterator.Element == XMLNode {
    func toString(withIndent indent: String, indentFirstLine: Bool = true, isHTML: Bool = false) throws -> String {
        var output = ""
        var previous: XMLNode?
        var indentNextLine = indentFirstLine
        var params = [XMLNode]()
        var macros = [XMLNode]()
        var nodes = Array(self)
        if !isHTML {
            for (index, node) in nodes.enumerated().reversed() {
                if node.isParameter {
                    var i = index
                    while i > 0, nodes[i - 1].isComment {
                        i -= 1
                    }
                    params = nodes[i ... index] + params
                    nodes[i ... index] = []
                } else if node.isMacro {
                    var i = index
                    while i > 0, nodes[i - 1].isComment {
                        i -= 1
                    }
                    macros = nodes[i ... index] + macros
                    nodes[i ... index] = []
                } else if node.isChildren || node.isHTML || node.isText {
                    break
                }
            }
        }
        for node in params + macros + nodes {
            if node.isLinebreak, previous?.isHTML != true {
                continue
            }
            switch node {
            case .text("\n"):
                continue
            case .comment:
                if let previous = previous, !previous.isComment, !previous.isLinebreak {
                    output += "\n"
                    indentNextLine = true
                }
                fallthrough
            default:
                if let previous = previous {
                    if previous.isParameterOrMacro, !node.isParameterOrMacro, !node.isComment {
                        if !node.isHTML {
                            output += "\n"
                        }
                        output += "\n"
                    } else if !(node.isText && (previous.isHTML || previous.isText)), !(node.isHTML && previous.isText) {
                        output += "\n"
                    }
                }
                if output.hasSuffix("\n") {
                    indentNextLine = true
                }
                output += try node.toString(withIndent: indent, indentFirstLine: indentNextLine)
            }
            previous = node
            indentNextLine = false
        }
        if !output.hasSuffix("\n") {
            output += "\n"
        }
        return output
    }
}

// Threshold for min number of attributes to begin linewrapping
private let attributeWrap = 2

extension XMLNode {
    private func formatAttribute(key: String, value: String) throws -> String {
        do {
            let description: String
            if attributeIsString(key, inNode: self) ?? true {
                // We have to treat everying we aren't sure about as a string expression, because if
                // we attempt to format text outside of {...} as an expression, it will get messed up
                let parts = try parseStringExpression(value)
                for part in parts {
                    switch part {
                    case .string,
                         .comment:
                        break
                    case let .expression(expression):
                        try validateLayoutExpression(expression)
                    }
                }
                description = parts.description
            } else {
                let expression = try parseExpression(value)
                try validateLayoutExpression(expression)
                description = expression.description
            }
            return "\(key)=\"\(description.xmlEncoded(forAttribute: true))\""
        } catch {
            throw FormatError.parsing("\(error) in \(key) attribute")
        }
    }

    func toString(withIndent indent: String, indentFirstLine: Bool = true) throws -> String {
        switch self {
        case let .node(name, attributes, children):
            do {
                var xml = indentFirstLine ? indent : ""
                xml += "<\(name)"
                let attributes = attributes.sorted(by: { a, b in
                    a.key < b.key // sort alphabetically
                })
                if attributes.count < attributeWrap || isParameterOrMacro || isHTML {
                    for (key, value) in attributes {
                        xml += try " \(formatAttribute(key: key, value: value))"
                    }
                } else {
                    for (key, value) in attributes {
                        xml += try "\n\(indent)    \(formatAttribute(key: key, value: value))"
                    }
                }
                if isParameterOrMacro || isChildren {
                    xml += "/>"
                } else if isEmpty {
                    if !isHTML, attributes.count >= attributeWrap {
                        xml += "\n\(indent)"
                    }
                    if !isHTML || emptyHTMLTags.contains(name) {
                        xml += "/>"
                    } else {
                        xml += "></\(name)>"
                    }
                } else if children.count == 1, children[0].isComment || children[0].isText {
                    xml += ">"
                    var body = try children[0].toString(withIndent: indent + "    ", indentFirstLine: false)
                    if isHTML {
                        if !body.hasPrefix("\n") {
                            body = body.replacingOccurrences(of: "\\s*\\n\\s*", with: "\n\(indent)", options: .regularExpression)
                        }
                        if body.hasSuffix("\n") {
                            body = "\(body)\(indent)"
                        }
                    } else if attributes.count >= attributeWrap {
                        if !body.hasPrefix("\n") {
                            body = "\n\(indent)\(body)"
                        } else {
                            body = "\(indent)\(body)"
                        }
                        if !body.hasSuffix("\n") {
                            body = "\(body)\n\(indent)"
                        } else {
                            body = "\(body)\(indent)"
                        }
                    } else {
                        body = body.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    xml += "\(body)</\(name)>"
                } else {
                    xml += ">\n"
                    let body = try children.toString(withIndent: indent + "    ", isHTML: isHTML)
                    if (!isHTML && attributes.count >= attributeWrap) ||
                        children.first(where: { !$0.isLinebreak })?.isComment == true
                    {
                        xml += "\n"
                    }
                    xml += "\(body)\(indent)</\(name)>"
                }
                return xml
            } catch {
                throw FormatError.parsing("\(error) in <\(name)>")
            }
        case let .text(text):
            if text == "\n" {
                return text
            }
            var body = text
                .xmlEncoded(forAttribute: false)
                .replacingOccurrences(of: "\\s*\\n\\s*", with: "\n\(indent)", options: .regularExpression)
            if body.hasSuffix("\n\(indent)") {
                body = String(body[body.startIndex ..< body.index(body.endIndex, offsetBy: -indent.count)])
            }
            if indentFirstLine {
                body = body.replacingOccurrences(of: "^\\s*", with: indent, options: .regularExpression)
            }
            return body
        case let .comment(comment):
            let body = comment
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s*\\n\\s*", with: "\n\(indent)", options: .regularExpression)
            return "\(indentFirstLine ? indent : "")<!-- \(body) -->"
        }
    }
}
