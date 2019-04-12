//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout
@testable import TestFramework

class ImageExpressionTests: XCTestCase {
    // MARK: Image constants

    func testImageConstant() {
        let testImage = UIImage()
        let node = LayoutNode(constants: ["testImage": testImage])
        let expression = LayoutExpression(imageExpression: "testImage", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIImage, testImage)
    }

    func testImageConstantWithComment() {
        let testImage = UIImage()
        let node = LayoutNode(constants: ["testImage": testImage])
        let expression = LayoutExpression(imageExpression: "testImage // test", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIImage, testImage)
    }

    func testBracedImageConstant() {
        let testImage = UIImage()
        let node = LayoutNode(constants: ["testImage": testImage])
        let expression = LayoutExpression(imageExpression: "{testImage}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIImage, testImage)
    }

    func testBracedImageConstantWithComment() {
        let testImage = UIImage()
        let node = LayoutNode(constants: ["testImage": testImage])
        let expression = LayoutExpression(imageExpression: "{testImage // test}", for: node)
        XCTAssertEqual(try expression?.evaluate() as? UIImage, testImage)
    }

    func testBracedImageConstantWithCommentOutsideBraces() {
        let testImage = UIImage()
        let node = LayoutNode(constants: ["testImage": testImage])
        let expression = LayoutExpression(imageExpression: "{testImage} // test", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) // TODO: handle this correctly and/or improve error message
    }

    // MARK: Image assets

    func testImageAssetInModuleByID() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "com.LayoutTests:MyImage", for: node)
        XCTAssertNotNil(try expression?.evaluate() as? UIImage)
    }

    func testImageAssetInModuleByName() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "LayoutTests:MyImage", for: node)
        XCTAssertNotNil(try expression?.evaluate() as? UIImage)
    }

    func testNonexistentImageAssetInModuleyByName() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "LayoutTests:MyImage2", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }

    func testNonexistentImageAssetInBundleByName() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "LayoutTests:MyImage2", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }

    func testImageAssetInFrameworkBundleByID() {
        _ = TestFrameworkClass()
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "com.TestFramework:Boxes", for: node)
        XCTAssertNotNil(try expression?.evaluate() as? UIImage)
    }

    func testImageAssetInFrameworkBundleByName() {
        _ = TestFrameworkClass()
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "TestFramework:Boxes", for: node)
        XCTAssertNotNil(try expression?.evaluate() as? UIImage)
    }

    func testImageAssetInNonexistentBundleByID() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "com.NotReal:MyImage2", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not locate bundle with identifier"))
        }
    }

    func testImageAssetInNonexistentBundleByName() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "NotReal:MyImage2", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not locate bundle with name"))
        }
    }

    // MARK: Bundle variables

    func testImageAssetInFrameworkBundle() {
        let bundle = Bundle(for: TestFrameworkClass.self)
        let node = LayoutNode(constants: ["bundle": bundle])
        let expression = LayoutExpression(imageExpression: "{bundle}:Boxes", for: node)
        XCTAssertNotNil(try expression?.evaluate() as? UIImage)
    }

    // MARK: Error messages

    func testNonexistentImageAssetInMainBundle() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "MyImage", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }

    func testQuotedNonexistentImageAssetInMainBundle() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "'MyImage'", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }

    func testNonexistentImageVariable() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "{MyImage}", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("Unknown property"))
        }
    }

    func testNonexistentQuotedImageName() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "{'MyImage'}", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }

    func testNonexistentImageAssetWithExpression() {
        let node = LayoutNode()
        let expression = LayoutExpression(imageExpression: "MyImage{5}", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("not found"))
        }
    }
}
