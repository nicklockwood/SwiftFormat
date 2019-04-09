//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

extension UIScrollView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["contentInsetAdjustmentBehavior"] = .uiScrollViewContentInsetAdjustmentBehavior
        types["indicatorStyle"] = .uiScrollViewIndicatorStyle
        types["indexDisplayMode"] = .uiScrollViewIndexDisplayMode
        types["keyboardDismissMode"] = .uiScrollViewKeyboardDismissMode
        types["zoomScale"] = .cgFloat
        types["maximumZoomScale"] = .cgFloat
        types["minimumZoomScale"] = .cgFloat
        types["decelerationRate"] = .uiScrollView_DecelerationRate

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "accessoryViews",
                "allowsMultipleFingers",
                "autoscrollContentOffset",
                "horizontalScrollDecelerationFactor",
                "isProgrammaticScrollEnabled",
                "preservesCenterDuringRotation",
                "showBackgroundShadow",
                "topExtensionViewColor",
                "tracksImmediatelyWhileDecelerating",
                "updateInsetBottomDuringKeyboardDismiss",
                "verticalScrollDecelerationFactor",
            ] {
                types[name] = nil
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "contentOffset":
            setContentOffset(value as! CGPoint, animated: true)
        case "contentOffset.x":
            let offset = CGPoint(x: value as! CGFloat, y: contentOffset.y)
            setContentOffset(offset, animated: true)
        case "contentOffset.y":
            let offset = CGPoint(x: contentOffset.x, y: value as! CGFloat)
            setContentOffset(offset, animated: true)
        case "zoomScale":
            setZoomScale(value as! CGFloat, animated: true)
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "contentInsetAdjustmentBehavior":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func didUpdateLayout(for _: LayoutNode) {
        // Prevents contentOffset glitch when rotating from portrait to landscape
        // TODO: needs improvement - result can be off by one page sometimes
        if isPagingEnabled {
            let offset = CGPoint(
                x: round(contentOffset.x / frame.size.width) * frame.width - contentInset.left,
                y: round(contentOffset.y / frame.size.height) * frame.height - contentInset.top
            )
            guard !offset.x.isNaN, !offset.y.isNaN else { return }
            contentOffset = offset
        }
    }
}
