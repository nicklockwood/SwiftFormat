//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private class TestView: UIView {
    var wasUpdated = false
    @objc var testProperty = "" {
        didSet {
            wasUpdated = true
        }
    }
}

private class TestViewController: UIViewController {
    var labelWasSet = false
    @objc weak var label: UILabel? {
        didSet {
            labelWasSet = true
        }
    }
}

class LayoutNodeTests: XCTestCase {
    // MARK: Expression errors

    func testInvalidExpression() {
        let node = LayoutNode(expressions: ["foobar": "5"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("Unknown property") == true)
        XCTAssertTrue(errors.first?.description.contains("foobar") == true)
    }

    func testReadOnlyExpression() {
        let node = LayoutNode(expressions: ["safeAreaInsets.top": "5"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("read-only") == true)
        XCTAssertTrue(errors.first?.description.contains("safeAreaInsets.top") == true)
    }

    func testCircularReference() {
        let node = LayoutNode(expressions: ["top": "top"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("reference") == true)
        XCTAssertTrue(errors.first?.description.contains("top") == true)
    }

    func testMutualReferences() {
        let node = LayoutNode(expressions: ["top": "bottom", "bottom": "top"])
        let errors = node.validate()
        XCTAssertGreaterThanOrEqual(errors.count, 2)
        for error in errors {
            let description = error.description
            XCTAssertTrue(description.contains("reference"))
            XCTAssertTrue(description.contains("top") || description.contains("bottom"))
        }
    }

    func testCircularMacroReference() {
        let xmlData = "<UIView><macro name=\"foo\" value=\"foo\"/><UILabel text=\"{foo}\"/></UIView>".data(using: .utf8)!
        let node = try! LayoutNode(xmlData: xmlData)
        let errors = node.validate()
        XCTAssertGreaterThanOrEqual(errors.count, 1)
        for error in errors {
            let description = error.description
            XCTAssertTrue(description.contains("reference"))
            XCTAssertTrue(description.contains("foo"))
        }
    }

    func testMutualMacroReferences() {
        let xmlData = "<UIView><macro name=\"foo\" value=\"bar\"/><macro name=\"bar\" value=\"foo\"/><UILabel text=\"{foo}\"/></UIView>".data(using: .utf8)!
        let node = try! LayoutNode(xmlData: xmlData)
        let errors = node.validate()
        XCTAssertGreaterThanOrEqual(errors.count, 1)
        for error in errors {
            let description = error.description
            XCTAssertTrue(description.contains("reference"))
            XCTAssertTrue(description.contains("foo") || description.contains("bar"))
        }
    }

    func testCircularReference3() {
        UIGraphicsBeginImageContext(CGSize(width: 20, height: 10))
        let node = LayoutNode(
            expressions: [
                "height": "auto",
                "width": "100%",
            ],
            children: [
                LayoutNode(
                    view: UIImageView(image: UIGraphicsGetImageFromCurrentImageContext()),
                    expressions: [
                        "width": "max(auto, height)",
                        "height": "max(auto, width)",
                    ]
                ),
            ]
        )
        UIGraphicsEndImageContext()
        let errors = node.validate()
        XCTAssertGreaterThanOrEqual(errors.count, 2)
        for error in errors {
            let description = error.description
            XCTAssertTrue(description.contains("reference"))
            XCTAssertTrue(description.contains("width") || description.contains("height"))
        }
    }

    // MARK: Invalid node errors

    func testUnknownClass() {
        let layout = try! Layout(xmlData: "<Foo/>".data(using: .utf8)!)
        XCTAssertThrowsError(try LayoutNode(layout: layout)) { error in
            XCTAssert("\(error)".contains("Unknown class Foo"))
        }
    }

    func testInvalidClass() {
        let layout = try! Layout(xmlData: "<NSObject/>".data(using: .utf8)!)
        XCTAssertThrowsError(try LayoutNode(layout: layout)) { error in
            XCTAssert("\(error)".contains("NSObject is not a subclass of UIView"))
        }
    }

    // MARK: Animated setter

    func testSetSwitchStateAnimated() {
        let view = UISwitch()
        let node = LayoutNode(view: view, state: ["onState": false], expressions: ["isOn": "onState"])
        XCTAssertFalse(view.isOn)
        node.setState(["onState": true], animated: true)
        XCTAssertTrue(view.isOn)
    }

    func testScrollViewZoomScaleAnimated() {
        let view = UIScrollView()
        let node = LayoutNode(view: view, state: ["zoom": 1], expressions: [
            "zoomScale": "zoom",
        ])
        node.setState(["zoom": 2], animated: true)
    }

    func testScrollViewContentOffsetAnimated() {
        let view = UIScrollView()
        let node = LayoutNode(view: view, state: ["offset": CGPoint.zero], expressions: [
            "contentOffset": "offset",
            "contentSize.height": "100",
        ])
        let expected = CGPoint(x: 0, y: 15)
        XCTAssertEqual(view.contentOffset, .zero)
        node.setState(["offset": expected], animated: true)
        XCTAssertEqual(view.contentOffset, expected)
    }

    // MARK: Property errors

    func testNonexistentViewProperty() {
        let node = LayoutNode(view: UIView(), expressions: ["width": "5 + layer.foobar"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("Unknown property") == true)
        XCTAssertTrue(errors.first?.description.contains("foobar") == true)
    }

    func testNestedNonexistentViewProperty() {
        let node = LayoutNode(view: UIView(), expressions: ["width": "5 + layer.foo.bar"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("Unknown property") == true)
        XCTAssertTrue(errors.first?.description.contains("foo.bar") == true)
    }

    func testNonexistentRectViewProperty() {
        let node = LayoutNode(view: UIView(), expressions: ["width": "5 + frame.foo.bar"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first?.description.contains("Unknown property") == true)
        XCTAssertTrue(errors.first?.description.contains("foo.bar") == true)
    }

    func testNilViewProperty() {
        let node = LayoutNode(view: UIView(), expressions: ["width": "layer.contents == nil ? 5 : 10"])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 0)
        node.update()
        XCTAssertNil(node.view.layer.contents)
        XCTAssertEqual(node.view.frame.width, 5)
    }

    // MARK: State/constant/parameter shadowing

    func testExpressionShadowsConstant() {
        let node = LayoutNode(constants: ["top": 10], expressions: ["top": "top"])
        let errors = node.validate()
        XCTAssertTrue(errors.isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "top"), 10)
    }

    func testExpressionShadowsVariable() {
        let node = LayoutNode(state: ["top": 10], expressions: ["top": "top"])
        let errors = node.validate()
        XCTAssertTrue(errors.isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "top"), 10)
    }

    func testStateShadowsConstant() {
        let node = LayoutNode(state: ["foo": 10], constants: ["foo": 5], expressions: ["top": "foo"])
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "foo"), 10)
        XCTAssertEqual(try node.doubleValue(forSymbol: "top"), 10)
    }

    func testConstantShadowsViewProperty() {
        let view = UIView()
        view.tag = 10
        let node = LayoutNode(view: view, constants: ["tag": 5])
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "tag"), 5)
    }

    func testStateShadowsInheritedConstant() {
        let child = LayoutNode(state: ["foo": 10], expressions: ["top": "foo"])
        let parent = LayoutNode(constants: ["foo": 5], children: [child])
        XCTAssertTrue(parent.validate().isEmpty)
        XCTAssertEqual(try child.doubleValue(forSymbol: "foo"), 10)
        XCTAssertEqual(try child.doubleValue(forSymbol: "top"), 10)
    }

    func testConstantShadowsInheritedState() {
        let child = LayoutNode(constants: ["foo": 10], expressions: ["top": "foo"])
        let parent = LayoutNode(state: ["foo": 5], children: [child])
        XCTAssertTrue(parent.validate().isEmpty)
        XCTAssertEqual(try child.doubleValue(forSymbol: "foo"), 10)
        XCTAssertEqual(try child.doubleValue(forSymbol: "top"), 10)
    }

    func testParameterNameShadowsState() {
        let xmlData = "<UILabel text=\"{name}\" name=\"{name}\"><param name=\"name\" type=\"String\"/></UILabel>".data(using: .utf8)!
        let node = try! LayoutNode(xmlData: xmlData)
        node.setState(["name": "Foo"])
        node.update()
        XCTAssertEqual((node.view as! UILabel).text, "Foo")
    }

    func testMacroNameShadowsState() {
        let xmlData = "<UIView name=\"{foo}\"><macro name=\"name\" value=\"name\"/><UILabel text=\"{name}\"/></UIView>".data(using: .utf8)!
        let node = try! LayoutNode(xmlData: xmlData)
        node.setState(["name": "Foo"])
        node.update()
        XCTAssertEqual((node.view.subviews[0] as! UILabel).text, "Foo")
    }

    func testMacroNameShadowsConstant() {
        let xmlData = "<UIView><macro name=\"foo\" value=\"foo + 'baz'\"/><UILabel text=\"{foo}\"/></UIView>".data(using: .utf8)!
        let node = try! LayoutNode(xmlData: xmlData)
        node.constants = ["foo": "bar"]
        let errors = node.validate()
        XCTAssert(errors.isEmpty)
        let label = node.children[0]
        XCTAssertEqual(try label.value(forSymbol: "text") as? String, "barbaz")
        XCTAssertEqual(try label.constantValue(forSymbol: "text") as? String, "barbaz")
    }

    // MARK: update(with:)

    func testUpdateViewWithSameClass() {
        let node = LayoutNode(view: UIView())
        let oldView = node.view
        XCTAssertTrue(oldView.classForCoder == UIView.self)
        let layout = Layout(node)
        try! node.update(with: layout)
        XCTAssertTrue(oldView === node.view)
    }

    func testUpdateViewWithSubclass() {
        let node = LayoutNode(view: UIView())
        XCTAssertTrue(node.view.classForCoder == UIView.self)
        let layout = Layout(LayoutNode(view: UILabel()))
        try! node.update(with: layout)
        XCTAssertTrue(node.view.classForCoder == UILabel.self)
    }

    func testUpdateViewWithSuperclass() {
        let node = LayoutNode(view: UILabel())
        let layout = Layout(LayoutNode(view: UIView()))
        XCTAssertThrowsError(try node.update(with: layout))
    }

    func testUpdateViewControllerWithSameClass() {
        let node = LayoutNode(viewController: UIViewController())
        let oldViewController = node.viewController
        XCTAssertTrue(oldViewController?.classForCoder == UIViewController.self)
        let layout = Layout(node)
        try! node.update(with: layout)
        XCTAssertTrue(oldViewController === node.viewController)
    }

    func testUpdateViewControllerWithSubclass() {
        let node = LayoutNode(viewController: UIViewController())
        XCTAssertTrue(node.viewController?.classForCoder == UIViewController.self)
        let layout = Layout(LayoutNode(viewController: UITabBarController()))
        try! node.update(with: layout)
        XCTAssertTrue(node.viewController?.classForCoder == UITabBarController.self)
    }

    func testUpdateViewControllerWithSuperclass() {
        let node = LayoutNode(viewController: UITabBarController())
        let layout = Layout(LayoutNode(viewController: UIViewController()))
        XCTAssertThrowsError(try node.update(with: layout))
    }

    // MARK: value persistence

    func testLiteralValueNotReapplied() {
        let view = TestView()
        let node = LayoutNode(view: view, expressions: ["testProperty": "foo"])

        node.update()
        XCTAssertTrue(view.wasUpdated)
        XCTAssertEqual(view.testProperty, "foo")

        view.wasUpdated = false
        node.update()
        XCTAssertFalse(view.wasUpdated)

        view.testProperty = "bar"
        node.update()
        XCTAssertEqual(view.testProperty, "bar")
    }

    func testConstantValueNotReapplied() {
        let view = TestView()
        let node = LayoutNode(view: view, constants: ["foo": "foo"], expressions: ["testProperty": "{foo}"])

        node.update()
        XCTAssertTrue(view.wasUpdated)
        XCTAssertEqual(view.testProperty, "foo")

        view.wasUpdated = false
        node.update()
        XCTAssertFalse(view.wasUpdated)

        view.testProperty = "bar"
        node.update()
        XCTAssertEqual(view.testProperty, "bar")
    }

    func testUnchangedValueNotReapplied() {
        let view = TestView()
        let node = LayoutNode(view: view, state: ["text": "foo"], expressions: ["testProperty": "{text}"])

        node.update()
        XCTAssertTrue(view.wasUpdated)
        XCTAssertEqual(view.testProperty, "foo")

        view.wasUpdated = false
        node.update()
        XCTAssertFalse(view.wasUpdated)
    }

    // MARK: property evaluation order

    func testUpdateContentInsetWithTop() {
        let scrollView = UIScrollView()
        let node = LayoutNode(
            view: scrollView,
            state: [
                "inset": UIEdgeInsets(),
                "insetTop": 5,
            ],
            expressions: [
                "contentInset": "inset",
                "contentInset.top": "insetTop",
            ]
        )

        node.update()
        XCTAssertEqual(scrollView.contentInset.top, 5)
    }

    func testUpdateContentInsetWithConstantTop() {
        let scrollView = UIScrollView()
        let node = LayoutNode(
            view: scrollView,
            state: ["inset": UIEdgeInsets()],
            expressions: [
                "contentInset": "inset",
                "contentInset.top": "5",
            ]
        )

        node.update()
        XCTAssertEqual(scrollView.contentInset.top, 5)
    }

    // MARK: outlet expressions

    func testOutletBinding() {
        let node = LayoutNode(
            children: [
                LayoutNode(
                    view: UILabel(),
                    outlet: "label"
                ),
            ]
        )
        let viewController = TestViewController()
        XCTAssertNoThrow(try node.mount(in: viewController))
        XCTAssertTrue(viewController.labelWasSet)
    }

    func testOutletConstantBinding() {
        let node = LayoutNode(
            constants: [
                "label.outlet": "label",
            ],
            children: [
                LayoutNode(
                    view: UILabel(),
                    outlet: "{label.outlet}"
                ),
            ]
        )
        let viewController = TestViewController()
        XCTAssertNoThrow(try node.mount(in: viewController))
        XCTAssertTrue(viewController.labelWasSet)
    }

    func testOutletConstantExpressionBinding() {
        let node = LayoutNode(
            view: UILabel(),
            constants: [
                "label.outlet": "label",
            ],
            expressions: [
                "text": "{label.outlet}",
            ],
            children: [
                LayoutNode(
                    view: UILabel(),
                    outlet: "{parent.text}"
                ),
            ]
        )
        let viewController = TestViewController()
        XCTAssertNoThrow(try node.mount(in: viewController))
        XCTAssertTrue(viewController.labelWasSet)
    }

    func testOutletVariableBinding() {
        let node = LayoutNode(
            state: [
                "label.outlet": "label",
            ],
            children: [
                LayoutNode(
                    view: UILabel(),
                    outlet: "{label.outlet}"
                ),
            ]
        )
        let viewController = TestViewController()
        XCTAssertThrowsError(try node.mount(in: viewController)) { error in
            XCTAssert("\(error)".contains("must be a constant or literal value"))
        }
    }

    // MARK: node lookup

    func testFindChild() {
        let child = LayoutNode(id: "bar")
        let parent = LayoutNode(id: "foo", children: [child])
        XCTAssertEqual(parent.childNode(withID: "bar"), child)
        XCTAssertEqual(parent.children(withID: "bar"), [child])
        parent.update()
        XCTAssertEqual(parent.node(withID: "bar"), child)
    }

    func testFindChildren() {
        let child1 = LayoutNode(id: "bar")
        let child2 = LayoutNode(id: "bar")
        let parent = LayoutNode(id: "foo", children: [child1, child2])
        XCTAssertEqual(parent.childNode(withID: "bar"), child1)
        XCTAssertEqual(parent.children(withID: "bar"), [child1, child2])
        parent.update()
        XCTAssertEqual(parent.node(withID: "bar"), child1)
    }

    func testFindGrandchild() {
        let grandchild = LayoutNode(id: "baz")
        let child = LayoutNode(id: "bar", children: [grandchild])
        let parent = LayoutNode(id: "foo", children: [child])
        XCTAssertEqual(parent.childNode(withID: "baz"), grandchild)
        XCTAssertEqual(parent.children(withID: "baz"), [grandchild])
        parent.update()
        XCTAssertEqual(parent.node(withID: "baz"), grandchild)
    }

    func testFindSelf() {
        let node = LayoutNode(id: "foo")
        XCTAssertNil(node.childNode(withID: "foo"))
        XCTAssert(node.children(withID: "foo").isEmpty)
        node.update()
        XCTAssertEqual(node.node(withID: "foo"), node)
    }

    func testFindParent() {
        let child = LayoutNode(id: "bar")
        let parent = LayoutNode(id: "foo", children: [child])
        parent.update()
        XCTAssertNil(child.childNode(withID: "foo"))
        XCTAssert(child.children(withID: "foo").isEmpty)
        XCTAssertEqual(parent.children[0], child)
        XCTAssertEqual(child.node(withID: "foo"), parent)
    }

    func testFindGrandparent() {
        let grandchild = LayoutNode(id: "baz")
        let child = LayoutNode(id: "bar", children: [grandchild])
        let parent = LayoutNode(id: "foo", children: [child])
        parent.update()
        XCTAssertEqual(grandchild.node(withID: "foo"), parent)
    }

    func testFindSiblings() {
        let bar = LayoutNode(id: "bar")
        let baz = LayoutNode(id: "baz")
        let parent = LayoutNode(id: "foo", children: [bar, baz])
        parent.update()
        XCTAssertNil(bar.childNode(withID: "baz"))
        XCTAssert(bar.children(withID: "baz").isEmpty)
        XCTAssertEqual(bar.next, baz)
        XCTAssertNil(bar.previous)
        XCTAssertEqual(baz.previous, bar)
        XCTAssertNil(baz.next)
        XCTAssertEqual(parent.children[0], bar)
        XCTAssertEqual(parent.children[1], baz)
        XCTAssertEqual(bar.node(withID: "baz"), baz)
    }

    func testFindCousin() {
        let bar = LayoutNode(id: "bar")
        let baz = LayoutNode(id: "baz")
        let parent = LayoutNode(id: "foo", children: [
            LayoutNode(children: [bar]),
            LayoutNode(children: [baz]),
        ])
        parent.update()
        XCTAssertEqual(bar.node(withID: "baz"), baz)
    }

    func testFindNonexistentNode() {
        let child = LayoutNode()
        let parent = LayoutNode(id: "foo", children: [child])
        XCTAssertNil(parent.childNode(withID: "bar"))
        XCTAssert(parent.children(withID: "bar").isEmpty)
        parent.update()
        XCTAssertNil(parent.node(withID: "bar"))
    }

    // MARK: memory leaks

    func testLayoutNodeDoesNotRetainItself() throws {
        weak var controller: UIViewController?
        weak var view: UIView?
        weak var node: LayoutNode?
        try autoreleasepool {
            let vc = UIViewController()
            controller = vc
            let _node = LayoutNode(view: UIView.self)
            node = _node
            view = _node.view
            XCTAssertNotNil(view)
            try _node.mount(in: vc)
        }
        XCTAssertNil(controller)
        XCTAssertNil(view)
        XCTAssertNil(node)
    }

    func testLayoutTreeDoesNotContainCycles() throws {
        weak var root: LayoutNode?
        weak var child: LayoutNode?
        try autoreleasepool {
            let vc = UIViewController()
            let _node = LayoutNode(view: UIView.self, children: [
                LayoutNode(view: UILabel.self, expressions: [
                    "attributedText": "Hello World",
                ]),
            ])
            root = _node
            child = _node.children.first
            try _node.mount(in: vc)
        }
        XCTAssertNil(root)
        XCTAssertNil(child)
    }

    func testLayoutWhereChildReferencesParentIsReleased() {
        let child = LayoutNode(id: "bar", expressions: [
            "backgroundColor": "parent.backgroundColor",
            "contentMode": "#foo.contentMode",
        ])
        var strongParent: LayoutNode? = LayoutNode(id: "foo", children: [child])
        weak var parent: LayoutNode? = strongParent
        parent?.update()
        strongParent = nil
        XCTAssertNil(parent)
    }

    func testLayoutNodeWithSelfReferencingExpressionIsReleased() {
        weak var node: LayoutNode?
        do {
            let strongNode = LayoutNode(
                view: UIView(),
                expressions: [
                    "top": "safeAreaInsets.top",
                ]
            )
            strongNode.update()
            node = strongNode
        }
        XCTAssertNil(node)
    }

    // MARK: empty expressions

    func testHasExpression() {
        let node = LayoutNode(expressions: ["backgroundColor": "red"])
        XCTAssertTrue(node.hasExpression("backgroundColor"))
    }

    func testDoesntHaveExpression() {
        let node = LayoutNode(expressions: ["backgroundColor": "//red"])
        XCTAssertFalse(node.hasExpression("backgroundColor"))
    }

    func testDoesntHaveDefaultExpression() {
        let node = LayoutNode(expressions: ["width": "//5", "left": "4", "right": "6"])
        XCTAssertFalse(node.hasExpression("width"))
        XCTAssertEqual(try node.doubleValue(forSymbol: "width"), 2.0)
    }
}
