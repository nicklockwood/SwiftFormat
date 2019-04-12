//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

extension UIBarButtonItem: LayoutConfigurable {
    /// Expression names and types
    @objc class var expressionTypes: [String: RuntimeType] {
        var types = allPropertyTypes()
        types["title"] = .string
        types["image"] = .uiImage
        types["style"] = .uiBarButtonItemStyle
        types["systemItem"] = .uiBarButtonSystemItem
        return types
    }

    func bindAction(for target: AnyObject) throws {
        guard self.target !== target, let action = action else {
            return
        }
        if !target.responds(to: action) {
            throw LayoutError.message("\(target.classForCoder ?? type(of: target)) does not respond to \(action)")
        }
        self.target = target
    }

    func unbindAction(for target: AnyObject) {
        if self.target === target {
            self.target = nil
        }
    }
}

extension UIViewController: LayoutManaged {
    /// Expression names and types
    @objc open class var expressionTypes: [String: RuntimeType] {
        var types = allPropertyTypes()
        for (name, type) in UITabBarItem.allPropertyTypes() {
            types["tabBarItem.\(name)"] = type
        }
        types["tabBarItem.title"] = .string
        types["tabBarItem.image"] = .uiImage
        types["tabBarItem.systemItem"] = .uiTabBarSystemItem
        types["edgesForExtendedLayout"] = .uiRectEdge
        types["modalPresentationStyle"] = .uiModalPresentationStyle
        types["modalTransitionStyle"] = .uiModalTransitionStyle
        // TODO: tabBarItem.badgeTextAttributes
        for (name, type) in UINavigationItem.allPropertyTypes() {
            types["navigationItem.\(name)"] = type
        }
        types["navigationItem.largeTitleDisplayMode"] = .uiNavigationItem_LargeTitleDisplayMode
        types["navigationItem.leftBarButtonItems"] = .array(of: UIBarButtonItem.self)
        types["navigationItem.rightBarButtonItems"] = .array(of: UIBarButtonItem.self)
        for (name, type) in UIBarButtonItem.expressionTypes {
            types["navigationItem.leftBarButtonItem.\(name)"] = type
            types["navigationItem.rightBarButtonItem.\(name)"] = type
        }
        // TODO: barButtonItem.backgroundImage, etc

        // View properties
        for (name, type) in UIView.cachedExpressionTypes {
            types["view.\(name)"] = type
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "SKUIStackedBarSplit",
                "aggregateStatisticsDisplayCountKey",
                "appearanceTransitionsAreDisabled",
                "autoresizesArchivedViewToFullSize",
                "childModalViewController",
                "containmentSupport",
                "contentSizeForViewInPopover",
                "customNavigationInteractiveTransitionDuration",
                "customNavigationInteractiveTransitionPercentComplete",
                "customTransitioningView",
                "disableRootPromotion",
                "dropShadowView",
                "formSheetSize",
                "ignoresParentMargins",
                "isFinishingModalTransition",
                "isInAnimatedVCTransition",
                "isInWillRotateCallback",
                "isPerformingModalTransition",
                "modalTransitionView",
                "mutableChildViewControllers",
                "navigationInsetAdjustment",
                "navigationItem.useRelativeLargeTitleInsets",
                "needsDidMoveCleanup",
                "overrideTraitCollection",
                "parentModalViewController",
                "preferredFocusedItem",
                "sKUIStackedBarSplit",
                "searchBarHidNavBar",
                "shouldForceNonAnimatedTransition",
                "showsBackgroundShadow",
                "storePageProtocol",
                "useLegacyContainment",
                "wantsFullScreenLayout",
            ] {
                types[name] = nil
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
            // Read-only properties
            for name in [
                "disablesAutomaticKeyboardDismissal",
                "interfaceOrientation",
                "nibName",
                "nibBundle",
                "preferredFocusedView",
                "searchDisplayController",
                "view", // Not actually read-only, but Layout doesn't allow this to be set
            ] {
                types[name] = nil
            }
        #endif

        // Workaround for Swift availability selector limitations
        if #available(iOS 10.0, *), self is UICloudSharingController.Type {
            types["availablePermissions"] = .uiCloudSharingPermissionOptions
        }

