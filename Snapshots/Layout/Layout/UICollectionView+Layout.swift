//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

private let placeholderID = NSUUID().uuidString

private class Box {
    weak var node: LayoutNode?
    init(_ node: LayoutNode) {
        self.node = node
    }
}

extension UICollectionViewLayout {
    fileprivate static func defaultLayout(for node: LayoutNode) -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        if node.expressions["collectionViewLayout.itemSize"] ??
            node.expressions["collectionViewLayout.itemSize.width"] ??
            node.expressions["collectionViewLayout.itemSize.height"] == nil {
            flowLayout.estimatedItemSize = flowLayout.itemSize
        }
        if #available(iOS 10.0, *) {
            flowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
        } else {
            flowLayout.itemSize = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return flowLayout
    }
}

private class LayoutCollectionView: UICollectionView {
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

private extension UICollectionView {
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

extension UICollectionView: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UICollectionView {
        // UICollectionView cannot be created with a nil collectionViewLayout
        // so we cannot allow create(with:) to throw. Instead, we'll intercept the error
        let layout = node.attempt {
            try node.value(forExpression: "collectionViewLayout")
        } as? UICollectionViewLayout ?? .defaultLayout(for: node)
        let collectionView: UICollectionView = {
            if self == UICollectionView.self {
                return LayoutCollectionView(frame: .zero, collectionViewLayout: layout)
            } else {
                if !isSubclass(of: LayoutCollectionView.self), !swizzled.contains(self) {
                    replace(#selector(getter: intrinsicContentSize), of: self,
                            with: #selector(getter: layout_intrinsicContentSize))
                    replace(#selector(setter: contentSize), of: self,
                            with: #selector(layout_setContentSize(_:)))
                    swizzled.add(self)
                }
                return self.init(frame: .zero, collectionViewLayout: layout)
            }
        }()
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: placeholderID)
        return collectionView
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        for (key, type) in UICollectionViewFlowLayout.allPropertyTypes() {
            types["collectionViewLayout.\(key)"] = type
        }
        types["collectionViewLayout.sectionInsetReference"] = .uiCollectionViewFlowLayoutSectionInsetReference
        types["collectionViewLayout.scrollDirection"] = .uiCollectionViewScrollDirection
        types["reorderingCadence"] = .uiCollectionViewReorderingCadence

        for name in [
            "contentSize",
            "contentSize.height",
            "contentSize.width",
        ] {
            types[name] = .unavailable()
        }
        return types
    }

    open override func setAnimatedValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "collectionViewLayout":
            setCollectionViewLayout(value as! UICollectionViewLayout, animated: true)
        default:
            try super.setAnimatedValue(value, forExpression: name)
        }
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "reorderingCadence", "collectionViewLayout.sectionInsetReference":
            // Does nothing on iOS 10 and earlier
            if #available(iOS 11.0, *) {
                fallthrough
            }
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func shouldInsertChildNode(_ node: LayoutNode, at _: Int) -> Bool {
        if node.viewClass is UICollectionViewCell.Type {
            do {
                if let reuseIdentifier = try node.value(forExpression: "reuseIdentifier") as? String {
                    registerLayout(Layout(node), forCellReuseIdentifier: reuseIdentifier)
                } else {
                    layoutError(.message("UICollectionViewCell template missing reuseIdentifier"))
                }
            } catch {
                layoutError(LayoutError(error))
            }
            return false
        }
        return true
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        if backgroundView == nil {
            backgroundView = node.view // TODO: this is a bit inconsistent with UITableView - reconsider?
        } else {
            super.didInsertChildNode(node, at: index)
        }
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        let hadView = (node._view != nil)
        super.willRemoveChildNode(node, at: index)
        if node._view == backgroundView {
            backgroundView = nil
        }
        // Check we didn't accidentally instantiate the view
        // TODO: it would be better to do this in a unit test
        assert(hadView || node._view == nil)
    }

    open override func didUpdateLayout(for _: LayoutNode) {
        for cell in visibleCells {
            cell.layoutNode?.update()
        }
    }
}

