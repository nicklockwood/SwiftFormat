//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

private class LayoutTableView: UITableView {
    open override var intrinsicContentSize: CGSize {
        guard layoutNode != nil else {
            return super.intrinsicContentSize
        }
        return CGSize(
            width: contentSize.width + contentInset.left + contentInset.right,
            height: contentSize.height + contentInset.top + contentInset.bottom
        )
    }

    open override var contentSize: CGSize {
        didSet {
            if oldValue != contentSize, let layoutNode = layoutNode {
                layoutNode.contentSizeChanged()
            }
        }
    }
}

private var swizzled = NSMutableSet()

private extension UITableView {
    @objc var layout_intrinsicContentSize: CGSize {
        guard layoutNode != nil else {
            if imp(of: #selector(getter: intrinsicContentSize), of: type(of: self),
                   matches: #selector(getter: self.layout_intrinsicContentSize)) {
                return super.intrinsicContentSize
            }
            return self.layout_intrinsicContentSize
        }
        return CGSize(
            width: contentSize.width + contentInset.left + contentInset.right,
            height: contentSize.height + contentInset.top + contentInset.bottom
        )
    }

    @objc func layout_setContentSize(_ size: CGSize) {
        if imp(of: #selector(setter: contentSize), of: type(of: self),
               matches: #selector(layout_setContentSize(_:))) {
            super.contentSize = size
        } else {
            layout_setContentSize(size)
        }
        if size != contentSize, let layoutNode = layoutNode {
            layoutNode.contentSizeChanged()
        }
    }
}