        // UIImagePickerController support
        // Added here so we can avoid referencing UIImagePickerController in the code
        // as this causes App Store submission issues if the app isn't using the feature
        if "\(self)" == "UIImagePickerController" {
            types["cameraCaptureMode"] = .uiImagePickerControllerCameraCaptureMode
            types["cameraDevice"] = .uiImagePickerControllerCameraDevice
            types["cameraFlashMode"] = .uiImagePickerControllerCameraFlashMode
            types["imageExportPreset"] = .uiImagePickerControllerImageURLExportPreset
            types["mediaTypes"] = .array(of: .string)
            types["sourceType"] = .uiImagePickerControllerSourceType
            types["videoQuality"] = .uiImagePickerControllerQualityType
            // TODO: validate media types
            // TODO: validate videoExportPreset
            #if arch(i386) || arch(x86_64)
                // Private properties
                for name in [
                    "allowsImageEditing",
                    "initialViewControllerClassName",
                    "photosExtension",
                ] {
                    types[name] = nil
                }
            #endif
        }

        return types
    }

    private func copyTabBarItemProps(from oldItem: UITabBarItem, to newItem: UITabBarItem) {
        newItem.badgeValue = oldItem.badgeValue
        if #available(iOS 10.0, *) {
            newItem.badgeColor = oldItem.badgeColor
            // TODO: warn if badgeColor unsupported
        }
        newItem.titlePositionAdjustment = oldItem.titlePositionAdjustment
        // TODO: badgeTextAttributes
    }

    private func updateTabBarItem(title: String? = nil, image: UIImage? = nil) {
        guard let oldItem = tabBarItem else {
            tabBarItem = UITabBarItem(title: title, image: image, tag: 0)
            return
        }
        let title = title ?? tabBarItem.title
        let image = image ?? tabBarItem.image
        if tabBarItem.title != title || tabBarItem.image != image {
            tabBarItem = UITabBarItem(title: title, image: image, selectedImage: oldItem.selectedImage)
            copyTabBarItemProps(from: oldItem, to: tabBarItem)
        }
    }

    private func updateTabBarItem(systemItem: UITabBarItem.SystemItem) {
        guard let oldTabBarItem = tabBarItem else {
            tabBarItem = UITabBarItem(tabBarSystemItem: systemItem, tag: 0)
            return
        }
        tabBarItem = UITabBarItem(tabBarSystemItem: systemItem, tag: 0)
        tabBarItem.badgeValue = oldTabBarItem.badgeValue
        if #available(iOS 10.0, *) {
            tabBarItem.badgeColor = oldTabBarItem.badgeColor
            // TODO: warn if badgeColor unsupported
        }
        tabBarItem.titlePositionAdjustment = oldTabBarItem.titlePositionAdjustment
    }

    private func copyBarItemProps(from oldItem: UIBarButtonItem, to newItem: UIBarButtonItem) {
        newItem.width = oldItem.width
        newItem.possibleTitles = oldItem.possibleTitles
        newItem.customView = oldItem.customView
        newItem.tintColor = oldItem.tintColor
        // TODO: backgroundImage, etc
    }

    private func updatedBarItem(_ item: UIBarButtonItem?, title: String) -> UIBarButtonItem {
        guard var item = item else {
            return UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        }
        if item.title != title {
            let oldItem = item
            item = UIBarButtonItem(title: title, style: oldItem.style, target: oldItem.target, action: oldItem.action)
            copyBarItemProps(from: oldItem, to: item)
        }
        return item
    }

    private func updatedBarItem(_ item: UIBarButtonItem?, image: UIImage) -> UIBarButtonItem {
        guard var item = item else {
            return UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
        }
        if item.image != image {
            let oldItem = item
            item = UIBarButtonItem(image: image, style: oldItem.style, target: oldItem.target, action: oldItem.action)
            copyBarItemProps(from: oldItem, to: item)
        }
        return item
    }

    private func updatedBarItem(_ item: UIBarButtonItem?, systemItem: UIBarButtonItem.SystemItem) -> UIBarButtonItem {
        guard var item = item else {
            return UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        }
        let oldItem = item
        item = UIBarButtonItem(barButtonSystemItem: systemItem, target: oldItem.target, action: oldItem.action)
        copyBarItemProps(from: oldItem, to: item)
        return item
    }

    /// Constructor argument names and types
    @objc open class var parameterTypes: [String: RuntimeType] {
        return [:]
    }

    /// Deprecated symbols
    /// Key is the symbol name, value is the suggested replacement
    /// Empty value string indicates no replacement available
    @objc open class var deprecatedSymbols: [String: String] {
        var deprecatedSymbols = [
            "automaticallyAdjustsScrollViewInsets": "UIScrollView.contentInsetAdjustmentBehavior",
        ]
        for (key, alternative) in UIView.deprecatedSymbols {
            deprecatedSymbols["view.\(key)"] = alternative
        }
        return deprecatedSymbols
    }

    /// Called to construct the view
    @objc open class func create(with _: LayoutNode) throws -> UIViewController {
        return self.init()
    }

    /// Default expressions to use when not specified
    @objc open class var defaultExpressions: [String: String] {
        return [:]
    }

    // Set expression value
    @objc open func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "tabBarItem.title":
            updateTabBarItem(title: value as? String)
        case "tabBarItem.image":
            updateTabBarItem(image: value as? UIImage)
        case "tabBarItem.systemItem":
            updateTabBarItem(systemItem: value as! UITabBarItem.SystemItem)
        case "navigationItem.leftBarButtonItem.title":
            navigationItem.leftBarButtonItem = updatedBarItem(navigationItem.leftBarButtonItem, title: value as! String)
        case "navigationItem.leftBarButtonItem.image":
            navigationItem.leftBarButtonItem = updatedBarItem(navigationItem.leftBarButtonItem, image: value as! UIImage)
        case "navigationItem.leftBarButtonItem.systemItem":
            navigationItem.leftBarButtonItem = updatedBarItem(navigationItem.leftBarButtonItem, systemItem: value as! UIBarButtonItem.SystemItem)
        case "navigationItem.rightBarButtonItem.title":
            navigationItem.rightBarButtonItem = updatedBarItem(navigationItem.rightBarButtonItem, title: value as! String)
        case "navigationItem.rightBarButtonItem.image":
            navigationItem.rightBarButtonItem = updatedBarItem(navigationItem.rightBarButtonItem, image: value as! UIImage)
        case "navigationItem.rightBarButtonItem.systemItem":
            navigationItem.rightBarButtonItem = updatedBarItem(navigationItem.rightBarButtonItem, systemItem: value as! UIBarButtonItem.SystemItem)
        case "navigationItem.largeTitleDisplayMode":
            if #available(iOS 11.0, *) {
                navigationItem.largeTitleDisplayMode = value as! UINavigationItem.LargeTitleDisplayMode
            }
        case "imageExportPreset": // Used by UIImagePickerController
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            if name.hasPrefix("navigationItem.leftBarButtonItem."), navigationItem.leftBarButtonItem == nil {
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            } else if name.hasPrefix("navigationItem.rightBarButtonItem."),
                navigationItem.rightBarButtonItem == nil {
                navigationItem.rightBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
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
        return try _value(ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name) as Any
    }

    /// Called immediately before a child node is added
    /// Returning false will cancel insertion of the node
    @objc open func shouldInsertChildNode(_ node: LayoutNode, at _: Int) -> Bool {
        return true
    }

    /// Called immediately after a child node is added
    @objc open func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        for controller in node.viewControllers {
            addChild(controller)
        }
        node.view.frame = view.bounds
        if index > 0, let previous = node.parent?.children[index - 1].view {
            view.insertSubview(node.view, aboveSubview: previous)
        } else {
            view.addSubview(node.view)
        }
    }

    /// Called immediately before a child node is removed
    @objc open func willRemoveChildNode(_ node: LayoutNode, at _: Int) {
        for controller in node.viewControllers {
            controller.removeFromParent()
        }
        node.view.removeFromSuperview()
    }

    /// Called immediately after layout has been updated
    @objc open func didUpdateLayout(for _: LayoutNode) {}
}

