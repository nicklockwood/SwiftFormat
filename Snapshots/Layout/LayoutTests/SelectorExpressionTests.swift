//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private final class TestView: UIView {
    @objc var action: Selector?
}

private final class TestViewController: UIViewController {
    @objc func foo(_: UIView) {
        print("It works!")
    }
}

final class SelectorExpressionTests: XCTestCase {
    func testSetControlAction() throws {
        let node = LayoutNode(view: UIControl(), expressions: ["touchUpInside": "foo:"])
        let viewController = TestViewController()
        XCTAssertNoThrow(try node.mount(in: viewController))
        let control = try XCTUnwrap(node.view as? UIControl)
        XCTAssertEqual(control.actions(forTarget: viewController, forControlEvent: .touchUpInside)?.first, "foo:")
    }

    func testSetCustomSelector() {
        let node = LayoutNode(view: TestView(), expressions: ["action": "foo:"])
        node.update()
        XCTAssertNotNil(node.view.action)
    }
}
