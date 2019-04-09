//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

func autoLayoutViewOfSize(_ width: CGFloat, _ height: CGFloat) -> UIView {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: width).isActive = true
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
    return view
}

class StackViewTests: XCTestCase {
    func testFixedSizeElementsInAutoSizedStack() throws {
        let expectedSize = CGSize(width: 200, height: 150)

        do {
            // Check ordinary UIStackView
            let view = UIStackView(arrangedSubviews: [
                autoLayoutViewOfSize(200, 100),
                autoLayoutViewOfSize(200, 50),
            ])
            view.axis = .vertical
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layoutIfNeeded()
            XCTAssertEqual(view.frame.size, expectedSize)
        }

        do {
            // Check Layout-wrapped UIStackView
            let view = UIStackView(arrangedSubviews: [
                autoLayoutViewOfSize(200, 100),
                autoLayoutViewOfSize(200, 50),
            ])
            view.axis = .vertical
            let node = LayoutNode(view: view)
            node.update()
            XCTAssertEqual(node.frame.size, expectedSize)
            XCTAssertEqual(node.view.systemLayoutSizeFitting(.zero), expectedSize)
        }

        do {
            // Check Fully Layout-based UIStackView
            let node = try LayoutNode(
                class: UIStackView.self,
                expressions: ["axis": "vertical"],
                children: [
                    LayoutNode(expressions: ["width": "200", "height": "100"]),
                    LayoutNode(expressions: ["width": "200", "height": "50"]),
                ]
            )
            node.update()
            XCTAssertEqual(node.frame.size, expectedSize)
            XCTAssertEqual(node.view.frame.size, expectedSize)
        }
    }

    func testAutoSizeElementsInAutoSizedStack() throws {
        let label1 = try LayoutNode(
            class: UILabel.self,
            expressions: ["text": "Hello World"]
        )
        label1.update()
        let label1Size = label1.frame.size
        XCTAssert(label1Size != .zero)

        let label2 = try LayoutNode(
            class: UILabel.self,
            expressions: [
                "text": "Goodbye World",
                // Workaround for behavior change in iOS 11.2
                "contentCompressionResistancePriority.horizontal": "required",
            ]
        )
        label2.update()
        let label2Size = label2.frame.size
        XCTAssert(label2Size != .zero)

        do {
            // Check ordinary UIStackView
            let view = UIStackView(arrangedSubviews: [label1.view, label2.view])
            view.axis = .vertical
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layoutIfNeeded()
            XCTAssertEqual(label1.view.systemLayoutSizeFitting(.zero), label1Size)
            XCTAssertEqual(label2.view.systemLayoutSizeFitting(.zero), label2Size)
            XCTAssertEqual(view.systemLayoutSizeFitting(.zero), CGSize(
                width: max(label1Size.width, label2Size.width),
                height: label1Size.height + label2Size.height
            ))
        }

        do {
            // Check Layout-wrapped UIStackView
            let view = UIStackView(arrangedSubviews: [label1.view, label2.view])
            view.axis = .vertical
            let node = LayoutNode(view: view)
            node.update()
            XCTAssertEqual(label1.view.systemLayoutSizeFitting(.zero), label1Size)
            XCTAssertEqual(label2.view.systemLayoutSizeFitting(.zero), label2Size)
            XCTAssertEqual(node.frame.size, CGSize(
                width: max(label1Size.width, label2Size.width),
                height: label1Size.height + label2Size.height
            ))
            XCTAssertEqual(node.view.systemLayoutSizeFitting(.zero), node.frame.size)
        }

        do {
            // Check Fully Layout-based UIStackView
            let node = try LayoutNode(
                class: UIStackView.self,
                expressions: ["axis": "vertical"],
                children: [label1, label2]
            )
            node.update()
            XCTAssertEqual(label1.frame.size, label1Size)
            XCTAssertEqual(label2.frame.size, label2Size)
            XCTAssertEqual(node.frame.size, CGSize(
                width: max(label1Size.width, label2Size.width),
                height: label1Size.height + label2Size.height
            ))
            XCTAssertEqual(node.view.frame.size, node.frame.size)
        }
    }

    func testAutoSizeElementsInFixedWidthStack() throws {
        let label1 = try LayoutNode(
            class: UILabel.self,
            expressions: ["text": "Hello World"]
        )

        let label2 = try LayoutNode(
            class: UILabel.self,
            expressions: ["text": "Goodbye World"]
        )

        let node = try LayoutNode(
            class: UIStackView.self,
            expressions: ["width": "300", "axis": "vertical"],
            children: [label1, label2]
        )
        node.update()
        XCTAssertEqual(node.frame.width, 300)
        XCTAssert(node.frame.height > 10)
        XCTAssertEqual(node.view.frame.size, node.frame.size)
    }
}
