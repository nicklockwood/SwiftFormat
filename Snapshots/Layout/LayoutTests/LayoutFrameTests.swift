//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class LayoutFrameTests: XCTestCase {
    // MARK: Frame/view consistency

    func testLayoutFrameMatchesView() {
        let frame = CGRect(x: 100, y: 50, width: 200, height: 300)
        let view = UIView(frame: frame)
        let node = LayoutNode(view: view)

        // Test unmounted view
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(node.frame, view.frame)

        // Test mounted view
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        try! node.mount(in: superview)
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(node.frame, view.frame)
    }

    func testLayoutFrameSizeMatchesView() {
        let view = UIView(frame: CGRect(x: 100, y: 50, width: 200, height: 300))
        let node = LayoutNode(view: view, expressions: ["left": "5", "top": "15"])
        let expectedFrame = CGRect(x: 5, y: 15, width: 200, height: 300)

        // Test unmounted view
        XCTAssertEqual(view.frame.size, expectedFrame.size)
        XCTAssertEqual(node.frame, expectedFrame)

        // Test mounted view
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        try! node.mount(in: superview)
        XCTAssertEqual(view.frame, expectedFrame)
        XCTAssertEqual(node.frame, view.frame)
    }

    func testLayoutFrameOriginMatchesView() {
        let view = UIView(frame: CGRect(x: 100, y: 50, width: 200, height: 300))
        let node = LayoutNode(view: view, expressions: ["width": "5", "height": "15"])
        let expectedFrame = CGRect(x: 100, y: 50, width: 5, height: 15)

        // Test unmounted view
        XCTAssertEqual(view.frame.origin, expectedFrame.origin)
        XCTAssertEqual(node.frame, expectedFrame)

        // Test mounted view
        let superview = UIView()
        try! node.mount(in: superview)
        XCTAssertEqual(view.frame, expectedFrame)
        XCTAssertEqual(node.frame, view.frame)
    }

    func testLayoutFrameTracksView() {
        var frame = CGRect(x: 100, y: 50, width: 200, height: 300)
        let view = UIView(frame: frame)
        let node = LayoutNode(view: view)
        let superview = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        superview.addSubview(view)

        // Test initial frame
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(node.frame, view.frame)

        // Test updated frame
        frame = CGRect(x: 20, y: 15, width: 150, height: 400)
        view.frame = frame
        XCTAssertEqual(view.frame, frame)
        XCTAssertEqual(node.frame, view.frame)
    }

    // MARK: Auto-sizing

    func testAutoSizeParentToFitChildren() {
        let node = LayoutNode(
            expressions: [
                "width": "auto",
                "height": "auto",
            ],
            children: [
                LayoutNode(
                    expressions: [
                        "width": "100",
                        "height": "20",
                    ]
                ),
                LayoutNode(
                    expressions: [
                        "top": "previous.bottom + 10",
                        "width": "150",
                        "height": "20",
                    ]
                ),
            ]
        )
        XCTAssertEqual(node.frame.size, CGSize(width: 150, height: 50))
    }

    func testAutosizeParentHeightToFitChildren() {
        let node = LayoutNode(
            expressions: [
                "width": "auto",
                "height": "10",
            ],
            children: [
                LayoutNode(
                    expressions: [
                        "width": "100",
                        "height": "20",
                    ]
                ),
                LayoutNode(
                    expressions: [
                        "top": "previous.bottom + 10",
                        "width": "150",
                        "height": "20",
                    ]
                ),
            ]
        )
        XCTAssertEqual(node.frame.size, CGSize(width: 150, height: 10))
    }

    func testAutosizeParentWidthToFitChildren() {
        let node = LayoutNode(
            expressions: [
                "width": "50",
                "height": "auto",
            ],
            children: [
                LayoutNode(
                    expressions: [
                        "width": "100",
                        "height": "20",
                    ]
                ),
                LayoutNode(
                    expressions: [
                        "top": "previous.bottom + 10",
                        "width": "150",
                        "height": "20",
                    ]
                ),
            ]
        )
        XCTAssertEqual(node.frame.size, CGSize(width: 50, height: 50))
    }

    func testAutosizeParentWhenChildHasPercentageWidth() {
        let node = LayoutNode(
            expressions: [
                "width": "auto",
                "height": "auto",
            ],
            children: [
                LayoutNode(
                    expressions: [
                        "width": "50%",
                        "height": "20",
                    ]
                ),
                LayoutNode(
                    expressions: [
                        "top": "previous.bottom + 10",
                        "width": "150",
                        "height": "20",
                    ]
                ),
            ]
        )
        node.update()
        XCTAssertEqual(node.frame.size, CGSize(width: 150, height: 50))
        XCTAssertEqual(node.children[0].frame.size, CGSize(width: 75, height: 20))
    }

    func testAutosizeParentWhenChildHasAutoWidth() {
        let node = LayoutNode(
            expressions: [
                "width": "auto",
                "height": "auto",
            ],
            children: [
                LayoutNode(
                    expressions: [
                        "width": "auto",
                        "height": "20",
                    ]
                ),
                LayoutNode(
                    expressions: [
                        "top": "previous.bottom + 10",
                        "width": "150",
                        "height": "20",
                    ]
                ),
            ]
        )
        node.update()
        XCTAssertEqual(node.frame.size, CGSize(width: 150, height: 50))
        XCTAssertEqual(node.children[0].frame.size, CGSize(width: 150, height: 20))
    }

    func testAutosizeImage() {
        let size = CGSize(width: 100, height: 200)
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 35, height: 500)
        let node = LayoutNode(view: imageView)
        node.update()
        XCTAssertEqual(node.frame.size, size)
        XCTAssertEqual(imageView.frame.size, size)
    }

    func testAutosizeText() {
        let text = "This is a line long enough to wrap"
        var node = LayoutNode(
            view: UILabel(),
            expressions: [
                "text": text,
                "numberOfLines": "0",
            ]
        )
        node.update()
        XCTAssertTrue(node.frame.width > 100)
        XCTAssertTrue(node.frame.height < 30)
        XCTAssertEqual(node.frame, node.view.frame)
        node = LayoutNode(
            view: UILabel(),
            expressions: [
                "text": text,
                "width": "50",
                "numberOfLines": "0",
            ]
        )
        node.update()
        XCTAssertTrue(node.frame.width <= 50)
        XCTAssertTrue(node.frame.height > 20)
        XCTAssertEqual(node.frame, node.view.frame)
    }

    func testAutosizeCollapsing() throws {
        let label = UILabel()
        let node = LayoutNode(
            state: ["text": "foobar"],
            expressions: ["width": "100", "height": "auto"],
            children: [
                LayoutNode(
                    view: label,
                    expressions: ["text": "{text}"]
                ),
            ]
        )
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        try node.mount(in: container)
        XCTAssert(node.frame.height > 15)
        XCTAssertEqual(node.frame.height, label.frame.height)
        node.setState(["text": ""])
        XCTAssertEqual(node.frame.height, 0)
    }

    // MARK: AutoLayout

    func testAutosizeTextUsingConstraints() {
        let text = "This is a line long enough to wrap"
        var node = LayoutNode(
            view: UILabel(),
            expressions: [
                "translatesAutoresizingMaskIntoConstraints": "false",
                "text": text,
                "numberOfLines": "0",
            ]
        )
        node.update()
        XCTAssertTrue(node.frame.width > 100)
        XCTAssertTrue(node.frame.height < 30)
        XCTAssertEqual(node.frame.size, node.view.systemLayoutSizeFitting(.zero))
        node = LayoutNode(
            view: UILabel(),
            expressions: [
                "translatesAutoresizingMaskIntoConstraints": "false",
                "text": text,
                "width": "50",
                "numberOfLines": "0",
            ]
        )
        node.update()
        XCTAssertTrue(node.frame.width <= 50)
        XCTAssertTrue(node.frame.height > 20)
        XCTAssertEqual(node.frame.size, node.view.systemLayoutSizeFitting(.zero))
    }

    // MARK: Center

    func testCenterPositioning() {
        let child = LayoutNode(expressions: [
            "width": "50%",
            "height": "50%",
            "center.x": "50%",
            "center.y": "25%",
        ])
        let parent = LayoutNode(expressions: [
            "width": "100",
            "height": "100",
        ], children: [child])
        parent.update()
        XCTAssertEqual(child.frame.origin.x, 25)
        XCTAssertEqual(child.frame.origin.y, 0)
    }

    func testCenterPositioningWithCustomAnchor() {
        let child = LayoutNode(expressions: [
            "width": "50%",
            "height": "50%",
            "center.x": "50%",
            "center.y": "25%",
            "layer.anchorPoint.x": "0",
            "layer.anchorPoint.y": "1",
        ])
        let parent = LayoutNode(expressions: [
            "width": "100",
            "height": "100",
        ], children: [child])
        parent.update()
        XCTAssertEqual(child.frame.origin.x, 50)
        XCTAssertEqual(child.frame.origin.y, -25)
    }

    // MARK: Redundant expressions

    func testRedundantRightPosition() {
        let node = LayoutNode(expressions: [
            "width": "100",
            "height": "100",
            "left": "0",
            "right": "100",
        ])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssert((errors.first.map { "\($0)" } ?? "").contains("right is redundant"))
    }

    func testNonRedundantRightPosition() {
        let node = LayoutNode(expressions: [
            "height": "100",
            "left": "0",
            "right": "100",
        ])
        let errors = node.validate()
        XCTAssert(errors.isEmpty)
    }

    func testRedundantCenterPosition() {
        let node = LayoutNode(expressions: [
            "width": "100",
            "height": "100",
            "left": "50% - width / 2",
            "center.x": "50%",
        ])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssert((errors.first.map { "\($0)" } ?? "").contains("center.x is redundant"))
    }

    func testRedundantLeadingPosition() {
        let node = LayoutNode(expressions: [
            "width": "100",
            "height": "100",
            "left": "0",
            "leading": "0",
        ])
        let errors = node.validate()
        XCTAssertEqual(errors.count, 1)
        XCTAssert((errors.first.map { "\($0)" } ?? "").contains("leading is redundant"))
    }

    func testNonRedundantLeadingPosition() {
        let node = LayoutNode(expressions: [
            "height": "100",
            "trailing": "0",
            "leading": "0",
        ])
        let errors = node.validate()
        XCTAssert(errors.isEmpty)
    }
}
