//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit
import WebKit

extension UIView: LayoutManaged {
    /// The view controller that owns the view - used to access layout guides
    var viewController: UIViewController? {
        var controller: UIViewController?
        var responder: UIResponder? = next
        while responder != nil {
            if let responder = responder as? UIViewController {
                controller = responder
                break
            }
            responder = responder?.next
        }
        return controller
    }

    /// Expression names and types
    @objc open class var expressionTypes: [String: RuntimeType] {
        var types = allPropertyTypes()
        // TODO: support more properties
        types["alpha"] = .cgFloat
        types["contentScaleFactor"] = .cgFloat
        types["contentMode"] = .uiViewContentMode
        types["tintAdjustmentMode"] = .uiViewTintAdjustmentMode
        if #available(iOS 11.0, *) {} else {
            types["directionalLayoutMargins"] = .uiEdgeInsets
        }
        for key in ["top", "leading", "bottom", "trailing"] {
            types["directionalLayoutMargins.\(key)"] = .cgFloat
        }
        types["semanticContentAttribute"] = .uiSemanticContentAttribute

        // Layer properties
        for (name, type) in (layerClass as! CALayer.Type).cachedExpressionTypes {
            types["layer.\(name)"] = type
        }

        // AutoLayout support
        types["contentHuggingPriority.horizontal"] = .uiLayoutPriority
        types["contentHuggingPriority.vertical"] = .uiLayoutPriority
        types["contentCompressionResistancePriority.horizontal"] = .uiLayoutPriority
        types["contentCompressionResistancePriority.vertical"] = .uiLayoutPriority

        // Explicitly disabled properties
        for name in [
            "autoresizingMask",
            "bounds",
            "frame",
            "topAnchor",
            "bottomAnchor",
            "leftAnchor",
            "rightAnchor",
            "widthAnchor",
            "heightAnchor",
            "leadingAnchor",
            "trailingAnchor",
        ] {
            types[name] = .unavailable("Use top/left/width/height instead")
            let name = "\(name)."
            for key in types.keys where key.hasPrefix(name) {
                types[key] = .unavailable("Use top/left/width/height instead")
            }
        }
        for name in [
            "firstBaselineAnchor",
            "lastBaselineAnchor",
        ] {
            types[name] = .unavailable("Use firstBaseline or lastBaseline instead")
        }
        for name in [
            "center",
            "centerXAnchor",
            "centerYAnchor",
        ] {
            types[name] = .unavailable("Use center.x or center.y instead")
        }
        for name in [
            "needsDisplayInRect",
            "layer.delegate",
        ] {
            types[name] = .unavailable()
            let name = "\(name)."
            for key in types.keys where key.hasPrefix(name) {
                types[key] = .unavailable()
            }
        }

