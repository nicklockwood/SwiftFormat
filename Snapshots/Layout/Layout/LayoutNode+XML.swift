//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

public extension LayoutNode {
    @available(*, deprecated, renamed: "init(xmlData:)")
    static func with(xmlData: Data, url: URL? = nil, relativeTo: String? = #file) throws -> LayoutNode {
        return try LayoutNode(
            layout: Layout(xmlData: xmlData, url: url, relativeTo: relativeTo)
        )
    }

    /// Creates a LayoutNode from a parse XML file
    /// The optional `url` parameter tells Layout where the node was loded from
    /// The optional` relativeTo` parameter helps to locate the original source file
    convenience init(xmlData: Data, url: URL? = nil, relativeTo: String? = #file) throws {
        try self.init(layout: Layout(xmlData: xmlData, url: url, relativeTo: relativeTo))
    }
}
