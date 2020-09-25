//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

public extension XMLNode {
    internal var isLayout: Bool {
        switch self {
        case let .node(name, attributes, children):
            guard name.isCapitalized else {
                return false
            }
            for key in attributes.keys {
                if layoutSymbols.contains(key) {
                    return true
                }
                if key.hasPrefix("layer.") {
                    return true
                }
            }
            return children.isLayout
        default:
            return false
        }
    }

    var isParameter: Bool {
        guard case .node("param", _, _) = self else {
            return false
        }
        return true
    }

    var isMacro: Bool {
        guard case .node("macro", _, _) = self else {
            return false
        }
        return true
    }

    var isChildren: Bool {
        guard case .node("children", _, _) = self else {
            return false
        }
        return true
    }

    var isParameterOrMacro: Bool {
        return isParameter || isMacro
    }

    var parameters: [String: String] {
        var params = [String: String]()
        for child in children where child.isParameter {
            let attributes = child.attributes
            if let name = attributes["name"], let type = attributes["type"] {
                params[name] = type
            }
        }
        return params
    }
}

extension Collection where Iterator.Element == XMLNode {
    var isLayout: Bool {
        for node in self {
            if node.isLayout {
                return true
            }
        }
        return false
    }
}
