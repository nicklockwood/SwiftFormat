//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

/// Protocol for views or view controllers that can load and display a LayoutNode
public protocol LayoutLoading: LayoutDelegate {
    /// The loaded LayoutNode instance
    /// A default implementation of this property is provided for UIView and UIViewControllers
    var layoutNode: LayoutNode? { get set }

    /// Called immediately after the layoutNode is set. Will not be called
    /// in the event of an error, or if layoutNode is set to nil
    func layoutDidLoad(_ layoutNode: LayoutNode)

    /// Fetch a localized string constant for a given key.
    /// These strings are assumed to be constant for the duration of the layout tree's lifecycle
    /// The default implementation dynamically loads the string from the Localizable.strings file
    func layoutString(forKey key: String) -> String?
}

public extension LayoutLoading {
    /// Load a named Layout xml file from a local resource bundle
    func loadLayout(
        named: String? = nil,
        bundle: Bundle = Bundle.main,
        relativeTo: String = #file,
        state: Any = (),
        constants: [String: Any]...
    ) {
        assert(Thread.isMainThread)
        let name = named ?? "\(type(of: self))".components(separatedBy: ".").last!
        guard let xmlURL = bundle.url(forResource: name, withExtension: nil) ??
            bundle.url(forResource: name, withExtension: "xml") else {
            layoutError(.message("No layout XML file found for \(name)"))
            return
        }
        loadLayout(
            withContentsOfURL: xmlURL,
            relativeTo: relativeTo,
            state: state,
            constants: merge(constants),
            completion: nil
        )
    }

    /// Load a local or remote xml file via its URL
    func loadLayout(
        withContentsOfURL xmlURL: URL,
        relativeTo: String? = #file,
        state: Any = (),
        constants: [String: Any]...,
        completion: ((LayoutError?) -> Void)? = nil
    ) {
        ReloadManager.addObserver(self)
        loader.loadLayoutNode(
            withContentsOfURL: xmlURL,
            relativeTo: relativeTo,
            state: state,
            constants: merge(constants)
        ) { layoutNode, error in
            if let layoutNode = layoutNode {
                self.layoutNode = layoutNode
            }
            if let error = error {
                self.layoutError(error)
            }
            completion?(error)
        }
    }

    /// Reload the previously loaded xml file
    func reloadLayout(withCompletion completion: ((LayoutError?) -> Void)? = nil) {
        loader.reloadLayoutNode { layoutNode, error in
            if let layoutNode = layoutNode {
                self.layoutNode = layoutNode
            }
            if let error = error {
                self.layoutError(error)
            }
            completion?(error)
        }
    }

    // Used by LayoutLoading protocol
    internal var loader: LayoutLoader {
        guard let loader = objc_getAssociatedObject(self, &loaderKey) as? LayoutLoader else {
            let loader = LayoutLoader()
            objc_setAssociatedObject(self, &loaderKey, loader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return loader
        }
        return loader
    }
}

public extension LayoutLoading where Self: UIView {
    /// Default layoutNode implementation for views
    var layoutNode: LayoutNode? {
        get {
            return objc_getAssociatedObject(self, &layoutNodeKey) as? LayoutNode
        }
        set {
            layoutNode?.unmount()
            objc_setAssociatedObject(self, &layoutNodeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            layoutNode?.unmount()
            if let layoutNode = layoutNode {
                do {
                    try layoutNode.mount(in: self)
                    layoutDidLoad(layoutNode)
                } catch {
                    layoutError(LayoutError(error, for: layoutNode))
                }
            }
        }
    }
}

public extension LayoutLoading where Self: UIViewController {
    /// Default layoutNode implementation for view controllers
    var layoutNode: LayoutNode? {
        get {
            return objc_getAssociatedObject(self, &layoutNodeKey) as? LayoutNode
        }
        set {
            layoutNode?.unmount()
            objc_setAssociatedObject(self, &layoutNodeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            layoutNode?.unmount()
            if let layoutNode = layoutNode {
                do {
                    try layoutNode.mount(in: self)
                    layoutDidLoad(layoutNode)
                } catch {
                    layoutError(LayoutError(error, for: layoutNode))
                }
            }
        }
    }
}

public extension LayoutLoading {
    /// Default layoutDidLoad(_:) implementation - does nothing
    func layoutDidLoad(_: LayoutNode) {}

    /// Default layoutString implementation - bubbles request up to the first responder
    /// that will handle it, or dynamically loads localized string  from Localizable.strings
    /// file in the local resources if no overridden implementation is found
    func layoutString(forKey key: String) -> String? {
        var responder = (self as? UIResponder)?.next
        while responder != nil {
            if let stringHandler = responder as? LayoutLoading {
                return stringHandler.layoutString(forKey: key)
            }
            responder = responder?.next ?? (responder as? UIViewController)?.parent
        }
        do {
            return try loader.loadLocalizedStrings()[key]
        } catch {
            layoutError(LayoutError(error))
            return nil
        }
    }
}

// MARK: private

private var layoutNodeKey = 1
private var loaderKey = 1
