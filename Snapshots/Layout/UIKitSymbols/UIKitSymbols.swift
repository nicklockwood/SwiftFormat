//  Copyright © 2017 Schibsted. All rights reserved.

import AVKit
import GLKit
import MapKit
import SceneKit
import SpriteKit
import UIKit
import WebKit
import XCTest

@testable import Layout

class UIKitSymbols: XCTestCase {
    func getProperties() -> [String: [String: RuntimeType]] {
        // Force classes to load
        _ = AVPlayerViewController()
        _ = WKWebView()

        // Get class names
        var classCount: UInt32 = 0
        let classes = objc_copyClassList(&classCount)
        var names = ["SKView"] // Doesn't load otherwise for some reason
        for cls in UnsafeBufferPointer(start: classes, count: Int(classCount)) {
            if class_getSuperclass(cls) != nil,
                cls.isSubclass(of: UIView.self) || cls.isSubclass(of: UIViewController.self) {
                let name = NSStringFromClass(cls)
                if !name.contains("_"), !name.contains(".") {
                    names.append(name)
                }
            }
        }

        // Filter views
        // These lists are longer than the actual list of view we support
        // but the advantage of thie approach is that new classes added in
        // future iOS releases will be picked up automatically
        let whitelist = [
            "AVPlayerViewController",
            "AVPictureInPictureViewController",
            "MKOverlay",
            "MKMapView",
            "GLK",
            "SCNView",
            "SKView",
            "UI",
            "WKWebView",
        ]
        let blacklist = [
            "AVPlayerViewControllerContentView",
            "AVPlayerViewControllerCustomControlsView",
            "AVPlayerViewControllerCustomControlsViewLayoutMarginsGuideProvidingView",
            "MKOverlayContainer",
            "UIAccessibility",
            "UIActionSheet",
            "UIActivityGroupViewController",
            "UIActivityViewPopoverBackgroundView",
            "UIAlertView",
            "UIApplication",
            "UIAutocorrect",
            "UIAutoRotatingWindow",
            "UIButtonLabel",
            "UICallout",
            "UICheckeredPatternView",
            "UIClassic",
            "UICollectionViewControllerWrapperView",
            "UICollectionViewTable",
            "UICompatibilityInputViewController",
            "UICoverSheetButton",
            "UIDateLabel",
            "UIDatePickerContentView",
            "UIDatePickerWeekMonthDayView",
            "UIDebugging",
            "UIDefaultKeyboardInput",
            "UIDictation",
            "UIDimmingView",
            "UIDocument",
            "UIDOM",
            "UIDropShadowView",
            "UIDynamicCaret",
            "UIFieldEditor",
            "UIGroupTable",
            "UIIndexBar",
            "UIInputS",
            "UIInputWindow",
            "UIInsertControl",
            "UIInterface",
            "UIKB",
            "UIKeyCommand",
            "UIKeyboard",
            "UILayoutContainerView",
            "UIMainPrinterUtilityCell",
            "UIMore",
            "UIMorphingLabel",
            "UIMovieScrubber",
            "UIMultiColumnViewController",
            "UINavigationBarBackIndicatorView",
            "UINavigationButton",
            "UINavigationTransitionView",
            "UINotesTableView",
            "UIPageController",
            "UIPasscodeField",
            "UIPageControllerScrollView",
            "UIPanel",
            "UIPDF",
            "UIPeripheral",
            "UIPickerContentView",
            "UIPickerColumnView",
            "UIPickerTableView",
            "UIPopoverB",
            "UIPrint",
            "UIProgressHUD",
            "UIProgressIndicator",
            "UIRecent",
            "UIReferenceLibraryViewController",
            "UIRemoteKeyboardWindow",
            "UIRemoveControl",
            "UIRoundedRect",
            "UISegment",
            "UISearch",
            "UISelection",
            "UIShadow",
            "UISnapshot",
            "UISplitAndMaskView",
            "UISpringBoard",
            "UISoftware",
            "UIStatusBar",
            "UISegment",
            "UISwappableImageView",
            "UISwipe",
            "UISwitch",
            "UISystemInputViewController",
            "UITabBar",
            "UITableViewBackground",
            "UITableViewCell",
            "UITableViewCollectionCell",
            "UITableViewCountView",
            "UITableViewIndex",
            "UITableViewLabel",
            "UITableViewWrapperView",
            "UIText",
            "UIToolbar",
            "UITransitionView",
            "UIURLDragPreviewView",
            "UIVideoEditorController",
            "UIViewControllerWrapperView",
            "UIWeb",
            "UIWindow",
            "UIWK",
            "UIZoomViewController",
        ]
        names = names.filter { name in
            whitelist.contains { name.hasPrefix($0) } &&
                !blacklist.contains { name.hasPrefix($0) }
        }
        names += [
            "UISearchBar",
            "UISearchController",
            "UISegmentedControl",
            "UISwitch",
            "UITabBar",
            "UITabBarController",
            "UITableViewCell",
            "UITextField",
            "UITextView",
            "UIToolbar",
            "UIWebView",
        ]

        // Get properties
        var result = [String: [String: RuntimeType]]()
        for name in names {
            var props: [String: RuntimeType]
            guard let cls = NSClassFromString(name), let superclass = class_getSuperclass(cls) else {
                continue
            }
            switch cls {
            case let viewClass as UIView.Type:
                props = viewClass.cachedExpressionTypes
                if viewClass == UIView.self {
                    break
                }
                for (key, type) in (superclass as! UIView.Type).cachedExpressionTypes where props[key] == type {
                    props.removeValue(forKey: key)
                }
            case let controllerClass as UIViewController.Type:
                props = controllerClass.cachedExpressionTypes
                if controllerClass == UIViewController.self {
                    break
                }
                for (key, type) in (superclass as! UIViewController.Type).cachedExpressionTypes where props[key] == type {
                    props.removeValue(forKey: key)
                }
            default:
                props = [:]
            }
            for (key, type) in props where !type.isAvailable {
                props.removeValue(forKey: key)
            }
            result[name] = props
        }
        return result
    }

