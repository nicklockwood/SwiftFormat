//  Copyright © 2017 Schibsted. All rights reserved.

import UIKit
import XCTest
@testable import Layout

class TableViewController: UIViewController, LayoutLoading, UITableViewDataSource, UITableViewDelegate {
    @objc var tableView: UITableView?
    var didLoadRows = false

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        loadLayout(named: "TableViewTest.xml", bundle: Bundle(for: type(of: self)))
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        didLoadRows = true
        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = tableView.dequeueReusableCellNode(withIdentifier: "testCell", for: indexPath)
        node.setState([])
        return node.view as! UITableViewCell
    }
}

class TableViewTests: XCTestCase {
    func testTableCellSizing() {
        let vc = TableViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: 512, height: 512)
        XCTAssertNotNil(vc.tableView)
        vc.tableView?.reloadData()
        XCTAssert(vc.didLoadRows)
        guard let cell = vc.tableView?.cellForRow(at: IndexPath(row: 0, section: 0)) else {
            XCTFail()
            return
        }
        XCTAssertEqual(cell.frame.width, 512)
        guard let cellLayoutView = cell.contentView.subviews.first else {
            XCTFail()
            return
        }
        XCTAssertNotNil(cellLayoutView._layoutNode)
        XCTAssertEqual(cellLayoutView.frame.width, 512)
        XCTAssertEqual(cellLayoutView.frame.origin.x, 0)
    }
}
