//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation
import UIKit

class ReloadManager {
    private static var boxes = [ObserverBox]()

    private struct ObserverBox {
        weak var observer: LayoutLoading?
    }

    // Useful for testing
    static var observers: [LayoutLoading] {
        return boxes.compactMap { $0.observer }
    }

    static func addObserver(_ observer: LayoutLoading) {
        // Clean up unregistered observers so array doesn't grow indefinitely
        var alreadyRegistered = false
        boxes = boxes.filter {
            guard let o = $0.observer else { return false }
            if o === observer { alreadyRegistered = true }
            return true
        }
        if alreadyRegistered {
            return
        }
        boxes.append(ObserverBox(observer: observer))

        #if arch(i386) || arch(x86_64)

            if !UIResponder.handlerInstalled {
                // Swizzle UIResponder.keyCommands so we can handle Cmd-R correctly
                // regardless of which view or controller currently has focus
                // (Don't worry, this code is only included in simulator builds)
                replace(#selector(getter: UIResponder.keyCommands), of: UIResponder.self,
                        with: #selector(UIResponder.layout_keyCommands))
                UIResponder.handlerInstalled = true
            }

        #endif
    }

    static func reload(hard: Bool) {
        for observer in observers {
            if hard {
                observer.loader.clearSourceURLs()
            }
            LayoutConsole.hide() // TODO: remove this dependency?
            observer.reloadLayout()
        }
    }
}

#if arch(i386) || arch(x86_64)

    private extension UIResponder {
        static var handlerInstalled = false

        @objc func layout_keyCommands() -> [UIKeyCommand]? {
            return (layout_keyCommands() ?? []) + [
                UIKeyCommand(
                    input: "r",
                    modifierFlags: .command,
                    action: #selector(layout_reloadLayout)
                ),
                UIKeyCommand(
                    input: "r",
                    modifierFlags: [.command, .alternate],
                    action: #selector(layout_hardReloadLayout)
                ),
            ]
        }

        @objc private func layout_reloadLayout() {
            ReloadManager.reload(hard: false)
        }

        @objc private func layout_hardReloadLayout() {
            ReloadManager.reload(hard: true)
        }
    }

#endif
