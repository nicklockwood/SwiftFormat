//  Copyright © 2017 Schibsted. All rights reserved.

import Foundation

extension LayoutNode {
    /// Create a new LayoutNode instance from a Layout template
    convenience init(
        layout: Layout,
        outlet: String? = nil,
        state: Any = (),
        constants: [String: Any]...
    ) throws {
        try self.init(
            layout: layout,
            outlet: outlet,
            state: state,
            constants: merge(constants),
            isRoot: true
        )
    }

    private convenience init(
        layout: Layout,
        outlet: String? = nil,
        state: Any = (),
        constants: [String: Any] = [:],
        isRoot: Bool
    ) throws {
        do {
            if let path = layout.templatePath {
                throw LayoutError("Cannot initialize \(layout.className) node until content for \(path) has been loaded")
            }
            let _class: AnyClass = try layout.getClass()
            var expressions = layout.expressions
            if let body = layout.body {
                guard case let bodyExpression?? = _class.bodyExpression else {
                    throw LayoutError("\(layout.className) does not support inline (X)HTML content")
                }
                expressions[bodyExpression] = body
            }
            if let outlet = outlet {
                expressions["outlet"] = outlet
            }
            try self.init(
                class: _class,
                id: layout.id,
                state: state,
                constants: constants,
                expressions: expressions,
                children: layout.children.map {
                    try LayoutNode(layout: $0, isRoot: false)
                }
            )
            _parameters = layout.parameters
            _macros = layout.macros
            rootURL = layout.rootURL
            guard let xmlPath = layout.xmlPath else {
                return
            }
            var deferredError: Error?
            LayoutLoader().loadLayout(
                withContentsOfURL: urlFromString(xmlPath, relativeTo: rootURL),
                relativeTo: layout.relativePath
            ) { [weak self] layout, error in
                if let layout = layout {
                    do {
                        try self?.update(with: layout)
                    } catch {
                        deferredError = error
                    }
                } else if let error = error {
                    deferredError = error
                }
            }
            // TODO: what about errors thrown by deferred load?
            if let error = deferredError {
                throw error
            }
        } catch {
            throw LayoutError(error, in: layout.className, in: isRoot ? layout.rootURL : nil)
        }
    }
}

extension Layout {
    // Experimental - extracts a layout template from an existing node
    // TODO: this isn't a lossless conversion - find a better approach
    init(_ node: LayoutNode) {
        self.init(
            className: nameOfClass(node._class),
            id: node.id,
            expressions: node._originalExpressions,
            parameters: node._parameters,
            macros: node._macros,
            children: node.children.map(Layout.init(_:)),
            body: nil,
            xmlPath: nil, // TODO: what if the layout is currently loading this? Race condition!
            templatePath: nil,
            childrenTagIndex: nil,
            relativePath: nil,
            rootURL: node.rootURL
        )
    }
}