extension UITabBar {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["selectedImageTintColor"] = .unavailable() // Deprecated
        types["itemPositioning"] = RuntimeType([
            "automatic": .automatic,
            "fill": .fill,
            "centered": .centered,
        ] as [String: UITabBar.ItemPositioning])
        types["barStyle"] = .uiBarStyle
        types["itemSpacing"] = .cgFloat
        types["itemWidth"] = .cgFloat
        types["items"] = .array(of: UITabBarItem.self)

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "backgroundEffects",
                "barPosition",
                "isLocked",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "delegate":
            if viewController is UITabBarController {
                if value as? UIViewController == viewController {
                    break
                }
                throw LayoutError("Cannot change the delegate of a UITabBar managed by a UITabBarController")
            }
            fallthrough
        default:
            try _setValue(value, ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name)
        }
    }
}

extension UITabBarController {
    open override class func create(with node: LayoutNode) throws -> UITabBarController {
        let tabBarController = self.init()
        let tabBarType = type(of: tabBarController.tabBar)
        if let child = node.children.first(where: { $0._class is UITabBar.Type && $0._class != tabBarType }) {
            throw LayoutError("\(child._class) is not compatible with \(tabBarType)")
        }
        return tabBarController
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["delegate"] = RuntimeType(UITabBarControllerDelegate.self)
        types["selectedIndex"] = .int
        types["viewControllers"] = .array(of: UIViewController.self)
        types["customizableViewControllers"] = .array(of: UIViewController.self)

        // Read-only properties
        types["tabBar"] = nil
        // Private properties
        #if arch(i386) || arch(x86_64)
            for name in [
                "moreChildViewControllers",
                "showsEditButtonOnLeft",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "viewControllers":
            setViewControllers(value as? [UIViewController], animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        if let viewController = node.viewController {
            var viewControllers = self.viewControllers ?? []
            viewControllers.append(viewController) // Ignore index
            setViewControllers(viewControllers, animated: false)
        } else if node.viewClass is UITabBar.Type {
            assert(node._view == nil)
            node._view = tabBar
        } else {
            super.didInsertChildNode(node, at: index)
        }
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        if let viewController = node.viewController,
            var viewControllers = self.viewControllers,
            let index = viewControllers.index(of: viewController) {
            viewControllers.remove(at: index)
            setViewControllers(viewControllers, animated: false)
        } else if !(node.viewClass is UITabBar.Type) {
            super.willRemoveChildNode(node, at: index)
        }
    }
}

extension UINavigationBar: TitleTextAttributes {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["backgroundImage"] = .uiImage
        types["titleVerticalPositionAdjustment"] = .cgFloat
        types["barStyle"] = .uiBarStyle
        types["barPosition"] = .uiBarPosition
        types["prefersLargeTitles"] = .bool
        types["items"] = .array(of: UINavigationItem.self)

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "backgroundEffects",
                "forceFullHeightInLandscape",
                "isLocked",
                "requestedContentSize",
                "rightMargin",
                "titleAutoresizesToFit",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    var titleColor: UIColor? {
        get { return titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor }
        set { titleTextAttributes?[NSAttributedString.Key.foregroundColor] = newValue }
    }

    var titleFont: UIFont? {
        get { return titleTextAttributes?[NSAttributedString.Key.font] as? UIFont }
        set { titleTextAttributes?[NSAttributedString.Key.font] = newValue }
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "items":
            setItems(value as? [UINavigationItem], animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "backgroundImage":
            setBackgroundImage(value as? UIImage, for: .default)
        case "titleVerticalPositionAdjustment":
            setTitleVerticalPositionAdjustment(value as! CGFloat, for: .default)
        case "delegate":
            if viewController is UINavigationController {
                throw LayoutError("Cannot change the delegate of a UINavigationBar managed by a UINavigationController")
            }
            delegate = value as? UINavigationBarDelegate
        case "prefersLargeTitles":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try _setValue(value, ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name)
        }
    }
}

extension UIToolbar {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["items"] = .array(of: UIBarButtonItem.self)
        types["backgroundImage"] = .uiImage
        types["shadowImage"] = .uiImage
        types["barStyle"] = .uiBarStyle
        types["barPosition"] = .uiBarPosition

        #if arch(i386) || arch(x86_64)
            // Private properties
            types["backgroundEffects"] = nil
            types["centerTextButtons"] = nil
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "backgroundImage":
            setBackgroundImage(value as? UIImage, forToolbarPosition: .any, barMetrics: .default)
        case "shadowImage":
            setShadowImage(value as? UIImage, forToolbarPosition: .any)
        case "delegate":
            if viewController is UINavigationController {
                throw LayoutError("Cannot change the delegate of a UIToolbar managed by a UINavigationController")
            }
            fallthrough
        default:
            try _setValue(value, ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name)
        }
    }
}