extension UITableView: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UITableView {
        let style = try node.value(forExpression: "style") as? UITableView.Style ?? .plain
        let tableView: UITableView = {
            if self == UITableView.self {
                return LayoutTableView(frame: .zero, style: style)
            } else {
                if !isSubclass(of: LayoutTableView.self), !swizzled.contains(self) {
                    replace(#selector(getter: intrinsicContentSize), of: self,
                            with: #selector(getter: layout_intrinsicContentSize))
                    replace(#selector(setter: contentSize), of: self,
                            with: #selector(layout_setContentSize(_:)))
                    swizzled.add(self)
                }
                return self.init(frame: .zero, style: style)
            }
        }()
        tableView.enableAutoSizing()
        return tableView
    }

    fileprivate func enableAutoSizing() {
        estimatedRowHeight = 44
        rowHeight = UITableView.automaticDimension
        estimatedSectionHeaderHeight = 0
        sectionHeaderHeight = UITableView.automaticDimension
        estimatedSectionFooterHeight = 0
        sectionFooterHeight = UITableView.automaticDimension
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "style": .uiTableViewStyle,
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["separatorStyle"] = .uiTableViewCellSeparatorStyle
        types["separatorInsetReference"] = .uiTableViewSeparatorInsetReference
        for name in [
            "contentSize",
            "contentSize.height",
            "contentSize.width",
        ] {
            types[name] = .unavailable()
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "countStringInsignificantRowCount",
                "currentTouch",
                "indexHiddenForSearch",
                "multiselectCheckmarkColor",
                "overlapsSectionHeaderViews",
                "sectionBorderColor",
                "separatorBottomShadowColor",
                "separatorTopShadowColor",
                "tableHeaderBackgroundColor",
                "usesVariableMargins",
            ] {
                types[name] = nil
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "separatorInsetReference":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isEditing":
            setEditing(value as! Bool, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func shouldInsertChildNode(_ node: LayoutNode, at _: Int) -> Bool {
        do {
            switch node.viewClass {
            case is UITableViewCell.Type:
                if let reuseIdentifier = try node.value(forExpression: "reuseIdentifier") as? String {
                    registerLayout(Layout(node), forReuseIdentifier: reuseIdentifier, key: &cellDataKey)
                } else {
                    layoutError(.message("UITableViewCell template missing reuseIdentifier"))
                }
            case is UITableViewHeaderFooterView.Type:
                if let reuseIdentifier = try node.value(forExpression: "reuseIdentifier") as? String {
                    registerLayout(Layout(node), forReuseIdentifier: reuseIdentifier, key: &headerDataKey)
                } else {
                    layoutError(.message("UITableViewHeaderFooterView template missing reuseIdentifier"))
                }
            default:
                return true
            }
        } catch {
            layoutError(LayoutError(error))
        }
        return false
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        if tableHeaderView == nil {
            tableHeaderView = node.view
        } else if tableFooterView == nil {
            tableFooterView = node.view
        } else {
            super.didInsertChildNode(node, at: index)
        }
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        let hadView = (node._view != nil)
        super.willRemoveChildNode(node, at: index)
        guard let view = node._view else { return }
        // Check we didn't accidentally instantiate the view
        // TODO: it would be better to do this in a unit test
        assert(hadView)
        if view == tableHeaderView {
            tableHeaderView = nil
        } else if view == tableFooterView {
            tableFooterView = nil
        }
    }

    open override func didUpdateLayout(for _: LayoutNode) {
        for cell in visibleCells {
            cell.layoutNode?.update()
        }
    }
}

extension UITableViewController: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UITableViewController {
        let style = try node.value(forExpression: "style") as? UITableView.Style ?? .plain
        let viewController = self.init(style: style)
        if !node.children.contains(where: { $0.viewClass is UITableView.Type }) {
            viewController.tableView.enableAutoSizing()
        } else if node.expressions.keys.contains(where: { $0.hasPrefix("tableView.") }) {
            // TODO: figure out how to propagate this config to the view once it has been created
        }
        return viewController
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "style": .uiTableViewStyle,
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        for (key, type) in UITableView.cachedExpressionTypes {
            types["tableView.\(key)"] = type
        }
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case _ where name.hasPrefix("tableView."):
            try tableView.setValue(value, forExpression: String(name["tableView.".endIndex ..< name.endIndex]))
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func shouldInsertChildNode(_ node: LayoutNode, at index: Int) -> Bool {
        switch node.viewClass {
        case is UITableViewCell.Type, is UITableViewHeaderFooterView.Type:
            return tableView?.shouldInsertChildNode(node, at: index) ?? false
        default:
            return true
        }
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // TODO: what if more than one tableView is added?
        if node.viewClass is UITableView.Type {
            let wasLoaded = (viewIfLoaded != nil)
            tableView = node.view as? UITableView
            if wasLoaded {
                viewDidLoad()
            }
            return
        }
        tableView.didInsertChildNode(node, at: index)
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        if node.viewClass is UITableView.Type {
            tableView = nil
            return
        }
        tableView.willRemoveChildNode(node, at: index)
    }
}

extension UITableView: LayoutDelegate {
    public func layoutValue(forKey key: String) throws -> Any? {
        if let layoutNode = layoutNode {
            return try layoutNode.value(forParameterOrVariableOrConstant: key)
        }
        return nil
    }
}

private var cellDataKey = 0
private var headerDataKey = 0
private var nodesKey = 0

extension UITableView {
    private enum LayoutData {
        case success(Layout, Any, [String: Any])
        case failure(Error)
    }

    private func registerLayoutData(
        _ layoutData: LayoutData,
        forReuseIdentifier identifier: String,
        key: UnsafeRawPointer
    ) {
        var layoutsData = objc_getAssociatedObject(self, key) as? NSMutableDictionary
        if layoutsData == nil {
            layoutsData = [:]
            objc_setAssociatedObject(self, key, layoutsData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        layoutsData![identifier] = layoutData
    }

    fileprivate func registerLayout(
        _ layout: Layout,
        state: Any = (),
        constants: [String: Any]...,
        forReuseIdentifier identifier: String,
        key: UnsafeRawPointer
    ) {
        registerLayoutData(
            .success(layout, state, merge(constants)),
            forReuseIdentifier: identifier,
            key: key
        )
    }

    // MARK: UITableViewHeaderFooterView recycling

    public func registerLayout(
        named: String,
        bundle: Bundle = Bundle.main,
        relativeTo: String = #file,
        state: Any = (),
        constants: [String: Any]...,
        forHeaderFooterViewReuseIdentifier identifier: String
    ) {
        do {
            let layout = try LayoutLoader().loadLayout(
                named: named,
                bundle: bundle,
                relativeTo: relativeTo
            )
            registerLayout(
                layout,
                state: state,
                constants: merge(constants),
                forReuseIdentifier: identifier,
                key: &headerDataKey
            )
        } catch {
            layoutError(LayoutError(error))
            registerLayoutData(.failure(error), forReuseIdentifier: identifier, key: &headerDataKey)
        }
    }

    public func dequeueReusableHeaderFooterNode(withIdentifier identifier: String) -> LayoutNode? {
        if let view = dequeueReusableHeaderFooterView(withIdentifier: identifier) {
            guard let node = view.layoutNode else {
                preconditionFailure("\(type(of: view)) is not a Layout-managed view")
            }
            if !view.isHidden {
                node.update()
                return node
            }
            // TODO: reusing a tableHeaderFooterView after reload causes it to be
            // permanently hidden, which breaks layout. figure out why that is
        }
        guard let layoutsData = objc_getAssociatedObject(self, &headerDataKey) as? NSMutableDictionary,
            let layoutData = layoutsData[identifier] as? LayoutData else {
            return nil
        }
        var nodes = objc_getAssociatedObject(self, &nodesKey) as? NSMutableArray
        if nodes == nil {
            nodes = []
            objc_setAssociatedObject(self, &nodesKey, nodes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        do {
            switch layoutData {
            case let .success(layout, state, constants):
                let node = try LayoutNode(
                    layout: layout,
                    state: state,
                    constants: constants
                )
                nodes?.add(node)
                node.delegate = self
                try node.bind(to: node.view) // TODO: find a better solution for binding
                node._view?.setValue(identifier, forKey: "reuseIdentifier")
                return node
            case let .failure(error):
                throw error
            }
        } catch {
            layoutError(LayoutError(error))
            return nil
        }
    }

    // MARK: UITableViewCell recycling

    public func registerLayout(
        named: String,
        bundle: Bundle = Bundle.main,
        relativeTo: String = #file,
        state: Any = (),
        constants: [String: Any]...,
        forCellReuseIdentifier identifier: String
    ) {
        do {
            let layout = try LayoutLoader().loadLayout(
                named: named,
                bundle: bundle,
                relativeTo: relativeTo
            )
            registerLayout(
                layout,
                state: state,
                constants: merge(constants),
                forReuseIdentifier: identifier,
                key: &cellDataKey
            )
        } catch {
            layoutError(LayoutError(error))
            registerLayoutData(.failure(error), forReuseIdentifier: identifier, key: &cellDataKey)
        }
    }

    public func dequeueReusableCellNode(withIdentifier identifier: String) -> LayoutNode? {
        if let cell = dequeueReusableCell(withIdentifier: identifier) {
            guard let node = cell.layoutNode else {
                preconditionFailure("\(type(of: cell)) is not a Layout-managed view")
            }
            return node
        }
        guard let layoutsData = objc_getAssociatedObject(self, &cellDataKey) as? NSMutableDictionary,
            let layoutData = layoutsData[identifier] as? LayoutData else {
            return nil
        }
        do {
            switch layoutData {
            case let .success(layout, state, constants):
                let node = try LayoutNode(
                    layout: layout,
                    state: state,
                    constants: constants
                )
                var nodes = objc_getAssociatedObject(self, &nodesKey) as? NSMutableArray
                if nodes == nil {
                    nodes = []
                    objc_setAssociatedObject(self, &nodesKey, nodes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
                nodes?.add(node)
                node.delegate = self
                let cell = node.view
                cell.setValue(identifier, forKey: "reuseIdentifier")
                try node.bind(to: cell) // TODO: find a better solution for binding
                return node
            case let .failure(error):
                throw error
            }
        } catch {
            layoutError(LayoutError(error))
            return nil
        }
    }

    public func dequeueReusableCellNode(withIdentifier identifier: String, for _: IndexPath) -> LayoutNode {
        guard let node = dequeueReusableCellNode(withIdentifier: identifier) else {
            let layoutsData = objc_getAssociatedObject(self, &cellDataKey) as? NSMutableDictionary
            if layoutsData?[identifier] == nil {
                layoutError(.message("No cell layout has been registered for \(identifier)"))
            }
            return LayoutNode(view: UITableViewCell())
        }
        return node
    }
}

private class LayoutTableViewHeaderFooterView: UITableViewHeaderFooterView {
    // TODO: it looks like UITableView doesn't use this for auto-sizing sections header/footer - remove it?
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let layoutNode = layoutNode {
            let height = (try? layoutNode.doubleValue(forSymbol: "height")) ?? 0
            return CGSize(width: size.width, height: CGFloat(height))
        }
        return super.sizeThatFits(size)
    }
}

private extension UITableViewHeaderFooterView {
    @objc func layout_sizeThatFits(_ size: CGSize) -> CGSize {
        if let layoutNode = layoutNode {
            let height = (try? layoutNode.doubleValue(forSymbol: "height")) ?? 0
            return CGSize(width: size.width, height: CGFloat(height))
        }
        if imp(of: #selector(sizeThatFits(_:)), of: type(of: self),
               matches: #selector(layout_sizeThatFits(_:))) {
            return super.sizeThatFits(size)
        } else {
            return layout_sizeThatFits(size)
        }
    }
}

extension UITableViewHeaderFooterView: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UITableViewHeaderFooterView {
        let reuseIdentifier = try node.value(forExpression: "reuseIdentifier") as? String
        let view: UITableViewHeaderFooterView = {
            if self == UITableViewHeaderFooterView.self {
                return LayoutTableViewHeaderFooterView(reuseIdentifier: reuseIdentifier)
            } else {
                if !isSubclass(of: LayoutTableViewHeaderFooterView.self), !swizzled.contains(self) {
                    replace(#selector(sizeThatFits(_:)), of: self,
                            with: #selector(layout_sizeThatFits(_:)))
                    swizzled.add(self)
                }
                return self.init(reuseIdentifier: reuseIdentifier)
            }
        }()
        if node.expressions.keys.contains(where: { $0.hasPrefix("backgroundView.") }),
            !node.expressions.keys.contains("backgroundView") {
            // Add a background view if required
            view.backgroundView = UIView(frame: view.bounds)
        }
        return view
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "reuseIdentifier": .string,
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["backgroundColor"] = .unavailable("Setting backgroundColor on UITableViewHeaderFooterView is not supported. Use contentView.backgroundColor instead.")
        types["editingAccessoryType"] = types["accessoryType"]
        for (key, type) in UIView.cachedExpressionTypes {
            types["contentView.\(key)"] = type
            types["backgroundView.\(key)"] = type
        }
        for (key, type) in UILabel.cachedExpressionTypes {
            types["textLabel.\(key)"] = type
            types["detailTextLabel.\(key)"] = type
        }

        // Private and read-only properties
        for name in [
            "backgroundImage",
            "textAlignment",
            "text",
        ] + [
            "reuseIdentifier",
            "sectionHeader",
            "table",
            "tableView",
            "tableViewStyle",
        ] {
            types[name] = nil
        }
        #if arch(i386) || arch(x86_64)
            for name in [
                "floating",
                "maxTitleWidth",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // Insert child views into `contentView` instead of directly
        contentView.didInsertChildNode(node, at: index)
    }

    open override var intrinsicContentSize: CGSize {
        guard let layoutNode = layoutNode, layoutNode.children.isEmpty else {
            return super.intrinsicContentSize
        }
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: textLabel?.intrinsicContentSize.height ?? UIView.noIntrinsicMetric
        )
    }
}

private class LayoutTableViewCell: UITableViewCell {
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let layoutNode = layoutNode {
            let height = (try? layoutNode.doubleValue(forSymbol: "height")) ?? 0
            return CGSize(width: size.width, height: CGFloat(height))
        }
        return super.sizeThatFits(size)
    }
}

private extension UITableViewCell {
    @objc func layout_sizeThatFits(_ size: CGSize) -> CGSize {
        if let layoutNode = layoutNode {
            let height = (try? layoutNode.doubleValue(forSymbol: "height")) ?? 0
            return CGSize(width: size.width, height: CGFloat(height))
        }
        if imp(of: #selector(sizeThatFits(_:)), of: type(of: self),
               matches: #selector(layout_sizeThatFits(_:))) {
            return super.sizeThatFits(size)
        } else {
            return layout_sizeThatFits(size)
        }
    }
}

extension UITableViewCell: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UITableViewCell {
        let style = try node.value(forExpression: "style") as? UITableViewCell.CellStyle ?? .default
        let reuseIdentifier = try node.value(forExpression: "reuseIdentifier") as? String
        let cell: UITableViewCell = {
            if self == UITableViewCell.self {
                return LayoutTableViewCell(style: style, reuseIdentifier: reuseIdentifier)
            } else {
                if !isSubclass(of: LayoutTableViewCell.self), !swizzled.contains(self) {
                    replace(#selector(sizeThatFits(_:)), of: self,
                            with: #selector(layout_sizeThatFits(_:)))
                    swizzled.add(self)
                }
                return self.init(style: style, reuseIdentifier: reuseIdentifier)
            }
        }()
        if node.expressions.keys.contains(where: { $0.hasPrefix("backgroundView.") }),
            !node.expressions.keys.contains("backgroundView") {
            // Add a backgroundView view if required
            cell.backgroundView = UIView(frame: cell.bounds)
        }
        if node.expressions.keys.contains(where: { $0.hasPrefix("selectedBackgroundView.") }),
            !node.expressions.keys.contains("selectedBackgroundView") {
            // Add a selectedBackground view if required
            cell.selectedBackgroundView = UIView(frame: cell.bounds)
        }
        return cell
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return [
            "style": .uiTableViewCellStyle,
            "reuseIdentifier": .string,
        ]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["selectionStyle"] = .uiTableViewCellSelectionStyle
        types["focusStyle"] = .uiTableViewCellFocusStyle
        types["accessoryType"] = .uiTableViewCellAccessoryType
        types["editingAccessoryType"] = types["accessoryType"]
        for (key, type) in UIView.cachedExpressionTypes {
            types["contentView.\(key)"] = type
            types["backgroundView.\(key)"] = type
            types["selectedBackgroundView.\(key)"] = type
        }
        for (key, type) in UIImageView.cachedExpressionTypes {
            types["imageView.\(key)"] = type
        }
        for (key, type) in UILabel.cachedExpressionTypes {
            types["textLabel.\(key)"] = type
            types["detailTextLabel.\(key)"] = type
        }

        // Private and read-only properties
        types["lineBreakMode"] = nil
        types["textAlignment"] = nil
        types["textColor"] = nil
        #if arch(i386) || arch(x86_64)
            for name in [
                "accessoryAction",
                "bottomShadowColor",
                "clipsContents",
                "drawingEnabled",
                "hidesAccessoryWhenEditing",
                "returnAction",
                "sectionBorderColor",
                "sectionLocation",
                "selectedTextColor",
                "selectionFadeDuration",
                "selectionTintColor",
                "separatorColor",
                "separatorStyle",
                "tableBackgroundColor",
                "tableSpecificElementsHidden",
                "tableViewStyle",
                "textFieldOffset",
                "topShadowColor",
                "wasSwiped",
            ] + [
                "editingStyle",
                "reuseIdentifier",
                "showingDeleteConfirmation",
            ] {
                types[name] = nil
            }
        #endif
        return types
    }

    open override class var bodyExpression: String? {
        return "textLabel.attributedText"
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "isEditing":
            setEditing(value as! Bool, animated: true)
        case "isSelected":
            setSelected(value as! Bool, animated: true)
        case "isHighlighted":
            setHighlighted(value as! Bool, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // Insert child views into `contentView` instead of directly
        contentView.didInsertChildNode(node, at: index)
    }
}
