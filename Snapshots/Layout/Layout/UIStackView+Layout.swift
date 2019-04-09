//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

extension UIStackView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["axis"] = .uiLayoutConstraintAxis
        types["distribution"] = .uiStackViewDistribution
        types["alignment"] = .uiStackViewAlignment
        types["spacing"] = .cgFloat
        types["arrangedSubviews"] = .unavailable()
        // UIStackView is a non-drawing view, so none of these properties are available
        for name in [
            "backgroundColor",
            "contentMode",
            "layer.backgroundColor",
            "layer.cornerRadius",
            "layer.borderColor",
            "layer.borderWidth",
            "layer.contents",
            "layer.masksToBounds",
            "layer.shadowColor",
            "layer.shadowOffset",
            "layer.shadowOffset.height",
            "layer.shadowOffset.width",
            "layer.shadowOpacity",
            "layer.shadowPath",
            "layer.shadowPathIsBounds",
            "layer.shadowRadius",
        ] {
            types[name] = .unavailable()
        }
        return types
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        super.didInsertChildNode(node, at: index)
        addArrangedSubview(node.view)
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        (node._view as UIView?).map(removeArrangedSubview)
        super.willRemoveChildNode(node, at: index)
    }

    open override class var defaultExpressions: [String: String] {
        return [
            "width": "auto",
            "height": "auto",
        ]
    }
}
