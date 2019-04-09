//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

private class TestView: UIView, LayoutLoading {}
private class TestViewController: UIViewController, LayoutLoading {
    @IBOutlet var outlet: UIView?
}

class LayoutMountingTests: XCTestCase {
    // MARK: mounting view in view controller

    func testMountUnitializedViewNodeInInitializedViewController() throws {
        let node = LayoutNode()
        let vc = UIViewController()
        _ = vc.view // Initialize VC
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountUnitializedViewNodeInUninitializedViewController() throws {
        let node = LayoutNode()
        let vc = UIViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountInitializedViewNodeInUninitializedViewController() throws {
        let node = LayoutNode()
        _ = node.view // Initialize node
        let vc = UIViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountInitializedViewNodeInInitializedViewController() throws {
        let node = LayoutNode()
        _ = node.view // Initialize node
        let vc = UIViewController()
        _ = vc.view // Initialize VC
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    // MARK: mounting view in view

    func testMountViewNodeInViewOfSameType() throws {
        let node = LayoutNode(view: UIView.self)
        let view = UIView()
        try node.mount(in: view)
        XCTAssertNotEqual(view, node.view)
    }

    func testMountLayoutLoadingViewNodeInViewOfSameType() throws {
        let node = LayoutNode(view: TestView.self)
        let view = TestView()
        XCTAssertThrowsError(try node.mount(in: view)) { error in
            XCTAssert("\(error)".contains(NSStringFromClass(TestView.self)))
        }
    }

    // MARK: mounting view controller in view controller

    func testMountUninitializedViewControllerNodeInUninitializedViewController() throws {
        let node = LayoutNode(viewController: UIViewController.self)
        let vc = UIViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountViewControllerNodeInViewControllerOfSameType() throws {
        let node = LayoutNode(viewController: UIViewController.self)
        let vc = UIViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(node.viewController, vc)
        XCTAssertNotEqual(node.view, vc.view)
    }

    func testMountLayoutLoadingViewControllerNodeInViewControllerOfSameType() throws {
        let node = LayoutNode(viewController: TestViewController.self)
        let vc = TestViewController()
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains(NSStringFromClass(TestViewController.self)))
        }
    }

    // MARK: UITableViewController

    func testMountUninitializedViewInUninitializedTableViewController() throws {
        let node = LayoutNode(view: UIView.self)
        let vc = UITableViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountInitializedViewInUninitializedTableViewController() throws {
        let node = LayoutNode(view: UIView.self)
        _ = node.view // Initialize node
        let vc = UITableViewController()
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountInitializedViewInInitializedTableViewController() throws {
        let node = LayoutNode(view: UIView.self)
        _ = node.view // Initialize node
        let vc = UITableViewController()
        _ = vc.view // Initialize VC
        try node.mount(in: vc)
        XCTAssertNotEqual(vc.view, node.view)
    }

    func testMountUninitializedUITableViewInUninitializedTableViewController() {
        let node = LayoutNode(view: UITableView.self)
        let vc = UITableViewController()
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("UITableView"))
        }
    }

    func testMountInitializedUITableViewInUninitializedTableViewController() {
        let node = LayoutNode(view: UITableView.self)
        _ = node.view // Initialize node
        let vc = UITableViewController()
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("UITableView"))
        }
    }

    func testMountUninitializedUITableViewInInitializedTableViewController() {
        let node = LayoutNode(view: UITableView.self)
        let vc = UITableViewController()
        _ = vc.view // Initialize VC
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("UITableView"))
        }
    }

    func testMountInitializedUITableViewInInitializedTableViewController() {
        let node = LayoutNode(view: UITableView.self)
        _ = node.view // Initialize node
        let vc = UITableViewController()
        _ = vc.view // Initialize VC
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("UITableView"))
        }
    }

    // MARK: Duplicate views and outlets

    func testDuplicateOutletError() {
        let node = LayoutNode(children: [
            LayoutNode(outlet: "outlet"),
            LayoutNode(outlet: "outlet"),
        ])
        let vc = TestViewController()
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("outlet"))
        }
    }

    func testDuplicateViewError() {
        let view = UIView()
        let node = LayoutNode(children: [
            LayoutNode(view: view),
            LayoutNode(view: view),
        ])
        let vc = TestViewController()
        XCTAssertThrowsError(try node.mount(in: vc)) { error in
            XCTAssert("\(error)".contains("UIView"))
        }
    }
}
