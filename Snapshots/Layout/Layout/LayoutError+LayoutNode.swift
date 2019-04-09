//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

extension LayoutError {
    init(_ message: String, for node: LayoutNode?) {
        self.init(LayoutError.message(message), for: node)
    }

    init(_ error: Error, for node: LayoutNode?) {
        guard let node = node else {
            self.init(error)
            return
        }
        let rootURL = (node.rootURL != node.parent?.rootURL) ? node.rootURL : nil
        switch error {
        case let error as SymbolError where error.description.contains("Unknown property"):
            if error.description.contains("expression") {
                let symbol: String
                if let subError = error.error as? SymbolError {
                    symbol = subError.symbol
                } else {
                    symbol = error.symbol
                }
                let suggestions = bestMatches(
                    for: symbol, in: node.availableSymbols(forExpression: error.symbol)
                )
                self.init(LayoutError.unknownSymbol(error, suggestions), for: node)
            } else {
                let suggestions = bestMatches(for: error.symbol, in: node.availableExpressions)
                self.init(LayoutError.unknownExpression(error, suggestions), for: node)
            }
        case let error as SymbolError where error.description.contains("static property"):
            if error.description.contains("expression") {
                let symbol: String
                if let subError = error.error as? SymbolError {
                    symbol = subError.symbol
                } else {
                    symbol = error.symbol
                }
                guard let suggestions = staticPropertyMatches(for: symbol) else {
                    fallthrough
                }
                self.init(LayoutError.unknownSymbol(error, suggestions), for: node)
            } else {
                let suggestions = bestMatches(for: error.symbol, in: node.availableExpressions)
                self.init(LayoutError.unknownExpression(error, suggestions), for: node)
            }
        default:
            self.init(error, in: nameOfClass(node._class), in: rootURL)
        }
    }

    static func wrap<T>(_ closure: () throws -> T, for node: LayoutNode) throws -> T {
        do {
            return try closure()
        } catch {
            throw self.init(error, for: node)
        }
    }
}

private func staticPropertyMatches(for key: String) -> [String]? {
    var tail = key
    var head = ""
    while tail.isCapitalized, let range = tail.range(of: ".") {
        if !head.isEmpty {
            head += "."
        }
        head += String(tail[..<range.lowerBound])
        tail = String(tail[range.upperBound...])
    }
    guard !head.isEmpty, let type = RuntimeType.type(named: head) else {
        return nil
    }
    switch type.kind {
    case let .options(_, values):
        return bestMatches(for: tail, in: Set(values.keys))
    case let .any(type as NSObject.Type):
        var suffix = head.components(separatedBy: ".").last!
        for prefix in ["UI", "NS"] {
            if suffix.hasPrefix(prefix) {
                suffix = String(suffix[prefix.endIndex ..< suffix.endIndex])
                break
            }
        }
        var keys = Set<String>()
        var numberOfMethods: CUnsignedInt = 0
        let methods = class_copyMethodList(object_getClass(type.self), &numberOfMethods)!
        for i in 0 ..< Int(numberOfMethods) {
            let selector: Selector = method_getName(methods[i])
            var name = String(describing: selector)
            guard !name.contains(":"), !name.hasPrefix("_") else {
                continue
            }
            if name.hasSuffix(suffix) {
                name.removeLast(suffix.count)
            }
            keys.insert(name)
        }
        return bestMatches(for: tail, in: keys)
    default:
        return nil
    }
}

func bestMatches(for symbol: String, in suggestions: Set<String>) -> [String] {
    func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        var dist = [[Int]]()
        for i in 0 ... lhs.count {
            dist.append([i])
        }
        for j in 1 ... rhs.count {
            dist[0].append(j)
        }
        for i in 1 ... lhs.count {
            let lhs = lhs[lhs.index(lhs.startIndex, offsetBy: i - 1)]
            for j in 1 ... rhs.count {
                if lhs == rhs[rhs.index(rhs.startIndex, offsetBy: j - 1)] {
                    dist[i].append(dist[i - 1][j - 1])
                } else {
                    dist[i].append(min(min(dist[i - 1][j] + 1, dist[i][j - 1] + 1), dist[i - 1][j - 1] + 1))
                }
            }
        }
        return dist[lhs.count][rhs.count]
    }
    let lowercasedSymbol = symbol.lowercased()
    // Sort suggestions by Levenshtein distance
    return suggestions
        .compactMap { (string) -> (String, Int)? in
            let lowercaseString = string.lowercased()
            // Eliminate keyPaths unless symbol itself is a keyPath or is part of result
            guard !lowercaseString.contains(".") || symbol.contains(".") ||
                lowercaseString.hasPrefix("\(lowercasedSymbol).") else {
                return nil
            }
            return (string, levenshtein(lowercaseString, lowercasedSymbol))
        }
        // Sort by Levenshtein distance
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
}
