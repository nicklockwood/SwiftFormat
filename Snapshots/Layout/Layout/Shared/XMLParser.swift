//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

enum XMLNode {
    case node(
        name: String,
        attributes: [String: String],
        children: [XMLNode]
    )
    case text(String)
    case comment(String)

    public var isEmpty: Bool {
        switch self {
        case let .node(_, _, children):
            return !children.contains {
                guard case .text = $0 else {
                    return true
                }
                return !$0.isEmpty
            }
        case let .text(text):
            return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }

    public var isText: Bool {
        guard case .text = self else {
            return false
        }
        return !isLinebreak
    }

    public var isHTML: Bool {
        guard case let .node(name, _, _) = self else {
            return false
        }
        return name.lowercased() == name
    }

    public var isLinebreak: Bool {
        guard case .text("\n") = self else {
            return false
        }
        return true
    }

    public var isComment: Bool {
        guard case .comment = self else {
            return false
        }
        return true
    }

    var name: String? {
        guard case let .node(name, _, _) = self else {
            return nil
        }
        return name
    }

    public var children: [XMLNode] {
        if case let .node(_, _, children) = self {
            return children
        }
        return []
    }

    public var attributes: [String: String] {
        if case let .node(_, attributes, _) = self {
            return attributes
        }
        return [:]
    }

    fileprivate mutating func append(_ node: XMLNode) {
        switch self {
        case let .node(name, attributes, children):
            self = .node(
                name: name,
                attributes: attributes,
                children: children + [node]
            )
        default:
            preconditionFailure()
        }
    }
}

class XMLParser: NSObject, XMLParserDelegate {
    private var options: Options = []
    private var root: [XMLNode] = []
    private var stack: [XMLNode] = []
    private var top: XMLNode?
    private var error: Error?
    private var text = ""

    public struct Error: Swift.Error, CustomStringConvertible {
        public let description: String

        fileprivate init(_ message: String) {
            description = message
        }

        fileprivate init(_ error: Swift.Error) {
            let nsError = error as NSError
            guard let line = nsError.userInfo["NSXMLParserErrorLineNumber"] else {
                self.init("\(nsError.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines))")
                return
            }
            guard let message = nsError.userInfo["NSXMLParserErrorMessage"] else {
                self.init("Malformed XML at line \(line)")
                return
            }
            self.init("\("\(message)".trimmingCharacters(in: .whitespacesAndNewlines)) at line \(line)")
        }
    }

    public struct Options: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let skipComments = Options(rawValue: 1 << 0)
    }

    public static func parse(data: Data, options: Options = []) throws -> [XMLNode] {
        let parser = XMLParser(options: options)
        let foundationParser = Foundation.XMLParser(data: data)
        foundationParser.delegate = parser
        foundationParser.parse()
        if let error = parser.error {
            throw error
        }
        return parser.root
    }

    private init(options: Options) {
        self.options = options
        super.init()
    }

    private override init() {
        preconditionFailure()
    }

    private func appendNode(_ node: XMLNode) {
        if top != nil {
            top?.append(node)
        } else {
            root.append(node)
        }
    }

    private func appendText() {
        if !text.isEmpty {
            appendNode(.text(text
                    .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
                    .replacingOccurrences(of: " ?\\n+ ?", with: "\n", options: .regularExpression)))
            text = ""
        }
    }

    // MARK: XMLParserDelegate methods

    func parser(_: Foundation.XMLParser, didStartElement elementName: String, namespaceURI _: String?, qualifiedName _: String?, attributes: [String: String] = [:]) {
        let node = XMLNode.node(
            name: elementName,
            attributes: attributes,
            children: []
        )
        if top != nil { // Can't use if let binding here because we mutate top
            if !node.isHTML {
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if !top!.isHTML, top!.children.last?.isHTML != true {
                text = text.ltrim()
            }
            appendText()
            stack.append(top!)
        }
        top = node
    }

    func parser(_: Foundation.XMLParser, didEndElement elementName: String, namespaceURI _: String?, qualifiedName _: String?) {
        if !top!.isHTML {
            if top!.children.isEmpty {
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                text = text.rtrim()
            }
        }
        appendText()
        let node = top!
        top = stack.popLast()
        appendNode(node)
    }

    func parser(_: Foundation.XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_: Foundation.XMLParser, foundComment comment: String) {
        appendText()
        if !options.contains(.skipComments) {
            appendNode(.comment(comment))
        }
    }

    func parser(_: Foundation.XMLParser, parseErrorOccurred parseError: Swift.Error) {
        guard error == nil else {
            // Don't overwrite existing error
            return
        }
        error = Error(parseError)
    }
}

extension Collection where Iterator.Element == XMLNode {
    var isHTML: Bool {
        return contains(where: { $0.isHTML })
    }
}

extension String {
    func xmlEncoded(forAttribute: Bool = false) -> String {
        var output = ""
        for char in unicodeScalars {
            switch char {
            case "&":
                output.append("&amp;")
            case "<":
                output.append("&lt;")
            case "\"" where forAttribute:
                output.append("&quot;")
            case _ where char.value > 127:
                output.append(String(format: "&#x%2X;", char.value))
            default:
                output.append(String(char))
            }
        }
        return output
    }
}

private extension String {
    func ltrim() -> String {
        var chars = unicodeScalars
        while let char = chars.first, NSCharacterSet.whitespacesAndNewlines.contains(char) {
            chars.removeFirst()
        }
        return String(chars)
    }

    func rtrim() -> String {
        var chars = unicodeScalars
        while let char = chars.last, NSCharacterSet.whitespacesAndNewlines.contains(char) {
            chars.removeLast()
        }
        return String(chars)
    }
}
