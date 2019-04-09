//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

extension CATransform3D: Equatable {
    public static func == (lhs: CATransform3D, rhs: CATransform3D) -> Bool {
        return CATransform3DEqualToTransform(lhs, rhs)
    }
}

class GeometryExpressionTests: XCTestCase {
    // MARK: CGPoint

    func testGetContentOffset() {
        let scrollView = UIScrollView()
        let node = LayoutNode(view: scrollView)
        XCTAssertEqual(try node.value(forSymbol: "contentOffset") as? CGPoint, scrollView.contentOffset)
    }

    func testGetContentOffsetX() {
        let scrollView = UIScrollView()
        let node = LayoutNode(view: scrollView)
        XCTAssertEqual(try node.doubleValue(forSymbol: "contentOffset.x"), Double(scrollView.contentOffset.x))
    }

    func testSetContentOffset() {
        let offset = CGPoint(x: 5, y: 10)
        let node = LayoutNode(
            view: UIScrollView(),
            state: ["offset": offset],
            expressions: ["contentOffset": "offset"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "offset") as? CGPoint, offset)
        XCTAssertEqual(try node.value(forSymbol: "contentOffset") as? CGPoint, offset)
    }

    func testSetContentOffsetX() {
        let node = LayoutNode(
            view: UIScrollView(),
            expressions: ["contentOffset.x": "5"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "contentOffset.x"), 5)
    }

    // MARK: CGSize

    func testGetContentSize() {
        let scrollView = UIScrollView()
        let node = LayoutNode(view: scrollView)
        XCTAssertEqual(try node.value(forSymbol: "contentSize") as? CGSize, scrollView.contentSize)
    }

    func testGetContentSizeWidth() {
        let scrollView = UIScrollView()
        let node = LayoutNode(view: scrollView)
        XCTAssertEqual(try node.doubleValue(forSymbol: "contentSize.width"), Double(scrollView.contentSize.width))
    }

    func testSetContentSize() {
        let size = CGSize(width: 5, height: 10)
        let node = LayoutNode(
            view: UIScrollView(),
            state: ["size": size],
            expressions: ["contentSize": "size"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "size") as? CGSize, size)
        XCTAssertEqual(try node.value(forSymbol: "contentSize") as? CGSize, size)
    }

    func testSetContentSizeWidth() {
        let node = LayoutNode(
            view: UIScrollView(),
            expressions: ["contentSize.width": "5"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.doubleValue(forSymbol: "contentSize.width"), 5)
    }

    // MARK: CGRect

    func testGetContentsCenter() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter") as? CGRect, view.layer.contentsCenter)
    }

    func testGetContentsCenterX() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.x") as? CGFloat, view.layer.contentsCenter.origin.x)
    }

    func testGetContentsCenterMinX() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.minX") as? CGFloat, view.layer.contentsCenter.minX)
    }

    func testGetContentsCenterWidth() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.width") as? CGFloat, view.layer.contentsCenter.width)
    }

    func testGetContentsCenterOrigin() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.origin") as? CGPoint, view.layer.contentsCenter.origin)
    }

    func testGetContentsCenterOriginX() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.origin.x") as? CGFloat, view.layer.contentsCenter.origin.x)
    }

    func testGetContentsCenterSize() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.size") as? CGSize, view.layer.contentsCenter.size)
    }

    func testGetContentsCenterSizeWidth() {
        let view = UIView()
        view.layer.contentsCenter = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(view: view)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.size.width") as? CGFloat, view.layer.contentsCenter.width)
    }

    func testSetContentsCenter() {
        let rect = CGRect(x: 1, y: 2, width: 5, height: 10)
        let node = LayoutNode(
            view: UIView(),
            state: ["rect": rect],
            expressions: ["layer.contentsCenter": "rect"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "rect") as? CGRect, rect)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter") as? CGRect, rect)
    }

    func testSetContentsCenterX() {
        let value: CGFloat = 5.0
        let node = LayoutNode(
            view: UIView(),
            expressions: ["layer.contentsCenter.x": "\(value)"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.x") as? CGFloat, value)
    }

    func testSetContentsCenterWidth() {
        let value: CGFloat = 5.0
        let node = LayoutNode(
            view: UIView(),
            expressions: ["layer.contentsCenter.width": "\(value)"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.width") as? CGFloat, value)
    }

    func testSetContentsCenterOrigin() {
        let origin = CGPoint(x: 1, y: 2)
        let node = LayoutNode(
            view: UIView(),
            state: ["origin": origin],
            expressions: ["layer.contentsCenter.origin": "origin"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "origin") as? CGPoint, origin)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.origin") as? CGPoint, origin)
    }

    func testSetContentsCenterOriginX() {
        let value: CGFloat = 5.0
        let node = LayoutNode(
            view: UIView(),
            expressions: ["layer.contentsCenter.origin.x": "\(value)"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.origin.x") as? CGFloat, value)
    }

    func testSetContentsCenterSize() {
        let size = CGSize(width: 1, height: 2)
        let node = LayoutNode(
            view: UIView(),
            state: ["size": size],
            expressions: ["layer.contentsCenter.size": "size"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "size") as? CGSize, size)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.size") as? CGSize, size)
    }

    func testSetContentsCenterSizeWidth() {
        let value: CGFloat = 5.0
        let node = LayoutNode(
            view: UIView(),
            expressions: ["layer.contentsCenter.size.width": "\(value)"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.contentsCenter.size.width") as? CGFloat, value)
    }

    // MARK: CGAffineTransform

    func testSetViewTransform() {
        let transform = CGAffineTransform(rotationAngle: .pi)
        let node = LayoutNode(
            state: ["rotation": transform],
            expressions: ["transform": "rotation"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "rotation") as? CGAffineTransform, transform)
        XCTAssertEqual(try node.value(forSymbol: "transform") as? CGAffineTransform, transform)
    }

    func testSetViewTransformRotation() {
        let node = LayoutNode(
            expressions: ["transform.rotation": "pi"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "transform.rotation") as? CGFloat, .pi)
    }

    func testSetViewTransformTranslation() {
        let node = LayoutNode(
            expressions: ["transform.translation.x": "5"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "transform.translation.x") as? CGFloat, 5)
    }

    // MARK: CATransform3D

    func testSetLayerTransform() {
        let transform = CATransform3DMakeRotation(.pi, 0, 0, 1)
        let node = LayoutNode(
            state: ["rotation": transform],
            expressions: ["layer.transform": "rotation"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "rotation") as? CATransform3D, transform)
        XCTAssertEqual(try node.value(forSymbol: "layer.transform") as? CATransform3D, transform)
    }

    func testSetLayerTransformRotation() {
        let node = LayoutNode(
            expressions: ["layer.transform.rotation": "pi"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.transform.rotation") as? CGFloat, .pi)
    }

    func testSetSublayerTransformRotation() {
        let node = LayoutNode(
            expressions: ["layer.sublayerTransform.rotation": "pi"]
        )
        XCTAssertTrue(node.validate().isEmpty)
        XCTAssertEqual(try node.value(forSymbol: "layer.sublayerTransform.rotation") as? CGFloat, .pi)
    }
}