        // Private and read-only properties
        for name in [
            "size",
            "origin",
            "position",
        ] + [
            "effectiveUserInterfaceLayoutDirection",
            "safeAreaInsets",
        ] {
            types[name] = nil
            let name = "\(name)."
            for key in types.keys where key.hasPrefix(name) {
                types[key] = nil
            }
        }
        #if arch(i386) || arch(x86_64)
            for name in [
                "allowsBaselineOffsetApproximation",
                "animationInfo",
                "charge",
                "clearsContext",
                "clipsSubviews",
                "compositingMode",
                "contentStretch",
                "contentsPosition",
                "customAlignmentRectInsets",
                "customBaselineOffsetFromBottom",
                "customFirstBaselineOffsetFromContentTop",
                "customFirstBaselineOffsetFromTop",
                "customScreenScale",
                "deliversButtonsForGesturesToSuperview",
                "deliversTouchesForGesturesToSuperview",
                "edgesInsettingLayoutMarginsFromSafeArea",
                "edgesPreservingSuperviewLayoutMargins",
                "enabledGestures",
                "fixedBackgroundPattern",
                "frameOrigin",
                "gesturesEnabled",
                "interactionTintColor",
                "invalidatingIntrinsicContentSizeAlsoInvalidatesSuperview",
                "isBaselineRelativeAlignmentRectInsets",
                "layoutMarginsFollowReadableWidth",
                "maximumLayoutSize",
                "minimumLayoutSize",
                "needsDisplayOnBoundsChange",
                "neverCacheContentLayoutSize",
                "previewingSegueTemplateStorage",
                "rotationBy",
                "skipsSubviewEnumeration",
                "viewTraversalMark",
                "wantsDeepColorDrawing",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    /// Constructor argument names and types
    @objc open class var parameterTypes: [String: RuntimeType] {
        return [:]
    }

    /// Deprecated symbols
    /// Key is the symbol name, value is the suggested replacement
    /// Empty value string indicates no replacement available
    @objc open class var deprecatedSymbols: [String: String] {
        return [
            "topLayoutGuide.length": "safeAreaInsets.top",
            "bottomLayoutGuide.length": "safeAreaInsets.bottom",
        ]
    }

    /// The name of the String or NSAttributedString property to use for body text
    /// Return nil to indicate that the view doesn't allow body text
    @objc open class var bodyExpression: String? {
        let types = cachedExpressionTypes
        for key in ["attributedText", "attributedTitle", "text", "title"] {
            if let type = types[key], case let .any(subtype) = type.kind,
                subtype is String.Type || subtype is NSAttributedString.Type {
                return key
            }
        }
        return nil
    }

    /// Called to construct the view
    @objc open class func create(with _: LayoutNode) throws -> UIView {
        return self.init()
    }

    /// Default expressions to use when not specified
    @objc open class var defaultExpressions: [String: String] {
        return [:]
    }

    // Return the best available VC for computing the layout guide
    var _layoutGuideController: UIViewController? {
        let viewController = self.viewController
        return viewController?.navigationController?.topViewController ??
            viewController?.tabBarController?.selectedViewController ?? viewController
    }

    var _safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            if let viewController = viewController {
                // This is the root view of a controller, so we can use the inset value directly, as per
                // https://developer.apple.com/documentation/uikit/uiview/2891103-safeareainsets
                return viewController.view.safeAreaInsets
            } else if let window = window {
                return window.safeAreaInsets
            }
        }
        return UIEdgeInsets(
            top: _layoutGuideController?.topLayoutGuide.length ?? 0,
            left: 0,
            bottom: _layoutGuideController?.bottomLayoutGuide.length ?? 0,
            right: 0
        )
    }

    internal var _effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10.0, *) {
            return effectiveUserInterfaceLayoutDirection
        } else {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        }
    }

    // Set expression value
    @objc open func setValue(_ value: Any, forExpression name: String) throws {
        if #available(iOS 11.0, *) {} else {
            let ltr = (_effectiveUserInterfaceLayoutDirection == .leftToRight)
            switch name {
            case "directionalLayoutMargins":
                layoutMargins = value as! UIEdgeInsets
                return
            case "directionalLayoutMargins.top":
                layoutMargins.top = value as! CGFloat
                return
            case "directionalLayoutMargins.leading":
                if ltr {
                    layoutMargins.left = value as! CGFloat
                } else {
                    layoutMargins.right = value as! CGFloat
                }
                return
            case "directionalLayoutMargins.bottom":
                layoutMargins.bottom = value as! CGFloat
                return
            case "directionalLayoutMargins.trailing":
                if ltr {
                    layoutMargins.right = value as! CGFloat
                } else {
                    layoutMargins.left = value as! CGFloat
                }
                return
            case "layer.maskedCorners":
                return // TODO: warn about unavailability
            default:
                break
            }
        }
        switch name {
        case "contentHuggingPriority.horizontal":
            setContentHuggingPriority(value as! UILayoutPriority, for: .horizontal)
        case "contentHuggingPriority.vertical":
            setContentHuggingPriority(value as! UILayoutPriority, for: .vertical)
        case "contentCompressionResistancePriority.horizontal":
            setContentCompressionResistancePriority(value as! UILayoutPriority, for: .horizontal)
        case "contentCompressionResistancePriority.vertical":
            setContentCompressionResistancePriority(value as! UILayoutPriority, for: .vertical)
        default:
            try _setValue(value, ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name)
        }
    }

    // Set expression value with animation (if applicable)
    @objc open func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        let type = Swift.type(of: self).cachedExpressionTypes[name]
        if try !_setValue(value, ofType: type, forKey: name, animated: true) {
            try setValue(value, forExpression: name)
        }
    }

    /// Get symbol value
    @objc open func value(forSymbol name: String) throws -> Any {
        switch name {
        case "backgroundColor":
            return backgroundColor ?? .clear
        case "safeAreaInsets":
            return _safeAreaInsets
        case "safeAreaInsets.top":
            return _safeAreaInsets.top
        case "safeAreaInsets.left":
            return _safeAreaInsets.left
        case "safeAreaInsets.bottom":
            return _safeAreaInsets.bottom
        case "safeAreaInsets.right":
            return _safeAreaInsets.right
        case "topLayoutGuide.length": // TODO: deprecate this
            return _layoutGuideController?.topLayoutGuide.length ?? 0
        case "bottomLayoutGuide.length": // TODO: deprecate this
            return _layoutGuideController?.bottomLayoutGuide.length ?? 0
        case "contentHuggingPriority.horizontal":
            return contentHuggingPriority(for: .horizontal)
        case "contentHuggingPriority.vertical":
            return contentHuggingPriority(for: .vertical)
        case "contentCompressionResistancePriority.horizontal":
            return contentCompressionResistancePriority(for: .horizontal)
        case "contentCompressionResistancePriority.vertical":
            return contentCompressionResistancePriority(for: .vertical)
        default:
            break
        }
        if #available(iOS 11.0, *) {} else {
            let ltr = (_effectiveUserInterfaceLayoutDirection == .leftToRight)
            switch name {
            case "directionalLayoutMargins":
                return layoutMargins
            case "directionalLayoutMargins.top":
                return layoutMargins.top
            case "directionalLayoutMargins.leading":
                return ltr ? layoutMargins.left : layoutMargins.right
            case "directionalLayoutMargins.bottom":
                return layoutMargins.bottom
            case "directionalLayoutMargins.trailing":
                return ltr ? layoutMargins.right : layoutMargins.left
            case "effectiveUserInterfaceLayoutDirection":
                return _effectiveUserInterfaceLayoutDirection
            case "layer.maskedCorners":
                return CACornerMask()
            default:
                break
            }
        }
        return try _value(ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name) as Any
    }

    /// Called immediately before a child node is added
    /// Returning false will cancel insertion of the node
    @objc open func shouldInsertChildNode(_ node: LayoutNode, at _: Int) -> Bool {
        return true
    }

    /// Called immediately after a child node is added
    @objc open func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        if let viewController = self.viewController {
            for controller in node.viewControllers {
                viewController.addChild(controller)
            }
        }
        if index > 0, let previous = node.parent?.children[index - 1].view {
            insertSubview(node.view, aboveSubview: previous)
        } else {
            addSubview(node.view)
        }
    }

    /// Called immediately before a child node is removed
    // TODO: remove index argument as it isn't used
    @objc open func willRemoveChildNode(_ node: LayoutNode, at _: Int) {
        if node._view == nil { return }
        for controller in node.viewControllers {
            controller.removeFromParent()
        }
        node.view.removeFromSuperview()
    }

    /// Called immediately after layout has been updated
    @objc open func didUpdateLayout(for _: LayoutNode) {}
}

