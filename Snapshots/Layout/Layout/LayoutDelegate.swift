//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

/// Optional delegate protocol to be implemented by a LayoutNode's owner
public protocol LayoutDelegate: class {
    /// Handle errors produced by the layout during an update
    /// The default implementation displays a red box error alert using the LayoutConsole
    func layoutError(_ error: LayoutError)

    /// A variable or constant value inherited from the delegate
    /// Layout will call this method for any expression symbol that it doesn't
    /// recognize. If the method returns nil, an error will be thrown
    func layoutValue(forKey key: String) throws -> Any?
}

extension LayoutDelegate {
    /// Default error handler implementation - bubbles error up to the first responder
    /// that will handle it, or displays LayoutConsole if no handler is found
    public func layoutError(_ error: LayoutError) {
        DispatchQueue.main.async {
            var responder = (self as? UIResponder)?.next
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

    /// Default implementation - returns nothing
    public func layoutValue(forKey _: String) throws -> Any? {
        return nil
    }
}