extension UICollectionView: LayoutDelegate {
    public func layoutValue(forKey key: String) throws -> Any? {
        if let layoutNode = layoutNode {
            return try layoutNode.value(forParameterOrVariableOrConstant: key)
        }
        return nil
    }
}

extension UICollectionViewController: LayoutBacked {
    open override class func create(with node: LayoutNode) throws -> UICollectionViewController {
        let layout = try node.value(forExpression: "collectionViewLayout") as? UICollectionViewLayout ?? .defaultLayout(for: node)
        let viewController = self.init(collectionViewLayout: layout)
        guard let collectionView = viewController.collectionView else {
            throw LayoutError("Failed to create collectionView")
        }
        if !node.children.contains(where: { $0.viewClass is UICollectionView.Type }) {
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: placeholderID)
        } else if node.expressions.keys.contains(where: { $0.hasPrefix("collectionView.") }) {
            // TODO: figure out how to propagate this config to the view once it has been created
        }
        return viewController
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        types["collectionViewLayout"] = RuntimeType(UICollectionViewFlowLayout.self)
        for (key, type) in UICollectionViewFlowLayout.allPropertyTypes() {
            types["collectionViewLayout.\(key)"] = type
        }
        types["collectionViewLayout.sectionInsetReference"] = .uiCollectionViewFlowLayoutSectionInsetReference
        types["collectionViewLayout.scrollDirection"] = .uiCollectionViewScrollDirection
        for (key, type) in UICollectionView.cachedExpressionTypes {
            types["collectionView.\(key)"] = type
        }
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        switch name {
        case "collectionViewLayout":
            collectionView?.collectionViewLayout = value as! UICollectionViewLayout
        case _ where name.hasPrefix("collectionViewLayout."):
            try collectionView?.setValue(value, forExpression: name)
        case _ where name.hasPrefix("collectionView."):
            try collectionView?.setValue(value, forExpression: String(name["collectionView.".endIndex ..< name.endIndex]))
        default:
            try super.setValue(value, forExpression: name)
        }
    }

    open override func shouldInsertChildNode(_ node: LayoutNode, at index: Int) -> Bool {
        switch node.viewClass {
        case is UICollectionViewCell.Type:
            return collectionView?.shouldInsertChildNode(node, at: index) ?? false
        default:
            return true
        }
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // TODO: what if more than one collectionView is added?
        if node.viewClass is UICollectionView.Type {
            let wasLoaded = (viewIfLoaded != nil)
            collectionView = node.view as? UICollectionView
            if wasLoaded {
                viewDidLoad()
            }
            return
        }
        collectionView?.didInsertChildNode(node, at: index)
    }

    open override func willRemoveChildNode(_ node: LayoutNode, at index: Int) {
        if node.viewClass is UICollectionView.Type {
            collectionView = nil
            return
        }
        collectionView?.willRemoveChildNode(node, at: index)
    }
}

private var cellDataKey = 0
private var nodesKey = 0

extension UICollectionView {
    private enum LayoutData {
        case success(Layout, Any, [String: Any])
        case failure(Error)
    }