extension UINavigationController {
    open override class func create(with node: LayoutNode) throws -> UINavigationController {
        var navigationBarClass = try node.value(forExpression: "navigationBarClass") as? UINavigationBar.Type
        var toolbarClass = try node.value(forExpression: "toolbarClass") as? UIToolbar.Type
        for child in node.children {
            if let cls = navigationBarClass, child._class is UINavigationBar.Type {
                if (child._class as AnyClass).isSubclass(of: cls) {
                    navigationBarClass = child._class as? UINavigationBar.Type
                } else if !cls.isSubclass(of: child._class) {
                    throw LayoutError("\(child._class) is not compatible with \(cls)")
                }
            } else if let cls = toolbarClass, child._class is UIToolbar.Type {
                if (child._class as AnyClass).isSubclass(of: cls) {
                    toolbarClass = child._class as? UIToolbar.Type
                } else if !cls.isSubclass(of: child._class) {
                    throw LayoutError("\(child._class) is not compatible with \(cls)")
                }
            }
        }
        return self.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "navigationBarClass": RuntimeType(class: UINavigationBar.self),
            "toolbarClass": RuntimeType(class: UIToolbar.self),
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["viewControllers"] = .array(of: UIViewController.self)
        // Read-only properties
        for name in [
            "navigationBar",
            "toolbar",
        ] {
            types[name] = nil
        }
        // Private properties
        #if arch(i386) || arch(x86_64)
            for name in [
                "allowUserInteractionDuringTransition",
                "avoidMovingNavBarOffscreenBeforeUnhiding",
                "condensesBarsOnSwipe",
                "customNavigationTransitionDuration",
                "detailViewController",
                "disappearingViewController",
                "enableBackButtonDuringTransition",
                "isExpanded",
                "isInteractiveTransition",
                "needsDeferredTransition",
                "pretendNavBarHidden",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isNavigationBarHidden":
            setNavigationBarHidden(value as! Bool, animated: true)
        case "isToolbarHidden":
            setToolbarHidden(value as! Bool, animated: true)
        case "viewControllers":
            setViewControllers(value as! [UIViewController], animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        if let viewController = node.viewController {
            var viewControllers = self.viewControllers
            viewControllers.append(viewController) // Ignore index
            self.viewControllers = viewControllers
        } else if node.viewClass is UINavigationBar.Type {
            assert(node._view == nil)
            node._view = navigationBar
        } else if node.viewClass is UIToolbar.Type {
            assert(node._view == nil)
            node._view = toolbar
        } else {
            super.didInsertChildNode(node, at: index)
        }
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        var viewControllers = self.viewControllers
        if let viewController = node.viewController,
            let index = viewControllers.index(of: viewController) {
            viewControllers.remove(at: index)
            self.viewControllers = viewControllers
        } else {
            super.willRemoveChildNode(node, at: index)
        }
    }
}

// TODO: better support for alert actions and text fields
extension UIAlertController {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["preferredStyle"] = .uiAlertControllerStyle
        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "contentViewController",
                "textFieldsCanBecomeFirstResponder",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }
}

extension UIActivityViewController {
    open override class func create(with node: LayoutNode) throws -> UIActivityViewController {
        let activityItems: [Any] = try node.value(forExpression: "activityItems") as? [Any] ?? []
        let applicationActivities = try node.value(forExpression: "applicationActivities") as? [UIActivity]
        return self.init(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "activityItems": .array(of: .any), // TODO: validate activity item types
            "applicationActivities": RuntimeType([UIActivity].self),
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["excludedActivityTypes"] = .array(of: .uiActivityType)
        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "activitiesByUUID",
                "activity",
                "activityAlertCancelAction",
                "activityAlertController",
                "activityItemProviderOperationQueue",
                "activityItemProviderOperations",
                "activityItems",
                "activityTypeOrder",
                "activityTypesToCreateInShareService",
                "activityViewController",
                "activityViewControllerConfiguration",
                "airDropDelegate",
                "allowsEmbedding",
                "applicationActivities",
                "backgroundTaskIdentifier",
                "completedProviderCount",
                "dismissalDetectionOfViewControllerForSelectedActivityShouldAutoCancel",
                "excludedActivityCategories",
                "extensionRequestIdentifier",
                "includedActivityTypes",
                "originalPopoverBackgroundStyle",
                "performActivityForStateRestoration",
                "preferredContentSizeWithoutSafeInsets",
                "preferredContentSizeWithoutSafeInsets.height",
                "preferredContentSizeWithoutSafeInsets.width",
                "shareExtension",
                "shareServicePreferredContentSizeIsValid",
                "shouldMatchOnlyUserElectedExtensions",
                "showKeyboardAutomatically",
                "sourceIsManaged",
                "subject",
                "totalProviderCount",
                "waitingForInitialShareServicePreferredContentSize",
                "willDismissActivityViewController",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }
}

extension UIInputViewController {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        #if arch(i386) || arch(x86_64)
            // Private property
            types["hasDictation"] = nil
        #endif
        return types
    }
}

extension UISplitViewController {
    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["preferredDisplayMode"] = .uiSplitViewControllerDisplayMode
        types["viewControllers"] = .array(of: UIViewController.self)
        types["primaryEdge"] = .uiSplitViewControllerPrimaryEdge

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "gutterWidth",
                "hidesMasterViewInPortrait",
                "leadingViewController",
                "mainViewController",
                "masterColumnWidth",
                "stateRequest",
                "trailingViewController",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "primaryEdge":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try _setValue(value, ofType: type(of: self).cachedExpressionTypes[name], forKeyPath: name)
        }
    }
}