extension UIImageView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["animationImages"] = .array(of: .uiImage)
        types["highlightedAnimationImages"] = .array(of: .uiImage)
        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "adjustsImageWhenAncestorFocused",
                "cGImageRef",
                "drawMode",
                "masksFocusEffectToContents",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isAnimating":
            switch (value as! Bool, isAnimating) {
            case (true, false):
                startAnimating()
            case (false, true):
                stopAnimating()
            case (true, true), (false, false):
                break
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

private let controlEvents: [String: UIControl.Event] = [
    "touchDown": .touchDown,
    "touchDownRepeat": .touchDownRepeat,
    "touchDragInside": .touchDragInside,
    "touchDragOutside": .touchDragOutside,
    "touchDragEnter": .touchDragEnter,
    "touchDragExit": .touchDragExit,
    "touchUpInside": .touchUpInside,
    "touchUpOutside": .touchUpOutside,
    "touchCancel": .touchCancel,
    "valueChanged": .valueChanged,
    "primaryActionTriggered": .primaryActionTriggered,
    "editingDidBegin": .editingDidBegin,
    "editingChanged": .editingChanged,
    "editingDidEnd": .editingDidEnd,
    "editingDidEndOnExit": .editingDidEndOnExit,
    "allTouchEvents": .allTouchEvents,
    "allEditingEvents": .allEditingEvents,
    "allEvents": .allEvents,
]

private let controlStates: [String: UIControl.State] = [
    "normal": .normal,
    "highlighted": .highlighted,
    "disabled": .disabled,
    "selected": .selected,
    "focused": .focused,
]

private var layoutActionsKey: UInt8 = 0
extension UIControl {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["contentVerticalAlignment"] = .uiControlContentVerticalAlignment
        types["contentHorizontalAlignment"] = .uiControlContentHorizontalAlignment
        for name in controlEvents.keys {
            types[name] = .selector
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "adPrivacyData",
                "requiresDisplayOnTracking",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        if let action = value as? Selector, let event = controlEvents[name] {
            var actions = objc_getAssociatedObject(self, &layoutActionsKey) as? NSMutableDictionary
            if actions == nil {
                actions = NSMutableDictionary()
                objc_setAssociatedObject(self, &layoutActionsKey, actions, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            if let oldAction = actions?[name] as? Selector {
                if oldAction == action {
                    return
                }
                removeTarget(nil, action: action, for: event)
            }
            actions?[name] = action
            return
        }
        try super.setValue(value, forExpression: name)
    }

    func bindActions(for target: AnyObject) throws {
        guard let actions = objc_getAssociatedObject(self, &layoutActionsKey) as? NSMutableDictionary else {
            return
        }
        for (name, action) in actions {
            guard let name = name as? String, let event = controlEvents[name], let action = action as? Selector else {
                assertionFailure()
                return
            }
            if let actions = self.actions(forTarget: target, forControlEvent: event), actions.contains("\(action)") {
                // Already bound
            } else {
                if !target.responds(to: action) {
                    guard let responder = target as? UIResponder, let next = responder.next else {
                        throw LayoutError.message("Layout could find no suitable target for the \(action) action. If the method exists, it must be prefixed with @objc or @IBAction to be used with Layout")
                    }
                    try bindActions(for: next)
                    return
                }
                addTarget(target, action: action, for: event)
            }
        }
    }

    func unbindActions(for target: AnyObject) {
        for action in actions(forTarget: target, forControlEvent: .allEvents) ?? [] {
            removeTarget(target, action: Selector(action), for: .allEvents)
        }
        if let responder = target as? UIResponder, let next = responder.next {
            unbindActions(for: next)
        }
    }
}

extension UIButton {
    open override class func create(with node: LayoutNode) throws -> UIButton {
        if let type = try node.value(forExpression: "type") as? UIButton.ButtonType {
            return self.init(type: type)
        }
        return self.init(frame: .zero)
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return ["type": .uiButtonType]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["title"] = .string
        types["attributedTitle"] = .nsAttributedString
        types["titleColor"] = .uiColor
        types["titleShadowColor"] = .uiColor
        types["image"] = .uiImage
        types["backgroundImage"] = .uiImage
        for state in controlStates.keys {
            types["\(state)Title"] = .string
            types["\(state)AttributedTitle"] = .nsAttributedString
            types["\(state)TitleColor"] = .uiColor
            types["\(state)TitleShadowColor"] = .uiColor
            types["\(state)Image"] = .uiImage
            types["\(state)BackgroundImage"] = .uiImage
        }
        for (name, type) in UILabel.cachedExpressionTypes {
            types["titleLabel.\(name)"] = type
        }
        for (name, type) in UIImageView.cachedExpressionTypes {
            types["imageView.\(name)"] = type
        }
        // Private properties
        types["lineBreakMode"] = nil
        #if arch(i386) || arch(x86_64)
            for name in [
                "autosizesToFit",
                "showPressFeedback",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "title": setTitle(value as? String, for: .normal)
        case "titleColor": setTitleColor(value as? UIColor, for: .normal)
        case "titleShadowColor": setTitleShadowColor(value as? UIColor, for: .normal)
        case "image": setImage(value as? UIImage, for: .normal)
        case "backgroundImage": setBackgroundImage(value as? UIImage, for: .normal)
        case "attributedTitle": setAttributedTitle(value as? NSAttributedString, for: .normal)
        default:
            if let (prefix, state) = controlStates.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "Title": setTitle(value as? String, for: state)
                case "TitleColor": setTitleColor(value as? UIColor, for: state)
                case "TitleShadowColor": setTitleShadowColor(value as? UIColor, for: state)
                case "Image": setImage(value as? UIImage, for: state)
                case "BackgroundImage": setBackgroundImage(value as? UIImage, for: state)
                case "AttributedTitle": setAttributedTitle(value as? NSAttributedString, for: state)
                default:
                    break
                }
                return
            }
            try super.setValue(value, forExpression: name)
        }
    }

    open override func value(forSymbol name: String) throws -> Any {
        switch name {
        case "title": return title(for: .normal) ?? ""
        case "titleColor": return titleColor(for: .normal) as Any
        case "titleShadowColor": return titleShadowColor(for: .normal) as Any
        case "image": return image(for: .normal) as Any
        case "backgroundImage": return backgroundImage(for: .normal) as Any
        case "attributedTitle": return attributedTitle(for: .normal) as Any
        default:
            if let (prefix, state) = controlStates.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "Title": return title(for: state) as Any
                case "TitleColor": return titleColor(for: state) as Any
                case "TitleShadowColor": return titleShadowColor(for: state) as Any
                case "Image": return image(for: state) as Any
                case "BackgroundImage": return backgroundImage(for: state) as Any
                case "AttributedTitle": return attributedTitle(for: state) as Any
                default:
                    break
                }
            }
            return try super.value(forSymbol: name)
        }
    }
}

