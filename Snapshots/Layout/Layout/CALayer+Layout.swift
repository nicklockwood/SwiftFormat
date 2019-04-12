//  Copyright © 2017 Schibsted. All rights reserved.

import QuartzCore

extension CALayer: LayoutConfigurable {
    /// Expression names and types
    @objc class var expressionTypes: [String: RuntimeType] {
        var types = allPropertyTypes()
        types["contents"] = .cgImage
        for key in [
            "borderWidth",
            "contentsScale",
            "cornerRadius",
            "shadowRadius",
            "rasterizationScale",
            "zPosition",
        ] {
            types[key] = .cgFloat
        }
        types["contentsGravity"] = .caLayerContentsGravity
        types["edgeAntialiasingMask"] = .caEdgeAntialiasingMask
        types["fillMode"] = .caMediaTimingFillMode
        types["minificationFilter"] = .caLayerContentsFilter
        types["magnificationFilter"] = .caLayerContentsFilter
        types["maskedCorners"] = .caCornerMask
        // Explicitly disabled properties
        for name in [
            "bounds",
            "frame",
        ] {
            types[name] = .unavailable("Use top/left/width/height instead")
            let name = "\(name)."
            for key in types.keys where key.hasPrefix(name) {
                types[key] = .unavailable("Use top/left/width/height instead")
            }
        }
        for name in [
            "needsDisplayInRect",
        ] {
            types[name] = .unavailable()
            for key in types.keys where key.hasPrefix(name) {
                types[key] = .unavailable()
            }
        }
        for name in [
            "position",
        ] {
            types[name] = .unavailable("Use center.x or center.y instead")
            for key in types.keys where key.hasPrefix(name) {
                types[key] = .unavailable("Use center.x or center.y instead")
            }
        }

        #if arch(i386) || arch(x86_64)
            // Private properties
            for name in [
                "acceleratesDrawing",
                "allowsContentsRectCornerMasking",
                "allowsDisplayCompositing",
                "allowsGroupBlending",
                "allowsHitTesting",
                "backgroundColorPhase",
                "behaviors",
                "canDrawConcurrently",
                "clearsContext",
                "coefficientOfRestitution",
                "contentsContainsSubtitles",
                "contentsDither",
                "contentsMultiplyByColor",
                "contentsOpaque",
                "contentsScaling",
                "contentsSwizzle",
                "continuousCorners",
                "cornerContentsCenter",
                "cornerContentsMasksEdges",
                "definesDisplayRegionOfInterest",
                "disableUpdateMask",
                "doubleBounds",
                "doublePosition",
                "flipsHorizontalAxis",
                "hitTestsAsOpaque",
                "hitTestsContentsAlphaChannel",
                "inheritsTiming",
                "invertsShadow",
                "isFlipped",
                "isFrozen",
                "literalContentsCenter",
                "mass",
                "meshTransform",
                "momentOfInertia",
                "motionBlurAmount",
                "needsLayoutOnGeometryChange",
                "perspectiveDistance",
                "preloadsCache",
                "presentationModifiers",
                "rasterizationPrefersDisplayCompositing",
                "sizeRequisition",
                "sortsSublayers",
                "stateTransitions",
                "states",
                "velocityStretch",
                "wantsExtendedDynamicRangeContent",
            ] {
                types[name] = nil
                for key in types.keys where key.hasPrefix(name) {
                    types[key] = nil
                }
            }
        #endif
        return types
    }
}
