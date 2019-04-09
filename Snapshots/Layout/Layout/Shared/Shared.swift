//  Copyright © 2017 Schibsted. All rights reserved.

// Expressions that affect layout
// These are common to every Layout node
// These are all of type CGFloat, apart from `center` which is a CGPoint
let layoutSymbols: Set<String> = [
    "left", "right", "leading", "trailing",
    "width", "top", "bottom", "height", "center",
    "center.x", "center.y", "firstBaseline", "lastBaseline",
]

// HTML tags that should not contain children
// http://w3c.github.io/html/syntax.html#void-elements
let emptyHTMLTags: Set<String> = [
    "area", "base", "br", "col", "embed", "hr",
    "img", "input", "link", "meta", "param",
    "source", "track", "wbr",
]