private let textInputTraits: [String: RuntimeType] = [
    "autocapitalizationType": .uiTextAutocapitalizationType,
    "autocorrectionType": .uiTextAutocorrectionType,
    "spellCheckingType": .uiTextSpellCheckingType,
    "keyboardType": .uiKeyboardType,
    "keyboardAppearance": .uiKeyboardAppearance,
    "returnKeyType": .uiReturnKeyType,
    "enablesReturnKeyAutomatically": .bool,
    "isSecureTextEntry": .bool,
    "smartQuotesType": .uiTextSmartQuotesType,
    "smartDashesType": .uiTextSmartDashesType,
    "smartInsertDeleteType": .uiTextSmartInsertDeleteType,
]

extension UILabel {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["textAlignment"] = .nsTextAlignment
        types["lineBreakMode"] = .nsLineBreakMode
        types["baselineAdjustment"] = .uiBaselineAdjustment
        types["enablesMarqueeWhenAncestorFocused"] = .bool

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "adjustsLetterSpacingToFitWidth",
                "autotrackTextToFit",
                "centersHorizontally",
                "color",
                "drawsLetterpress",
                "drawsUnderline",
                "lineSpacing",
                "marqueeEnabled",
                "marqueeRunning",
                "minimumFontSize",
                "rawSize",
                "rawSize.width",
                "rawSize.height",
                "shadowBlur",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        if #available(iOS 12.0, *) {} else {
            switch name {
            case "enablesMarqueeWhenAncestorFocused":
                return // does nothing
            default:
                break
            }
        }
        try super.setValue(value, forExpression: name)
    }
}

private let dragAndDropOptions: [String: RuntimeType] = [
    "textDragDelegate": .uiTextDragDelegate,
    "textDropDelegate": .uiTextDropDelegate,
    "textDragOptions": .uiTextDragOptions,
]

