//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit

extension NSObject {
    private static var propertiesKey = 0

    private class func localPropertyTypes() -> [String: RuntimeType] {
        // Check for memoized props
        if let memoized = objc_getAssociatedObject(self, &propertiesKey) as? [String: RuntimeType] {
            return memoized
        }
        let name = "\(self)"
        if !name.hasPrefix("("), name.contains("_") { // We don't want to mess with private stuff
            return [:]
        }
        var allProperties = [String: RuntimeType]()
        func addProperty(_ name: String, _ type: RuntimeType) {
            allProperties[name] = type
            switch type.kind {
            case let .struct(type):
                switch type {
                case "CGPoint":
                    for key in ["x", "y"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "CGSize":
                    for key in ["width", "height"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "CGVector":
                    for key in ["dx", "dy"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "CGRect":
                    allProperties["\(name).origin"] = .cgPoint
                    allProperties["\(name).size"] = .cgSize
                    for key in [
                        "x", "y",
                        "width", "height",
                        "origin.x", "origin.y",
                        "size.width", "size.height",
                    ] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "CGAffineTransform":
                    for key in [
                        "rotation",
                        "scale", "scale.x", "scale.y",
                        "translation.x", "translation.y",
                    ] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "CATransform3D":
                    for key in [
                        "rotation", "rotation.x", "rotation.y", "rotation.z",
                        "scale", "scale.x", "scale.y", "scale.z",
                        "translation.x", "translation.y", "translation.z",
                        "m34", // Used for perspective
                    ] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "UIEdgeInsets":
                    for key in ["top", "left", "bottom", "right"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "UIOffset":
                    for key in ["horizontal", "vertical"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                case "NSDirectionalEdgeInsets":
                    for key in ["top", "leading", "bottom", "trailing"] {
                        allProperties["\(name).\(key)"] = .cgFloat
                    }
                default:
                    break
                }
            default:
                break
            }
        }
        // Gather properties
        var numberOfProperties: CUnsignedInt = 0
        if let properties = class_copyPropertyList(self, &numberOfProperties) {
            for i in 0 ..< Int(numberOfProperties) {
                let cprop = properties[i]
                let cname: UnsafePointer<Int8> = property_getName(cprop)
                if let cattribs = property_getAttributes(cprop) {
                    var name = String(cString: cname)
                    guard !name.contains("_"), // We don't want to mess with private stuff
                        allProperties[name] == nil else {
                        continue
                    }
                    // Get attributes
                    let setter = "set\(name.capitalized()):"
                    guard instancesRespond(to: Selector(setter)) else {
                        continue
                    }
                    let attribs = String(cString: cattribs).components(separatedBy: ",")
                    let objCType = String(attribs[0].unicodeScalars.dropFirst())
                    guard let type = RuntimeType(objCType: objCType) else {
                        continue
                    }
                    if case let .any(type) = type.kind, type is Bool.Type,
                        let attrib = attribs.first(where: { $0.hasPrefix("Gis") }) {
                        name = String(attrib.unicodeScalars.dropFirst())
                    }
                    let typeName = type.description
                    if !typeName.hasPrefix("("), typeName.contains("_") { // We don't want to mess with private stuff
                        continue
                    }
                    addProperty(name, type)
                }
            }
        }
        // Gather setter methods
        var numberOfMethods: CUnsignedInt = 0
        if let methods = class_copyMethodList(self, &numberOfMethods) {
            let maxChars = 256
            let ctype = UnsafeMutablePointer<Int8>.allocate(capacity: maxChars)
            for i in 0 ..< Int(numberOfMethods) {
                let method = methods[i]
                let selector: Selector = method_getName(method)
                var name = "\(selector)"
                guard name.hasPrefix("set"), let colonRange = name.range(of: ":"),
                    colonRange.upperBound == name.endIndex, !name.hasPrefix("set_") else {
                    continue
                }
                name = String(name["set".endIndex ..< colonRange.lowerBound])
                let isName = "is\(name)"
                guard allProperties[isName] == nil else {
                    continue
                }
                let characters = name.unicodeScalars
                name = (characters.first.map { String($0) } ?? "").lowercased() + String(characters.dropFirst())
                guard allProperties[name] == nil else {
                    continue
                }
                method_getArgumentType(method, 2, ctype, maxChars)
                var objCType = String(cString: ctype)
                if objCType == "@", name.hasSuffix("olor") {
                    objCType = "@\"UIColor\"" // Workaround for runtime not knowing the type
                }
                guard let type = RuntimeType(objCType: objCType) else {
                    continue
                }
                if case let .any(type) = type.kind, type is Bool.Type,
                    instancesRespond(to: Selector(isName)) {
                    name = isName
                }
                addProperty(name, type)
            }
            ctype.deallocate()
        }
        // Accessibility properties (TODO: find a way to automate this)
        if conforms(to: UIAccessibilityIdentification.self) ||
            self is UIView.Type || self is UIBarItem.Type || self is UIImage.Type {
            addProperty("accessibilityIdentifier", .string)
        }
        addProperty("isAccessibilityElement", .bool)
        addProperty("accessibilityLabel", .string)
        addProperty("accessibilityAttributedLabel", .nsAttributedString)
        addProperty("accessibilityHint", .string)
        addProperty("accessibilityAttributedHint", .nsAttributedString)
        addProperty("accessibilityValue", .string)
        addProperty("accessibilityAttributedValue", .nsAttributedString)
        addProperty("accessibilityTraits", .uiAccessibilityTraits)
        addProperty("accessibilityFrame", .cgRect)
        addProperty("accessibilityPath", .uiBezierPath)
        addProperty("accessibilityActivationPoint", .cgPoint)
        addProperty("accessibilityLanguage", .string)
        addProperty("accessibilityElementsHidden", .bool)
        addProperty("accessibilityViewIsModal", .bool)
        addProperty("shouldGroupAccessibilityChildren", .bool)
        addProperty("accessibilityNavigationStyle", .uiAccessibilityNavigationStyle)

        // Memoize properties
        objc_setAssociatedObject(self, &propertiesKey, allProperties, .OBJC_ASSOCIATION_RETAIN)
        return allProperties
    }

    class func allPropertyTypes(excluding baseClass: NSObject.Type = NSObject.self) -> [String: RuntimeType] {
        assert(isSubclass(of: baseClass))
        var allProperties = [String: RuntimeType]()
        var cls: NSObject.Type = self
        while cls !== baseClass {
            for (name, type) in cls.localPropertyTypes() where allProperties[name] == nil {
                allProperties[name] = type
            }
            cls = cls.superclass() as? NSObject.Type ?? baseClass
        }
        return allProperties
    }

    // Safe version of `setValue(forKeyPath:)`
    // Checks that the property exists, and is settable, but doesn't validate the type
    func _setValue(_ value: Any, ofType type: RuntimeType?, forKey key: String) throws {
        _ = try _setValue(value, ofType: type, forKey: key, animated: false)
    }

    // Animated version of `_setValue(_:ofType:forKey:)`
    func _setValue(_ value: Any, ofType type: RuntimeType?, forKey key: String, animated: Bool) throws -> Bool {
        if let setter = type?.setter {
            try setter(self, key, value)
            return true
        }
        var key = key
        var setter: String
        do {
            if key.hasPrefix("is") {
                let trimmedKey = String(key.dropFirst(2))
                setter = "set\(trimmedKey):"
                if responds(to: Selector(setter)) {
                    key = trimmedKey.unCapitalized()
                } else {
                    setter = "setIs\(trimmedKey):"
                }
            } else {
                setter = "set\(key.capitalized()):"
            }
        }
        if animated, let type = type {
            let selector = Selector("\(setter)animated:")
            guard responds(to: selector) else {
                return false
            }
            switch type.kind {
            case let .any(type):
                let method = class_getMethodImplementation(Swift.type(of: self), selector)
                switch type {
                case is Double.Type:
                    let fn = unsafeBitCast(
                        method,
                        to: (@convention(c) (AnyObject?, Selector, Double, ObjCBool) -> Void).self
                    )
                    fn(self, selector, Double(truncating: value as! NSNumber), true)
                    return true
                case is Float.Type:
                    let fn = unsafeBitCast(
                        method,
                        to: (@convention(c) (AnyObject?, Selector, Float, ObjCBool) -> Void).self
                    )
                    fn(self, selector, Float(truncating: value as! NSNumber), true)
                    return true
                case is Bool.Type:
                    let fn = unsafeBitCast(
                        method,
                        to: (@convention(c) (AnyObject?, Selector, ObjCBool, ObjCBool) -> Void).self
                    )
                    fn(self, selector, ObjCBool(Bool(truncating: value as! NSNumber)), true)
                    return true
                case is CGPoint.Type:
                    let fn = unsafeBitCast(
                        method,
                        to: (@convention(c) (AnyObject?, Selector, CGPoint, ObjCBool) -> Void).self
                    )
                    fn(self, selector, value as! CGPoint, true)
                    return true
                case is AnyObject.Type:
                    let fn = unsafeBitCast(
                        method,
                        to: (@convention(c) (AnyObject?, Selector, AnyObject, ObjCBool) -> Void).self
                    )
                    fn(self, selector, value as AnyObject, true)
                    return true
                default:
                    break
                }
            default:
                break
            }
            print("No animated setter implementation for \(selector)")
            return false
        }
        guard responds(to: Selector(setter)) else {
            if #available(iOS 11.0, *) {} else {
                switch key {
                case "accessibilityAttributedLabel":
                    accessibilityLabel = (value as? NSAttributedString)?.string
                    return true
                case "accessibilityAttributedHint":
                    accessibilityHint = (value as? NSAttributedString)?.string
                    return true
                case "accessibilityAttributedValue":
                    accessibilityValue = (value as? NSAttributedString)?.string
                    return true
                default:
                    break
                }
            }
            if self is NSValue {
                throw SymbolError("Cannot set property \(key) of immutable \(Swift.type(of: self))", for: key)
            }
            let mirror = Mirror(reflecting: self)
            if mirror.children.contains(where: { $0.label == key }) {
                throw LayoutError("\(classForCoder) \(key) property must be prefixed with @objc to be set at runtime")
            }
            throw SymbolError("Unknown property \(key) of \(classForCoder)", for: key)
        }
        setValue(value, forKey: key)
        return true
    }

    // Safe version of setValue(forKeyPath:)
    // Checks that the property exists, and is settable, but doesn't validate the type
    func _setValue(_ value: Any, ofType type: RuntimeType?, forKeyPath name: String) throws {
        guard let range = name.range(of: ".", options: .backwards) else {
            try _setValue(value, ofType: type, forKey: name)
            return
        }
        var prevKey = name
        var prevTarget: NSObject?
        var target = self as NSObject
        var key: String = String(name[range.upperBound ..< name.endIndex])
        for subkey in name[name.startIndex ..< range.lowerBound].components(separatedBy: ".") {
            guard target.responds(to: Selector(subkey)) else {
                if target is NSValue {
                    key = "\(subkey).\(key)"
                    break
                }
                throw SymbolError("Unknown property \(subkey) of \(target.classForCoder)", for: name)
            }
            guard let nextTarget = target.value(forKey: subkey) as? NSObject else {
                // We have no way to specify optional assignment, so we'll just fail silently here
                return
            }
            prevKey = subkey
            prevTarget = target
            target = nextTarget
        }
        guard target is NSValue else {
            try target._setValue(value, ofType: type, forKey: key)
            return
        }
        // TODO: optimize this
        var newValue: NSValue?
        switch target {
        case var point as CGPoint where value is NSNumber:
            switch key {
            case "x":
                point.x = CGFloat(truncating: value as! NSNumber)
                newValue = point as NSValue
            case "y":
                point.y = CGFloat(truncating: value as! NSNumber)
                newValue = point as NSValue
            default:
                break
            }
        case var size as CGSize where value is NSNumber:
            switch key {
            case "width":
                size.width = CGFloat(truncating: value as! NSNumber)
                newValue = size as NSValue
            case "height":
                size.height = CGFloat(truncating: value as! NSNumber)
                newValue = size as NSValue
            default:
                break
            }
        case var vector as CGVector where value is NSNumber:
            switch key {
            case "dx":
                vector.dx = CGFloat(truncating: value as! NSNumber)
                newValue = vector as NSValue
            case "dy":
                vector.dy = CGFloat(truncating: value as! NSNumber)
                newValue = vector as NSValue
            default:
                break
            }
        case var rect as CGRect:
            if value is NSNumber {
                switch key {
                case "x":
                    rect.origin.x = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "y":
                    rect.origin.y = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "width":
                    rect.size.width = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "height":
                    rect.size.height = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "origin.x":
                    rect.origin.x = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "origin.y":
                    rect.origin.y = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "size.width":
                    rect.size.width = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                case "size.height":
                    rect.size.height = CGFloat(truncating: value as! NSNumber)
                    newValue = rect as NSValue
                default:
                    break
                }
            } else if key == "origin" {
                if let value = value as? CGPoint {
                    rect.origin = value
                    newValue = rect as NSValue
                }
            } else if key == "size" {
                if let value = value as? CGSize {
                    rect.size = value
                    newValue = rect as NSValue
                }
            }
        case is CGAffineTransform where value is NSNumber &&
            ((prevTarget is UIView && prevKey == "transform") ||
                (prevTarget is CALayer && prevKey == "affineTransform")):
            switch key {
            case "rotation", "scale", "scale.x", "scale.y", "translation.x", "translation.y":
                prevTarget!.setValue(value, forKeyPath: "layer.transform.\(key)")
                return
            default:
                break
            }
        case var transform as CATransform3D where value is NSNumber && prevTarget != nil:
            switch key {
            case "rotation", "rotation.x", "rotation.y", "rotation.z",
                 "scale", "scale.x", "scale.y", "scale.z",
                 "translation.x", "translation.y", "translation.z":
                prevTarget!.setValue(value, forKeyPath: "\(prevKey).\(key)")
                return
            case "m34": // Used for setting perspective
                transform.m34 = CGFloat(truncating: value as! NSNumber)
                newValue = transform as NSValue
            default:
                break
            }
        case var insets as UIEdgeInsets where value is NSNumber:
            switch key {
            case "top":
                insets.top = CGFloat(truncating: value as! NSNumber)
                newValue = insets as NSValue
            case "left":
                insets.left = CGFloat(truncating: value as! NSNumber)
                newValue = insets as NSValue
            case "bottom":
                insets.bottom = CGFloat(truncating: value as! NSNumber)
                newValue = insets as NSValue
            case "right":
                insets.right = CGFloat(truncating: value as! NSNumber)
                newValue = insets as NSValue
            default:
                break
            }
        case var offset as UIOffset where value is NSNumber:
            switch key {
            case "horizontal":
                offset.horizontal = CGFloat(truncating: value as! NSNumber)
                newValue = offset as NSValue
            case "vertical":
                offset.vertical = CGFloat(truncating: value as! NSNumber)
                newValue = offset as NSValue
            default:
                break
            }
        case let nsValue as NSValue where String(cString: nsValue.objCType).hasPrefix("{NSDirectionalEdgeInsets="):
            if #available(iOS 11.0, *) {
                var insets = nsValue.directionalEdgeInsetsValue
                switch key {
                case "top":
                    insets.top = CGFloat(truncating: value as! NSNumber)
                    newValue = NSValue(directionalEdgeInsets: insets)
                case "leading":
                    insets.leading = CGFloat(truncating: value as! NSNumber)
                    newValue = NSValue(directionalEdgeInsets: insets)
                case "bottom":
                    insets.bottom = CGFloat(truncating: value as! NSNumber)
                    newValue = NSValue(directionalEdgeInsets: insets)
                case "trailing":
                    insets.trailing = CGFloat(truncating: value as! NSNumber)
                    newValue = NSValue(directionalEdgeInsets: insets)
                default:
                    break
                }
            }
        default:
            break
        }
        if let value = newValue {
            if let prevTarget = prevTarget {
                prevTarget.setValue(value, forKey: prevKey)
                return
            }
            throw SymbolError("No valid setter found for property \(key) of \(target.classForCoder)", for: name)
        }
        throw SymbolError("Cannot set property \(key) of immutable \(target.classForCoder)", for: name)
    }

    /// Safe version of value(forKey:)
    /// Checks that the property exists, and is gettable, but doesn't validate the type
    func _value(ofType type: RuntimeType?, forKey key: String) throws -> Any? {
        if let getter = type?.getter {
            return getter(self, key)
        }
        if responds(to: Selector(key)) {
            return value(forKey: key)
        }
        switch self {
        case let point as CGPoint:
            switch key {
            case "x":
                return point.x
            case "y":
                return point.y
            default:
                throw SymbolError("Unknown property \(key) of CGPoint", for: key)
            }
        case let size as CGSize:
            switch key {
            case "width":
                return size.width
            case "height":
                return size.height
            default:
                throw SymbolError("Unknown property \(key) of CGSize", for: key)
            }
        case let vector as CGVector:
            switch key {
            case "dx":
                return vector.dx
            case "dy":
                return vector.dy
            default:
                throw SymbolError("Unknown property \(key) of CGVector", for: key)
            }
        case let rect as CGRect:
            switch key {
            case "x":
                return rect.origin.x
            case "y":
                return rect.origin.y
            case "width":
                return rect.width
            case "height":
                return rect.height
            case "origin":
                return rect.origin
            case "size":
                return rect.size
            case "minX":
                return rect.minX
            case "maxX":
                return rect.maxX
            case "minY":
                return rect.minY
            case "maxY":
                return rect.maxY
            case "midX":
                return rect.midX
            case "midY":
                return rect.midY
            default:
                throw SymbolError("Unknown property \(key) of CGRect", for: key)
            }
        case is CGAffineTransform:
            throw SymbolError("Unknown property \(key) of CGAffineTransform", for: key)
        case let transform as CATransform3D:
            switch key {
            case "m34":
                return transform.m34 // Used for perspective
            default:
                throw SymbolError("Unknown property \(key) of CATransform3D", for: key)
            }
        case let insets as UIEdgeInsets:
            switch key {
            case "top":
                return insets.top
            case "left":
                return insets.left
            case "bottom":
                return insets.bottom
            case "right":
                return insets.right
            default:
                throw SymbolError("Unknown property \(key) of UIEdgeInsets", for: key)
            }
        case let offset as UIOffset:
            switch key {
            case "horizontal":
                return offset.horizontal
            case "vertical":
                return offset.vertical
            default:
                throw SymbolError("Unknown property \(key) of UIOffset", for: key)
            }
        default:
            if #available(iOS 11.0, *) {} else {
                switch key {
                case "accessibilityAttributedLabel":
                    return accessibilityLabel.map(NSAttributedString.init(string:))
                case "accessibilityAttributedHint":
                    return accessibilityHint.map(NSAttributedString.init(string:))
                case "accessibilityAttributedValue":
                    return accessibilityValue.map(NSAttributedString.init(string:))
                default:
                    break
                }
            }
            let mirror = Mirror(reflecting: self)
            if mirror.children.contains(where: { $0.label == key }) {
                throw LayoutError("\(classForCoder) \(key) property must be prefixed with @objc to be accessed at runtime")
            }
            throw SymbolError("Unknown property \(key) of \(classForCoder)", for: key)
        }
    }

    /// Safe version of value(forKeyPath:)
    /// Checks that the property exists, and is gettable, but doesn't validate the type
    func _value(ofType type: RuntimeType?, forKeyPath name: String) throws -> Any? {
        guard let range = name.range(of: ".", options: .backwards) else {
            do {
                return try _value(ofType: type, forKey: name)
            } catch let error as SymbolError {
                var description = error.description
                description = description.replacingOccurrences(of: " of \(classForCoder)", with: "")
                throw SymbolError(description, for: name)
            }
        }
        var prevKey = name
        var prevTarget: NSObject?
        var target = self as NSObject
        var key: String = String(name[range.upperBound ..< name.endIndex])
        for subkey in name[name.startIndex ..< range.lowerBound].components(separatedBy: ".") {
            if target is NSValue {
                key = "\(subkey).\(key)"
                break
            }
            guard target.responds(to: Selector(subkey)) else {
                throw SymbolError("Unknown property \(subkey) of \(target.classForCoder)", for: name)
            }
            guard let nextTarget = target.value(forKey: subkey) as? NSObject else {
                return nil
            }
            prevKey = subkey
            prevTarget = target
            target = nextTarget
        }
        if let prevTarget = prevTarget {
            switch target {
            case is CGRect:
                switch key {
                case "origin.x", "origin.y", "size.width", "size.height":
                    return prevTarget.value(forKeyPath: "\(prevKey).\(key)")
                default:
                    break
                }
            case is CGAffineTransform where
                (prevTarget is UIView && prevKey == "transform") ||
                (prevTarget is CALayer && prevKey == "affineTransform"):
                switch key {
                case "rotation", "scale", "scale.x", "scale.y", "translation.x", "translation.y":
                    return prevTarget.value(forKeyPath: "layer.transform.\(key)")
                default:
                    break
                }
            case is CATransform3D:
                switch key {
                case "rotation", "rotation.x", "rotation.y", "rotation.z",
                     "scale", "scale.x", "scale.y", "scale.z",
                     "translation.x", "translation.y", "translation.z":
                    return prevTarget.value(forKeyPath: "\(prevKey).\(key)")
                default:
                    break
                }
            case let nsValue as NSValue where String(cString: nsValue.objCType).hasPrefix("{NSDirectionalEdgeInsets="):
                if #available(iOS 11.0, *) {
                    switch key {
                    case "top":
                        return nsValue.directionalEdgeInsetsValue.top
                    case "leading":
                        return nsValue.directionalEdgeInsetsValue.leading
                    case "bottom":
                        return nsValue.directionalEdgeInsetsValue.bottom
                    case "trailing":
                        return nsValue.directionalEdgeInsetsValue.trailing
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        return try SymbolError.wrap({ try target._value(ofType: type, forKey: key) }, for: name)
    }
}
