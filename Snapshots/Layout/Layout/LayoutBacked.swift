//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

/// Protocol for views or controllers that are backed by a LayoutNode
/// Exposes the node reference so that the view can update itself
public protocol LayoutBacked: class {
    /* weak */ var layoutNode: LayoutNode? { get }
}

extension LayoutBacked where Self: NSObject {
    /// Default implementation of the layoutNode property
    public internal(set) weak var layoutNode: LayoutNode? {
        get { return _layoutNode }
        set { _setLayoutNode(layoutNode, retained: false) }
    }
}