extension UITextField {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        for (name, type) in textInputTraits {
            types[name] = type
        }
        types["textAlignment"] = .nsTextAlignment
        types["borderStyle"] = .uiTextBorderStyle
        types["clearButtonMode"] = .uiTextFieldViewMode
        types["leftViewMode"] = .uiTextFieldViewMode
        types["rightViewMode"] = .uiTextFieldViewMode
        types["minimumFontSize"] = .cgFloat
        types["passwordRules"] = .uiTextInputPasswordRules
        types["textContentType"] = .uiTextContentType
        for (name, type) in dragAndDropOptions {
            types[name] = type
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "animating",
                "atomStyle",
                "autoresizesTextToFit",
                "becomesFirstResponderOnClearButtonTap",
                "clearButtonOffset",
                "clearButtonStyle",
                "clearingBehavior",
                "clearsPlaceholderOnBeginEditing",
                "contentOffsetForSameViewDrops",
                "continuousSpellCheckingEnabled",
                "defaultTextAttributes",
                "displaySecureEditsUsingPlainText",
                "displaySecureTextUsingPlainText",
                "drawsAsAtom",
                "inactiveHasDimAppearance",
                "isDevicePasscodeEntry",
                "isUndoEnabled",
                "labelOffset",
                "nonEditingLinebreakMode",
                "paddingBottom",
                "paddingLeft",
                "paddingRight",
                "paddingTop",
                "progress",
                "recentsAccessoryView",
                "selectionRange",
                "shadowBlur",
                "shadowColor",
                "shadowOffset",
                "textAutorresizesToFit",
                "textCentersHorizontally",
                "textCentersVertically",
                "textSelectionBehavior",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "autocapitalizationType": autocapitalizationType = value as! UITextAutocapitalizationType
        case "autocorrectionType": autocorrectionType = value as! UITextAutocorrectionType
        case "spellCheckingType": spellCheckingType = value as! UITextSpellCheckingType
        case "keyboardType": keyboardType = value as! UIKeyboardType
        case "keyboardAppearance": keyboardAppearance = value as! UIKeyboardAppearance
        case "returnKeyType": returnKeyType = value as! UIReturnKeyType
        case "enablesReturnKeyAutomatically": enablesReturnKeyAutomatically = value as! Bool
        case "isSecureTextEntry": isSecureTextEntry = value as! Bool
        case "passwordRules":
            #if swift(>=4.1.5) || (!swift(>=4) && swift(>=3.4))
                // TODO: warn about unavailability
                if #available(iOS 12.0, *) {
                    passwordRules = value as? UITextInputPasswordRules
                }
            #endif
        case "textContentType":
            // TODO: warn about unavailability
            if #available(iOS 10.0, *) {
                textContentType = value as? UITextContentType
            }
        case "smartQuotesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartQuotesType = value as! UITextSmartQuotesType
            }
        case "smartDashesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartDashesType = value as! UITextSmartDashesType
            }
        case "smartInsertDeleteType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartInsertDeleteType = value as! UITextSmartInsertDeleteType
            }
        case "textDragDelegate", "textDropDelegate", "textDragOptions":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

extension UITextView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["textAlignment"] = .nsTextAlignment
        types["dataDetectorTypes"] = .uiDataDetectorTypes
        for (name, type) in textInputTraits {
            types[name] = type
        }
        for (name, type) in dragAndDropOptions {
            types[name] = type
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "becomesEditableWithGestures",
                "contentOffsetForSameViewDrops",
                "continuousSpellCheckingEnabled",
                "forceDisableDictation",
                "forceEnableDictation",
                "marginTop",
                "shouldAutoscrollAboveBottom",
                "shouldPresentSheetsInAWindowLayeredAboveTheKeyboard",
                "tiledViewsDrawAsynchronously",
                "usesTiledViews",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "autocapitalizationType": autocapitalizationType = value as! UITextAutocapitalizationType
        case "autocorrectionType": autocorrectionType = value as! UITextAutocorrectionType
        case "spellCheckingType": spellCheckingType = value as! UITextSpellCheckingType
        case "keyboardType": keyboardType = value as! UIKeyboardType
        case "keyboardAppearance": keyboardAppearance = value as! UIKeyboardAppearance
        case "returnKeyType": returnKeyType = value as! UIReturnKeyType
        case "enablesReturnKeyAutomatically": enablesReturnKeyAutomatically = value as! Bool
        case "isSecureTextEntry": isSecureTextEntry = value as! Bool
        case "smartQuotesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartQuotesType = value as! UITextSmartQuotesType
            }
        case "smartDashesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartDashesType = value as! UITextSmartDashesType
            }
        case "smartInsertDeleteType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartInsertDeleteType = value as! UITextSmartInsertDeleteType
            }
        case "textDragDelegate", "textDropDelegate", "textDragOptions":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

extension UISearchBar {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["barPosition"] = .uiBarPosition
        types["barStyle"] = .uiBarStyle
        types["scopeButtonTitles"] = .array(of: .string)
        types["searchBarStyle"] = .uiSearchBarStyle
        for (name, type) in textInputTraits {
            types[name] = type
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "centerPlaceholder",
                "combinesLandscapeBars",
                "contentInset",
                "drawsBackground",
                "drawsBackgroundInPalette",
                "pretendsIsInBar",
                "searchFieldLeftViewMode",
                "searchTextPositionAdjustment",
                "usesEmbeddedAppearance",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "autocapitalizationType": autocapitalizationType = value as! UITextAutocapitalizationType
        case "autocorrectionType": autocorrectionType = value as! UITextAutocorrectionType
        case "spellCheckingType": spellCheckingType = value as! UITextSpellCheckingType
        case "keyboardType": keyboardType = value as! UIKeyboardType
        case "keyboardAppearance": keyboardAppearance = value as! UIKeyboardAppearance
        case "returnKeyType": returnKeyType = value as! UIReturnKeyType
        case "enablesReturnKeyAutomatically": enablesReturnKeyAutomatically = value as! Bool
        case "isSecureTextEntry": isSecureTextEntry = value as! Bool
        case "smartQuotesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartQuotesType = value as! UITextSmartQuotesType
            }
        case "smartDashesType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartDashesType = value as! UITextSmartDashesType
            }
        case "smartInsertDeleteType":
            // TODO: warn about unavailability
            if #available(iOS 11.0, *) {
                smartInsertDeleteType = value as! UITextSmartInsertDeleteType
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

private let controlSegments = RuntimeType.uiSegmentedControlSegment.values.mapValues {
    $0 as! UISegmentedControl.Segment
}

