//  Copyright © 2017 Schibsted. All rights reserved.

import Layout
import UIKit

enum DeviceType: Int {
    case iPhone5
    case iPhone7
    case iPhone7Plus

    var portraitSize: CGSize {
        switch self {
        case .iPhone5:
            return CGSize(width: 320, height: 568)
        case .iPhone7:
            return CGSize(width: 375, height: 667)
        case .iPhone7Plus:
            return CGSize(width: 414, height: 736)
        }
    }

    var landscapeSize: CGSize {
        let size = portraitSize
        return CGSize(width: size.height, height: size.width)
    }
}

enum DeviceOrientation: Int {
    case portrait
    case landscape
}

class DesignView: UIControl {
    weak var node: LayoutNode? {
        didSet {
            update()
        }
    }

    func update() {
        guard let node = node else { return }
        layer.cornerRadius = node.view.layer.cornerRadius
        frame = node.frame
    }

    override var isSelected: Bool {
        set {
            layer.borderWidth = newValue ? 5 : 0
            layer.borderColor = tintColor.cgColor
            super.isSelected = newValue
        }
        get {
            return super.isSelected
        }
    }
}

class DesignViewController: UIViewController, UIToolbarDelegate, EditViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    private(set) var errorLabel: UILabel!

    private(set) var toolbar: UIToolbar!
    private(set) var addButton: UIBarButtonItem!
    private(set) var deleteButton: UIBarButtonItem!
    private(set) var orientationControl: UISegmentedControl!
    private(set) var deviceControl: UISegmentedControl!

    private(set) var containerView: UIView!
    private(set) var nodeContainerView: UIView!
    private(set) var uiContainerView: UIView!

    private var rootNode: LayoutNode!
    private var selectedView: DesignView?
    private var editViewController: EditViewController?
    private var error: Error? {
        didSet {
            guard let error = error else {
                errorLabel?.isHidden = true
                view.backgroundColor = .darkGray
                return
            }
            errorLabel?.text = "\(error)"
            errorLabel?.sizeToFit()
            errorLabel?.isHidden = false
            view.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        }
    }

    var selectedNode: LayoutNode? {
        didSet {
            if selectedNode != editViewController?.node {
                editViewController?.dismiss(animated: false, completion: nil)
                editViewController = nil
            }
            updateUI()
        }
    }

    private func layoutSizeFor(device: DeviceType, orientation: DeviceOrientation) -> CGSize {
        switch orientation {
        case .portrait:
            return device.portraitSize
        case .landscape:
            return device.landscapeSize
        }
    }

    var layoutSize = DeviceType.iPhone5.portraitSize {
        didSet {
            containerView.bounds.size = layoutSize
            updateLayout()
        }
    }

    func attempt(_ block: () throws -> Void) {
        do {
            try block()
        } catch {
            self.error = error
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectNode))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Container view
        containerView = UIView(frame: CGRect(origin: .zero, size: layoutSize))
        containerView.backgroundColor = .white
        view.addSubview(containerView)

        // Node container view
        nodeContainerView = UIView(frame: CGRect(origin: .zero, size: layoutSize))
        nodeContainerView.clipsToBounds = true
        containerView.addSubview(nodeContainerView)

        // UI container view
        uiContainerView = UIView(frame: CGRect(origin: .zero, size: layoutSize))
        uiContainerView.isUserInteractionEnabled = true
        uiContainerView.clipsToBounds = false
        containerView.addSubview(uiContainerView)

        // Add button
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNode))

        // Delete button
        deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteNode))
        deleteButton.isEnabled = false

        // Device control
        deviceControl = UISegmentedControl()
        deviceControl.insertSegment(withTitle: "iPhone 5", at: 0, animated: false)
        deviceControl.insertSegment(withTitle: "iPhone 7", at: 1, animated: false)
        deviceControl.insertSegment(withTitle: "iPhone 7 Plus", at: 2, animated: false)
        deviceControl.selectedSegmentIndex = 0
        deviceControl.sizeToFit()
        deviceControl.addTarget(self, action: #selector(changeDevice), for: .valueChanged)

        // Orientation control
        orientationControl = UISegmentedControl()
        orientationControl.insertSegment(withTitle: "Portrait", at: 0, animated: false)
        orientationControl.insertSegment(withTitle: "Landscape", at: 1, animated: false)
        orientationControl.selectedSegmentIndex = 0
        orientationControl.sizeToFit()
        orientationControl.addTarget(self, action: #selector(changeDevice), for: .valueChanged)

        // Toolbar
        toolbar = UIToolbar()
        toolbar.frame.size.width = view.frame.size.width
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.items = [
            addButton,
            deleteButton,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: orientationControl),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: deviceControl),
        ]
        toolbar.delegate = self
        toolbar.sizeToFit()
        view.addSubview(toolbar)

        // Error label
        errorLabel = UILabel(frame: CGRect(x: 30, y: 40, width: 1000, height: 30))
        errorLabel.textColor = .white
        view.addSubview(errorLabel)

        // Root node
        rootNode = LayoutNode(
            view: UIView(),
            expressions: ["width": "100%", "height": "100%"]
        )
        attempt { try rootNode.mount(in: nodeContainerView) }
        rebuildUIViews()
        updateUI()

        // Tree
        if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
            (navigationController.viewControllers[0] as? TreeViewController)?.layoutNode = rootNode
        }
    }

    @objc func editNode() {
        if selectedNode == editViewController?.node || error != nil {
            return
        }
        editViewController?.dismiss(animated: false, completion: nil)
        editViewController = nil
        guard let selectedNode = selectedNode, selectedNode != rootNode else {
            return
        }
        let viewController = EditViewController()
        viewController.node = selectedNode
        viewController.delegate = self
        viewController.modalPresentationStyle = .popover
        if let popoverPresentationController = viewController.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.sourceView = selectedView
            popoverPresentationController.sourceRect = selectedView!.bounds
            popoverPresentationController.passthroughViews = [view.superview!]
            popoverPresentationController.delegate = self
        }
        present(viewController, animated: false)
        editViewController = viewController
    }

    @objc func addNode() {
        let newNode = LayoutNode(view: UIView())
        if let selectedNode = selectedNode {
            newNode.view.frame = selectedNode.view.bounds
            selectedNode.addChild(newNode)
        } else {
            newNode.view.frame = rootNode.view.bounds
            rootNode.addChild(newNode)
        }

        // Tree
        if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
            for controller in navigationController.viewControllers {
                if let controller = controller as? TreeViewController {
                    if controller.layoutNode === newNode.parent {
                        controller.layoutNode = newNode.parent // Refresh
                        break
                    }
                }
            }
        }

        selectedNode = newNode
        rebuildUIViews()
        updateUI()
        editNode()
    }

    @objc func deleteNode() {
        if let selectedNode = selectedNode, selectedNode != rootNode {
            let parentNode = selectedNode.parent
            selectedNode.removeFromParent()
            rebuildUIViews()
            updateUI()

            // Tree
            if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
                for controller in navigationController.viewControllers {
                    if let controller = controller as? TreeViewController {
                        if controller.layoutNode === parentNode {
                            navigationController.popToViewController(controller, animated: true)
                            controller.layoutNode = parentNode
                            break
                        }
                    }
                }
            }
        }

        selectedNode = nil
        editViewController?.dismiss(animated: false, completion: nil)
        editViewController = nil
    }

    @objc func selectNode(_ gesture: UITapGestureRecognizer) {
        guard error == nil else {
            // Avoid breaking the UI
            return
        }
        selectedNode = (gesture.view as? DesignView)?.node
        if selectedNode != nil, selectedNode != rootNode {
            editNode()
        } else {
            editViewController?.dismiss(animated: false, completion: nil)
            editViewController = nil
        }
    }

    @objc func replaceNode(_ node: LayoutNode, with newNode: LayoutNode) {
        // Tree
        if let navigationController = splitViewController?.viewControllers[0] as? UINavigationController {
            for controller in navigationController.viewControllers {
                if let controller = controller as? TreeViewController {
                    if controller.layoutNode === node.parent {
                        controller.layoutNode = node.parent
                        navigationController.popToViewController(controller, animated: true)
                        break
                    }
                }
            }
        }

        if let parent = node.parent, let index = parent.children.index(of: node) {
            node.removeFromParent()
            parent.insertChild(newNode, at: index)
        }
        if selectedNode == node {
            selectedNode = newNode
        }
        rebuildUIViews()
        updateUI()
    }

    @objc func changeDevice() {
        let device = DeviceType(rawValue: deviceControl.selectedSegmentIndex)!
        let orientation = DeviceOrientation(rawValue: orientationControl.selectedSegmentIndex)!
        UIView.animate(withDuration: 0.25) {
            self.layoutSize = self.layoutSizeFor(device: device, orientation: orientation)
        }
    }

    private func updateUI() {
        func updateSelectedView(in containerView: UIView) {
            for view in containerView.subviews {
                if let view = view as? DesignView {
                    if view.node === selectedNode {
                        selectedView?.isSelected = false
                        selectedView = view
                        selectedView?.isSelected = true
                        return
                    }
                    updateSelectedView(in: view)
                }
            }
        }
        updateSelectedView(in: uiContainerView)
        deleteButton.isEnabled = (selectedNode != nil && selectedNode != rootNode)
    }

    private func rebuildUIViews() {
        func rebuildUIViews(for node: LayoutNode, in _: UIView) -> UIView {
            let view = DesignView()
            view.backgroundColor = .clear
            view.node = node
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectNode)))
            if node === selectedNode {
                selectedView = view
                view.isSelected = true
            }
            for child in node.children {
                view.addSubview(rebuildUIViews(for: child, in: view))
            }
            return view
        }
        rootNode.update()
        guard error == nil else {
            // Avoid breaking the UI
            return
        }
        selectedView?.removeFromSuperview()
        for subview in uiContainerView.subviews {
            subview.removeFromSuperview()
        }
        uiContainerView.addSubview(rebuildUIViews(for: rootNode, in: uiContainerView))
    }

    private func layoutUIViews() {
        func layoutUIViews(in containerView: UIView) {
            for view in containerView.subviews {
                if let view = view as? DesignView {
                    view.update()
                    layoutUIViews(in: view)
                }
            }
        }
        layoutUIViews(in: uiContainerView)
    }

    func updateLayout() {
        containerView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        nodeContainerView.frame = containerView.bounds
        uiContainerView.frame = containerView.bounds
        rootNode.update()
        layoutUIViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
        toolbar.frame.origin.y = view.bounds.height - toolbar.frame.height
    }

    func position(for _: UIBarPositioning) -> UIBarPosition {
        return .bottom
    }

    // MARK: editing

    private func deepCopyChildren(of node: LayoutNode) -> [LayoutNode] {
        var children = [LayoutNode]()
        for child in node.children {
            var viewController: UIViewController?
            if let oldViewController = child.viewController {
                viewController = type(of: oldViewController).init()
            }
            // TODO: update once class-based init is public
            if let viewController = viewController {
                children.append(
                    LayoutNode(
                        viewController: viewController,
                        expressions: child.expressions,
                        children: deepCopyChildren(of: child)
                    )
                )
            } else {
                children.append(
                    LayoutNode(
                        view: type(of: child.view).init(),
                        expressions: child.expressions,
                        children: deepCopyChildren(of: child)
                    )
                )
            }
        }
        return children
    }

    func didUpdateClass(_ cls: NSObject.Type, for node: LayoutNode) {
        error = nil
        var expressions = node.expressions
        for name in expressions.keys {
            if !LayoutNode.isValidExpressionName(name, for: cls) {
                expressions[name] = nil
            }
        }
        // TODO: update once class-based init is public
        let newNode: LayoutNode
        if let viewController = cls as? UIViewController.Type {
            newNode = LayoutNode(
                viewController: viewController,
                expressions: expressions,
                children: deepCopyChildren(of: node)
            )
        } else {
            newNode = LayoutNode(
                view: (cls as? UIView.Type) ?? UIView.self,
                expressions: expressions,
                children: deepCopyChildren(of: node)
            )
        }
        editViewController?.node = newNode
        replaceNode(node, with: newNode)
    }

    func didUpdateExpression(_ expression: String, for name: String, in node: LayoutNode) {
        error = nil
        var expressions = node.expressions
        if expression.isEmpty {
            expressions[name] = nil
        } else {
            expressions[name] = expression
        }
        var viewController: UIViewController?
        if let oldViewController = node.viewController {
            viewController = type(of: oldViewController).init()
        }
        // TODO: update once class-based init is public
        let newNode: LayoutNode
        if let viewController = viewController {
            newNode = LayoutNode(
                viewController: viewController,
                expressions: expressions,
                children: deepCopyChildren(of: node)
            )
        } else {
            newNode = LayoutNode(
                view: type(of: node.view).init(),
                expressions: expressions,
                children: deepCopyChildren(of: node)
            )
        }
        editViewController?.node = newNode
        replaceNode(node, with: newNode)
        if let error = newNode.validate().first {
            self.error = error
        }
    }

    func popoverPresentationControllerDidDismissPopover(_: UIPopoverPresentationController) {
        editViewController = nil
    }
}