    func testBuildLayoutToolSymbols() {
        if #available(iOS 11.0, *) {} else {
            XCTFail("Must be run with latest iOS SDK to ensure all symbols are supported")
            return
        }

        // Build output
        var output = ""
        let properties = getProperties()
        for name in properties.keys.sorted() {
            let props = properties[name]!
            var superclassName: String?
            if let cls = NSClassFromString(name), let superclass = class_getSuperclass(cls),
                superclass is UIView.Type || superclass is UIViewController.Type {
                superclassName = NSStringFromClass(superclass)
            }
            output += "    symbols[\"\(name)\"] = ["
            if let superclassName = superclassName {
                output += "\n        \"superclass\": \"\(superclassName)\","
            }
            if props.isEmpty, superclassName == nil {
                output += ":]\n"
            } else {
                output += "\n"
                for prop in props.keys.sorted() {
                    let type = props[prop]!
                    output += "        \"\(prop)\": \"\(type)\",\n"
                }
                output += "    ]\n"
            }
        }

        output = "//  Copyright © 2017 Schibsted. All rights reserved.\n\n" +
            "import Foundation\n\n" +
            "// NOTE: This is a machine-generated file. Run the UIKitSymbols scheme to regenerate\n\n" +
            "let UIKitSymbols: [String: [String: String]] = {\n" +
            "    var symbols = [String: [String: String]]()\n" + output +
            "    return symbols\n" +
            "}()\n"

        // Write output
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("LayoutTool/Symbols.swift")

        guard FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("\(url) does not exist")
            return
        }

        XCTAssertNoThrow(try output.write(to: url, atomically: true, encoding: .utf8))
    }

    func testBuildSublimeCompletions() {
        if #available(iOS 11.0, *) {} else {
            XCTFail("Must be run with latest iOS SDK to ensure all symbols are supported")
            return
        }

        // Build output
        var rows = [
            "{ \"trigger\": \"outlet\tString\", \"contents\": \"outlet=\\\"$0\\\"\" }",
            "{ \"trigger\": \"template\tURL\", \"contents\": \"template=\\\"$0\\\"\" }",
            "{ \"trigger\": \"xml\tURL\", \"contents\": \"xml=\\\"$0\\\"\" }",
        ]
        for name in Array(layoutSymbols).sorted() {
            let type = (name == "center") ? "CGPoint" : "CGFloat"
            rows.append("{ \"trigger\": \"\(name)\t\(type)\", \"contents\": \"\(name)\" }")
        }
        let properties = getProperties()
        for name in properties.keys.sorted() {
            let props = properties[name]!
            rows.append("{ \"trigger\": \"\(name)\", \"contents\": \"\(name) $0/>\" }")
            for prop in props.keys.sorted() {
                let type = props[prop]!
                let row = "{ \"trigger\": \"\(prop)\t\(type)\", \"contents\": \"\(prop)\" }"
                if !rows.contains(row) {
                    rows.append(row)
                }
            }
        }

        let output = "{\n" +
            "    \"scope\": \"text.xml\",\n" +
            "    \"completions\": [\n        " + rows.sorted().joined(separator: ",\n        ") + "\n" +
            "    ]\n" +
            "}\n"

        // Write output
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("layout.sublime-completions")

        guard FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("\(url) does not exist")
            return
        }

        XCTAssertNoThrow(try output.write(to: url, atomically: true, encoding: .utf8))
    }
}