extension UISegmentedControl: TitleTextAttributes {
    open override class func create(with node: LayoutNode) throws -> UISegmentedControl {
        var items = [Any]()
        for item in try node.value(forExpression: "items") as? [Any] ?? [] {
            switch item {
            case is String, is UIImage:
                items.append(item)
            default:
                throw LayoutError("\(type(of: item)) is not a valid item type for \(classForCoder())", for: node)
            }
        }
        return self.init(items: items)
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["items"] = RuntimeType(NSArray.self)
        // TODO: find a good naming scheme for left/right state variants
        types["backgroundImage"] = .uiImage
        types["titleColor"] = .uiColor
        types["titleFont"] = .uiFont
        for state in controlStates.keys {
            types["\(state)BackgroundImage"] = .uiImage
            types["\(state)TitleColor"] = .uiColor
            types["\(state)TitleFont"] = .uiFont
        }
        types["dividerImage"] = .uiImage
        types["contentPositionAdjustment"] = .uiOffset
        types["contentPositionAdjustment.horizontal"] = .cgFloat
        types["contentPositionAdjustment.vertical"] = .cgFloat
        for segment in controlSegments.keys {
            types["\(segment)ContentPositionAdjustment"] = .uiOffset
            types["\(segment)ContentPositionAdjustment.horizontal"] = .cgFloat
            types["\(segment)ContentPositionAdjustment.vertical"] = .cgFloat
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "aloneContentPositionAdjustment",
                "alwaysNotifiesDelegateOfSegmentClicks",
                "anyContentPositionAdjustment",
                "axLongPressGestureRecognizer",
                "barStyle",
                "controlSize",
                "removedSegment",
                "segmentControlStyle",
                "segmentedControlStyle",
                "selectedSegment",
                "transparentBackground",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    private func setItems(_ items: NSArray?, animated: Bool) throws {
        let items = items ?? []
        for (i, item) in items.enumerated() {
            switch item {
            case let title as String:
                if i >= numberOfSegments {
                    insertSegment(withTitle: title, at: i, animated: animated)
                } else {
                    if let oldTitle = titleForSegment(at: i), oldTitle == title {
                        break
                    }
                    removeSegment(at: i, animated: animated)
                    insertSegment(withTitle: title, at: i, animated: animated)
                }
            case let image as UIImage:
                if i >= numberOfSegments {
                    insertSegment(with: image, at: i, animated: animated)
                } else {
                    if let oldImage = imageForSegment(at: i), oldImage == image {
                        break
                    }
                    removeSegment(at: i, animated: animated)
                    insertSegment(with: image, at: i, animated: animated)
                }
            default:
                throw SymbolError("items array may only contain Strings or UIImages", for: "items")
            }
        }
        while items.count > numberOfSegments {
            removeSegment(at: numberOfSegments - 1, animated: animated)
        }
    }

    var titleColor: UIColor? {
        get { return titleTextAttributes(for: .normal)?[NSAttributedString.Key.foregroundColor] as? UIColor }
        set { setTitleColor(newValue, for: .normal) }
    }

    var titleFont: UIFont? {
        get { return titleTextAttributes(for: .normal)?[NSAttributedString.Key.font] as? UIFont }
        set { setTitleFont(newValue, for: .normal) }
    }

    private func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        var attributes = titleTextAttributes(for: state) ?? [:]
        attributes[NSAttributedString.Key.foregroundColor] = color
        setTitleTextAttributes(attributes, for: state)
    }

    private func setTitleFont(_ font: UIFont?, for state: UIControl.State) {
        var attributes = titleTextAttributes(for: state) ?? [:]
        attributes[NSAttributedString.Key.font] = font
        setTitleTextAttributes(attributes, for: state)
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "items": try setItems(value as? NSArray, animated: false)
        // TODO: find a good naming scheme for barMetrics variants
        case "backgroundImage": setBackgroundImage(value as? UIImage, for: .normal, barMetrics: .default)
        case "dividerImage": setDividerImage(value as? UIImage, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        case "titleColor": setTitleColor(value as? UIColor, for: .normal)
        case "titleFont": setTitleFont(value as? UIFont, for: .normal)
        case "contentPositionAdjustment": setContentPositionAdjustment(value as! UIOffset, forSegmentType: .any, barMetrics: .default)
        case "contentPositionAdjustment.horizontal":
            var offset = contentPositionAdjustment(forSegmentType: .any, barMetrics: .default)
            offset.horizontal = value as! CGFloat
            setContentPositionAdjustment(offset, forSegmentType: .any, barMetrics: .default)
        case "contentPositionAdjustment.vertical":
            var offset = contentPositionAdjustment(forSegmentType: .any, barMetrics: .default)
            offset.vertical = value as! CGFloat
            setContentPositionAdjustment(offset, forSegmentType: .any, barMetrics: .default)
        default:
            if let (prefix, state) = controlStates.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "BackgroundImage": setBackgroundImage(value as? UIImage, for: state, barMetrics: .default)
                case "TitleColor": setTitleColor(value as? UIColor, for: state)
                case "TitleFont": setTitleFont(value as? UIFont, for: state)
                default:
                    try super.setValue(value, forExpression: name)
                }
                return
            }
            if let (prefix, segment) = controlSegments.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "ContentPositionAdjustment":
                    setContentPositionAdjustment(value as! UIOffset, forSegmentType: segment, barMetrics: .default)
                case "ContentPositionAdjustment.horizontal":
                    var offset = contentPositionAdjustment(forSegmentType: segment, barMetrics: .default)
                    offset.horizontal = value as! CGFloat
                    setContentPositionAdjustment(offset, forSegmentType: segment, barMetrics: .default)
                case "ContentPositionAdjustment.vertical":
                    var offset = contentPositionAdjustment(forSegmentType: segment, barMetrics: .default)
                    offset.vertical = value as! CGFloat
                    setContentPositionAdjustment(offset, forSegmentType: segment, barMetrics: .default)
                default:
                    try super.setValue(value, forExpression: name)
                }
                return
            }
            try super.setValue(value, forExpression: name)
        }
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "items":
            try setItems(value as? NSArray, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }
}