    private func registerLayoutData(
        _ layoutData: LayoutData,
        forCellReuseIdentifier identifier: String
    ) {
        var layoutsData = objc_getAssociatedObject(self, &cellDataKey) as? NSMutableDictionary
        if layoutsData == nil {
            layoutsData = [:]
            objc_setAssociatedObject(self, &cellDataKey, layoutsData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        layoutsData![identifier] = layoutData
    }

    fileprivate func registerLayout(
        _ layout: Layout,
        state: Any = (),
        constants: [String: Any]...,
        forCellReuseIdentifier identifier: String
    ) {
        do {
            let viewClass: AnyClass = try layout.getClass()
            guard var cellClass = viewClass as? UICollectionViewCell.Type else {
                throw LayoutError.message("\(viewClass)) is not a subclass of UICollectionViewCell")
            }
            if cellClass == UICollectionViewCell.self {
                cellClass = LayoutCollectionViewCell.self
            } else if !cellClass.isSubclass(of: LayoutCollectionViewCell.self),
                !swizzled.contains(cellClass) {
                replace(#selector(getter: intrinsicContentSize), of: cellClass,
                        with: #selector(getter: layout_intrinsicContentSize))
                replace(#selector(sizeThatFits(_:)), of: cellClass,
                        with: #selector(UICollectionViewCell.layout_sizeThatFits(_:)))
                swizzled.add(cellClass)
            }
            register(cellClass, forCellWithReuseIdentifier: identifier)
            registerLayoutData(.success(layout, state, merge(constants)), forCellReuseIdentifier: identifier)
        } catch {
            layoutError(LayoutError(error))
            registerLayoutData(.failure(error), forCellReuseIdentifier: identifier)
        }
    }

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
                forCellReuseIdentifier: identifier
            )
        } catch {
            registerLayoutData(.failure(error), forCellReuseIdentifier: identifier)
        }
    }

    public func dequeueReusableCellNode(withIdentifier identifier: String, for indexPath: IndexPath) -> LayoutNode {
        do {
            guard let layoutsData = objc_getAssociatedObject(self, &cellDataKey) as? NSMutableDictionary,
                let layoutData = layoutsData[identifier] as? LayoutData else {
                throw LayoutError.message("No cell layout has been registered for \(identifier)")
            }
            let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
            if let node = cell.layoutNode {
                node.update() // Ensure frame is updated before re-use
                return node
            }
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
                assert(node._view == nil)
                node._view = cell
                try node.bind(to: cell) // TODO: find a better solution for binding
                cell.layoutNode = node
                return node
            case let .failure(error):
                throw error
            }
        } catch {
            layoutError(LayoutError(error))
            return LayoutNode(view: dequeueReusableCell(withReuseIdentifier: placeholderID, for: indexPath))
        }
    }
}

private class LayoutCollectionViewCell: UICollectionViewCell {
    open override var intrinsicContentSize: CGSize {
        guard let layoutNode = layoutNode, layoutNode.children.isEmpty else {
            return super.intrinsicContentSize
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let layoutNode = layoutNode {
            let height = (try? layoutNode.doubleValue(forSymbol: "height")) ?? 0
            return CGSize(width: size.width, height: CGFloat(height))
        }
        return super.sizeThatFits(size)
    }
}

private extension UICollectionViewCell {
    @objc var layout_intrinsicContentSize: CGSize {
        guard let layoutNode = layoutNode, layoutNode.children.isEmpty else {
            if imp(of: #selector(getter: intrinsicContentSize), of: type(of: self),
                   matches: #selector(getter: self.layout_intrinsicContentSize)) {
                return super.intrinsicContentSize
            } else {
                return self.layout_intrinsicContentSize
            }
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

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

extension UICollectionViewCell: LayoutBacked {
    open override class func create(with _: LayoutNode) throws -> UICollectionViewCell {
        throw LayoutError.message("UICollectionViewCells must be created by UICollectionView")
    }

    open override class var parameterTypes: [String: RuntimeType] {
        return ["reuseIdentifier": .string]
    }

    open override class var expressionTypes: [String: RuntimeType] {
        var types = super.expressionTypes
        for (key, type) in UIView.cachedExpressionTypes {
            types["contentView.\(key)"] = type
            types["backgroundView.\(key)"] = type
            types["selectedBackgroundView.\(key)"] = type
        }
        return types
    }

    open override func setValue(_ value: Any, forExpression name: String) throws {
        if name.hasPrefix("backgroundView."), backgroundView == nil {
            // Add a backgroundView view if required
            backgroundView = UIView(frame: bounds)
        } else if name.hasPrefix("selectedBackgroundView."), selectedBackgroundView == nil {
            // Add a selectedBackgroundView view if required
            selectedBackgroundView = UIView(frame: bounds)
        }
        try super.setValue(value, forExpression: name)
    }

    open override func didInsertChildNode(_ node: LayoutNode, at index: Int) {
        // Insert child views into `contentView` instead of directly
        contentView.didInsertChildNode(node, at: index)
    }
}
