//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

@available(*, deprecated, message: "Use the LayoutLoading protocol instead")
open class LayoutViewController: UIViewController, LayoutLoading {
    /// Called immediately after the layoutNode is set. Will not be called
    /// in the event of an error, or if layoutNode is set to nil
    open func layoutDidLoad(_: LayoutNode) {
        // Mimic old behaviour if not overriden
        layoutDidLoad()
    }

    /// Called immediately after the layoutNode is set. Will not be called
    /// in the event of an error, or if layoutNode is set to nil
    @available(*, deprecated, message: "Use layoutDidLoad(_ layoutNode:) instead")
    open func layoutDidLoad() {
        // Override in subclass
    }

    /// Default error handler implementation - bubbles error up to the first responder
    /// that will handle it, or displays LayoutConsole if no handler is found
    open func layoutError(_ error: LayoutError) {
        DispatchQueue.main.async {
            var responder = self.next
            while responder != nil {
                if let errorHandler = responder as? LayoutLoading {
                    errorHandler.layoutError(error)
                    return
                }
                responder = responder?.next ?? (responder as? UIViewController)?.parent
            }
            LayoutConsole.showError(error)
        }
    }
}