extension UIStepper {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        // TODO: find a good naming scheme for left/right state variants
        types["backgroundImage"] = .uiImage
        types["incrementImage"] = .uiColor
        types["decrementImage"] = .uiFont
        for state in controlStates.keys {
            types["\(state)BackgroundImage"] = .uiImage
            types["\(state)IncrementImage"] = .uiImage
            types["\(state)DecrementImage"] = .uiImage
        }
        types["dividerImage"] = .uiImage
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "backgroundImage": setBackgroundImage(value as? UIImage, for: .normal)
        case "dividerImage": setDividerImage(value as? UIImage, forLeftSegmentState: .normal, rightSegmentState: .normal)
        case "incrementImage": setIncrementImage(value as? UIImage, for: .normal)
        case "decrementImage": setDecrementImage(value as? UIImage, for: .normal)
        default:
            if let (prefix, state) = controlStates.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "BackgroundImage": setBackgroundImage(value as? UIImage, for: state)
                case "IncrementImage": setIncrementImage(value as? UIImage, for: state)
                case "DecrementImage": setDecrementImage(value as? UIImage, for: state)
                default:
                    try super.setValue(value, forExpression: name)
                }
                return
            }
            try super.setValue(value, forExpression: name)
        }
    }
}

extension UIActivityIndicatorView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["isAnimating"] = .bool
        types["activityIndicatorViewStyle"] = .uiActivityIndicatorViewStyle

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "animationDuration",
                "clockWise",
                "hasShadow",
                "innerRadius",
                "isHighlighted",
                "shadowColor",
                "shadowOffset",
                "spinning",
                "spinningDuration",
                "spokeCount",
                "spokeFrameRatio",
                "style",
                "useArtwork",
                "useOutlineShadow",
                "width",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isAnimating":
            switch (value as! Bool, isAnimating) {
            case (true, false):
                startAnimating()
            case (false, true):
                stopAnimating()
            case (true, true), (false, false):
                break
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override class var defaultExpressions: [String: String] {
        return ["isAnimating": "true"]
    }
}

extension UISwitch {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes

        #if arch(i386) || arch(x86_64)
            // Private
            types["visualElement"] = nil
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isOn":
            setOn(value as! Bool, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }
}

extension UISlider {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["thumbImage"] = .uiImage
        types["minimumTrackImage"] = .uiImage
        types["maximumTrackImage"] = .uiImage
        for state in controlStates.keys {
            types["\(state)ThumbImage"] = .uiImage
            types["\(state)MinimumTrackImage"] = .uiImage
            types["\(state)MaximumTrackImage"] = .uiImage
        }
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "thumbImage": setThumbImage(value as? UIImage, for: .normal)
        case "minimumTrackImage": setMinimumTrackImage(value as? UIImage, for: .normal)
        case "maximumTrackImage": setMaximumTrackImage(value as? UIImage, for: .normal)
        default:
            if let (prefix, state) = controlStates.first(where: { name.hasPrefix($0.key) }) {
                switch name[prefix.endIndex ..< name.endIndex] {
                case "ThumbImage": setThumbImage(value as? UIImage, for: state)
                case "MinimumTrackImage": setMinimumTrackImage(value as? UIImage, for: state)
                case "MaximumTrackImage": setMaximumTrackImage(value as? UIImage, for: state)
                default:
                    try super.setValue(value, forExpression: name)
                }
                return
            }
            try super.setValue(value, forExpression: name)
        }
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "value":
            setValue(value as! Float, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }
}

extension UIProgressView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["progressViewStyle"] = .uiProgressViewStyle

        #if arch(i386) || arch(x86_64)
            // Private
            types["barStyle"] = nil
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "progress":
            setProgress(value as! Float, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }
}

extension UIInputView {
    open override class func create(with node: LayoutNode) throws -> UIInputView {
        let inputViewStyle = try node.value(forExpression: "inputViewStyle") as? UIInputView.Style ?? .default
        return self.init(frame: .zero, inputViewStyle: inputViewStyle)
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return ["inputViewStyle": .uiInputViewStyle]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        // Read-only properties
        types["inputViewStyle"] = nil
        // Private properties
        #if arch(i386) || arch(x86_64)
            for name in [
                "assertSizingWithPredictionBar",
                "backgroundEdgeInsets",
                "contentRatio",
                "leftContentViewSize",
                "rightContentViewSize",
            ] {
                types[name] = nil
                let name = "\(name)."
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }
}

extension UIDatePicker {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["datePickerMode"] = .uiDatePickerMode

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "highlightsToday",
                "timeInterval",
                "staggerTimeIntervals",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "date":
            setDate(value as! Date, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }
}

extension UIRefreshControl {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["isRefreshing"] = .bool

