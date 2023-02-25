//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private func url(forXml name: String) throws -> URL {
    guard let url = Bundle(for: LayoutViewControllerTests.self)
        .url(forResource: name, withExtension: "xml")
    else {
        throw NSError(domain: "Could not locate: \(name).xml", code: 0)
    }
    return url
}

class LayoutViewControllerTests: XCTestCase {
    /// Test class which overrides layoutDidLoad(_:)
    private class TestLayoutViewController: UIViewController, LayoutLoading {
        var layoutDidLoadLayoutNode: LayoutNode?
        var layoutDidLoadLayoutNodeCallCount = 0

        func layoutDidLoad(_ layoutNode: LayoutNode) {
            layoutDidLoadLayoutNodeCallCount += 1
            layoutDidLoadLayoutNode = layoutNode
        }
    }

    func testLayoutDidLoadWithValidXML() throws {
        let viewController = TestLayoutViewController()
        try viewController.loadLayout(withContentsOfURL: url(forXml: "LayoutDidLoad_Valid"))

        XCTAssertNotNil(viewController.layoutDidLoadLayoutNode)
        XCTAssertEqual(viewController.layoutNode, viewController.layoutDidLoadLayoutNode)
        XCTAssertEqual(viewController.layoutDidLoadLayoutNodeCallCount, 1)
    }

    func testLayoutDidLoadWithInvalidXML() throws {
        let viewController = TestLayoutViewController()
        try viewController.loadLayout(withContentsOfURL: url(forXml: "LayoutDidLoad_Invalid"))

        XCTAssertNil(viewController.layoutDidLoadLayoutNode)
        XCTAssertEqual(viewController.layoutDidLoadLayoutNodeCallCount, 0)
    }

    func testLoadedLayoutDoesNotRetainItself() throws {
        weak var controller: TestLayoutViewController?
        weak var view: UIView?
        weak var node: LayoutNode?
        try autoreleasepool {
            let vc = TestLayoutViewController()
            try vc.loadLayout(withContentsOfURL: url(forXml: "LayoutDidLoad_Valid"))
            node = vc.layoutNode
            XCTAssertNotNil(node)
            view = node?.view
            XCTAssertNotNil(view)
            controller = vc
        }
        XCTAssertNil(controller)
        XCTAssertNil(view)
        XCTAssertNil(node)
    }
}