        #if arch(i386) || arch(x86_64)
            // Private property
            types["refreshControlState"] = nil
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isRefreshing":
            switch (value as! Bool, isRefreshing) {
            case (true, false):
                beginRefreshing()
            case (false, true):
                endRefreshing()
            case (true, true), (false, false):
                break
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

extension UIVisualEffectView {
    open override class func create(with node: LayoutNode) throws -> UIVisualEffectView {
        let defaultStyle = RuntimeType.uiBlurEffect_Style.values["regular"]! as! UIBlurEffect.Style
        var effect = try node.value(forExpression: "effect") as? UIVisualEffect
        let style = try node.value(forExpression: "effect.style") as? UIBlurEffect.Style
        if effect == nil {
            effect = UIBlurEffect(style: style ?? defaultStyle)
        } else if let style = style {
            switch effect {
            case nil, is UIBlurEffect:
                effect = UIBlurEffect(style: style)
            case is UIVibrancyEffect:
                effect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: style))
            case let effect:
                throw LayoutError.message("\(type(of: effect)) does not have a style property")
            }
        }
        return self.init(effect: effect)
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        for (key, type) in UIView.cachedExpressionTypes {
            types["contentView.\(key)"] = type
        }
        #if arch(i386) || arch(x86_64)
            // Private properties
            types["backgroundEffects"] = nil
            types["contentEffects"] = nil
        #endif
        return types
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // Insert child views into `contentView` instead of directly
        contentView.didInsertChildNode(node, at: index)
    }
}

private var baseURLKey = 1

extension UIWebView {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["baseURL"] = .url
        types["delegate"] = RuntimeType(UIWebViewDelegate.self)
        types["htmlString"] = .string
        types["request"] = .urlRequest
        types["paginationMode"] = .uiWebPaginationMode
        types["paginationBreakingMode"] = .uiWebPaginationBreakingMode
        for (key, type) in UIScrollView.expressionTypes {
            types["scrollView.\(key)"] = type
        }
        // TODO: support loading data
        // TODO: support inline html

        #if arch(i386) || arch(x86_64)
            // Private
            types["detectsPhoneNumbers"] = nil
        #endif
        return types
    }

    open override class var bodyExpression: String? {
        return "htmlString"
    }

    @nonobjc private var baseURL: URL? {
        get { return objc_getAssociatedObject(self, &baseURLKey) as? URL }
        set {
            let url = baseURL.flatMap { $0.absoluteString.isEmpty ? nil : $0 }
            objc_setAssociatedObject(self, &baseURLKey, url, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "baseURL":
            baseURL = value as? URL
        case "htmlString":
            loadHTMLString(value as! String, baseURL: baseURL)
        case "request":
            loadRequest(value as! URLRequest)
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}

private var readAccessURLKey = 1

extension WKWebView {
    open override class func create(with node: LayoutNode) throws -> WKWebView {
        if let configuration = try node.value(forExpression: "configuration") as? WKWebViewConfiguration {
            return self.init(frame: .zero, configuration: configuration)
        }
        return self.init(frame: .zero)
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return ["configuration": RuntimeType(WKWebViewConfiguration.self)]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["baseURL"] = .url
        types["fileURL"] = .url
        types["readAccessURL"] = .url
        types["htmlString"] = .string
        types["navigationDelegate"] = RuntimeType(WKNavigationDelegate.self)
        types["request"] = .urlRequest
        types["uiDelegate"] = RuntimeType(WKUIDelegate.self)
        types["UIDelegate"] = nil // TODO: find a way to automate this renaming
        for (key, type) in UIScrollView.expressionTypes {
            types["scrollView.\(key)"] = type
        }
        for (key, type) in WKWebViewConfiguration.allPropertyTypes() {
            types["configuration.\(key)"] = type
        }
        types["configuration.mediaTypesRequiringUserActionForPlayback"] = .wkAudiovisualMediaTypes
        types["configuration.dataDetectorTypes"] = .wkDataDetectorTypes
        types["configuration.selectionGranularity"] = .wkSelectionGranularity
        // TODO: support loading data
        // TODO: support configuration url scheme handlers
        return types
    }

    open override class var bodyExpression: String? {
        return "htmlString"
    }

    @nonobjc private var readAccessURL: URL? {
        get { return objc_getAssociatedObject(self, &readAccessURLKey) as? URL }
        set {
            let url = readAccessURL.flatMap { $0.absoluteString.isEmpty ? nil : $0 }
            objc_setAssociatedObject(self, &readAccessURLKey, url, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    @nonobjc private var baseURL: URL? {
        get { return objc_getAssociatedObject(self, &baseURLKey) as? URL }
        set {
            let url = baseURL.flatMap { $0.absoluteString.isEmpty ? nil : $0 }
            objc_setAssociatedObject(self, &baseURLKey, url, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "baseURL":
            baseURL = value as? URL
        case "htmlString":
            loadHTMLString(value as! String, baseURL: baseURL)
        case "readAccessURL":
            readAccessURL = value as? URL
        case "fileURL":
            let fileURL = value as! URL
            if !fileURL.absoluteString.isEmpty, !fileURL.isFileURL {
                throw LayoutError("fileURL must refer to a local file")
            }
            loadFileURL(fileURL, allowingReadAccessTo: readAccessURL ?? fileURL)
        case "request":
            let request = value as! URLRequest
            if let url = request.url, url.isFileURL {
                loadFileURL(url, allowingReadAccessTo: readAccessURL ?? url)
            } else {
                load(request)
            }
        case "customUserAgent":
            let userAgent = value as! String
            customUserAgent = userAgent.isEmpty ? nil : userAgent
        case "uiDelegate":
            uiDelegate = value as? WKUIDelegate
        case "configuration.dataDetectorTypes",
             "configuration.mediaTypesRequiringUserActionForPlayback",
             "configuration.ignoresViewportScaleLimits":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 10, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }
}
