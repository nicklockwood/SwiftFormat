//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

extension UIFont {
    @objc static let testFont = UIFont.systemFont(ofSize: 46)
}

class FontExpressionTests: XCTestCase {
    func testBold() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "bold", for: node)
        let expected = UIFont.systemFont(ofSize: UIFont.defaultSize, weight: .bold)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    #if swift(>=4)

        // Only works in Swift 4+ where UIFont.Weight is a distinct type, not CGFloat

        func testBoldWeight() {
            let node = LayoutNode()
            let expression = LayoutExpression(fontExpression: "{UIFont.Weight.bold}", for: node)
            let expected = UIFont.systemFont(ofSize: UIFont.defaultSize, weight: .bold)
            XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
        }

    #endif

    func testBoldTrait() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "{UIFontDescriptorSymbolicTraits.traitBold}", for: node)
        let descriptor = UIFont.systemFont(ofSize: UIFont.defaultSize).fontDescriptor
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits([.traitBold])!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testSystemBold() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "systemBold", for: node)
        let expected = UIFont.boldSystemFont(ofSize: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testSystemItalic() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "system italic", for: node)
        let expected = UIFont.italicSystemFont(ofSize: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBlack() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "black", for: node)
        let expected = UIFont.systemFont(ofSize: UIFont.defaultSize, weight: .black)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBoldItalic() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "bold italic", for: node)
        let descriptor = UIFont.systemFont(ofSize: UIFont.defaultSize, weight: .bold).fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitBold, .traitItalic])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testCondensed() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "condensed", for: node)
        let descriptor = UIFont.systemFont(ofSize: UIFont.defaultSize).fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitCondensed])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBlackCondensed() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "black condensed", for: node)
        let descriptor = UIFont.systemFont(ofSize: UIFont.defaultSize, weight: .black).fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitCondensed])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testMonospace() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "monospace", for: node)
        let descriptor = UIFont(name: "Courier", size: UIFont.defaultSize)!.fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitMonoSpace])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testFontName() {
        let node = LayoutNode()
        let name = "helvetica"
        let expression = LayoutExpression(fontExpression: name, for: node)
        let expected = UIFont(name: name, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testEscapedFontNameWithSpaces() {
        let node = LayoutNode()
        let name = "helvetica neue"
        let expression = LayoutExpression(fontExpression: "'\(name)'", for: node)
        let expected = UIFont(name: name, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBoldEscapedFontNameWithSpaces() {
        let node = LayoutNode()
        let name = "helvetica neue"
        let expression = LayoutExpression(fontExpression: "'\(name)' bold", for: node)
        let descriptor = UIFont(name: name, size: UIFont.defaultSize)!.fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitBold])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBlackEscapedFontNameWithSpaces() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "'helvetica neue' black", for: node)
        let expected = UIFont(name: "HelveticaNeue-CondensedBlack", size: UIFont.defaultSize)!
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testUltralightEscapedFontNameWithSpaces() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "'helvetica neue' ultralight", for: node)
        let expected = UIFont(name: "HelveticaNeue-UltraLight", size: UIFont.defaultSize)!
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBoldUnescapedFontNameWithSpaces() {
        let node = LayoutNode()
        let name = "helvetica neue"
        let expression = LayoutExpression(fontExpression: "\(name) bold", for: node)
        let descriptor = UIFont(name: name, size: UIFont.defaultSize)!.fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitBold])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: UIFont.defaultSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBlackUnescapedFontNameWithSpaces() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "helvetica neue black", for: node)
        let expected = UIFont(name: "HelveticaNeue-CondensedBlack", size: UIFont.defaultSize)!
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testBlackUnescapedFontNameWithSpaces2() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "Apple SD Gothic Neo light", for: node)
        let expected = UIFont(name: "AppleSDGothicNeo-Light", size: UIFont.defaultSize)!
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testUltralightUnescapedFontNameWithSpaces() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "helvetica neue ultralight", for: node)
        let expected = UIFont(name: "HelveticaNeue-UltraLight", size: UIFont.defaultSize)!
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testExplicitFontWithBoldAttributes() {
        let font = UIFont(name: "courier", size: 15)!
        let node = LayoutNode(constants: ["font": font])
        let expression = LayoutExpression(fontExpression: "{font} bold", for: node)
        let descriptor = font.fontDescriptor
        let traits = descriptor.symbolicTraits.union([.traitBold])
        let expected = UIFont(descriptor: descriptor.withSymbolicTraits(traits)!, size: font.pointSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testNilFont() {
        let font: UIFont? = nil
        let node = LayoutNode(constants: ["font": font as Any])
        let expression = LayoutExpression(fontExpression: "{font} bold", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssert("\(error)".contains("nil"))
        }
    }

    func testFontTextStyle() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "caption1", for: node)
        let expected = UIFont.preferredFont(forTextStyle: .caption1)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testCustomFontTextStyle() {
        let node = LayoutNode()
        let name = "courier"
        let expression = LayoutExpression(fontExpression: "\(name) title1", for: node)
        let expectedSize = UIFont.preferredFont(forTextStyle: .title1).pointSize
        let expected = UIFont(name: name, size: expectedSize)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testFontSize() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "19", for: node)
        let expected = UIFont.systemFont(ofSize: 19)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testRelativeFontSize() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "150%", for: node)
        let expected = UIFont.systemFont(ofSize: UIFont.defaultSize * 1.5)
        XCTAssertEqual(try expression?.evaluate() as? UIFont, expected)
    }

    func testFontTextStyleWithRelativeSize() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "body 150%", for: node)
        let expectedSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 1.5
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.pointSize, expectedSize)
    }

    func testInvalidSpecifier() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "bold 10 foo", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssertTrue("\(error)".contains("Invalid font name or specifier"))
        }
    }

    func testInvalidSpecifier2() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "Heiti SC weight", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssertTrue("\(error)".contains("Invalid font name or specifier"))
        }
    }

    func testInvalidFont() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "foobar", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssertTrue("\(error)".contains("Invalid font name or specifier"))
        }
    }

    func testInvalidFont2() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "foobar 20", for: node)
        XCTAssertThrowsError(try expression?.evaluate()) { error in
            XCTAssertTrue("\(error)".contains("Invalid font name or specifier"))
        }
    }

    func testCustomStaticFont1() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "testFont", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.pointSize, UIFont.testFont.pointSize)
    }

    func testCustomStaticFont2() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "test", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.pointSize, UIFont.testFont.pointSize)
    }

    func testCustomStaticFont3() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "{UIFont.testFont}", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.pointSize, UIFont.testFont.pointSize)
    }

    func testCustomStaticFont4() {
        let node = LayoutNode()
        let expression = LayoutExpression(fontExpression: "{testFont}", for: node)
        XCTAssertThrowsError(try expression?.evaluate())
    }

    func testAmbiguousFamilyName() {
        let node = LayoutNode()
        let familyName = "Avenir Next Condensed"
        let expression = LayoutExpression(fontExpression: "\(familyName) bold", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.familyName, familyName)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.fontWeight, .bold)
    }

    func testAmbiguousFamilyName2() {
        let node = LayoutNode()
        let familyName = "Avenir Next Condensed"
        let expression = LayoutExpression(fontExpression: "\(familyName) heavy", for: node)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.familyName, familyName)
        XCTAssertEqual(try (expression?.evaluate() as? UIFont)?.fontWeight, .heavy)
    }

    func testBuiltInFontWeights() {
        let node = LayoutNode()
        for familyName in UIFont.familyNames {
            for weightKey in RuntimeType.uiFont_Weight.values.keys {
                let expression = LayoutExpression(fontExpression: "\(familyName) \(weightKey)", for: node)
                let expected = UIFont.fontNames(forFamilyName: familyName).filter {
                    $0.lowercased().contains("-\(weightKey.lowercased())")
                }
                if !expected.isEmpty {
                    let name = try! (expression!.evaluate() as! UIFont).fontName
                    XCTAssertTrue(expected.contains(name), "\(expected) does not contain \(name)")
                }
            }
        }
    }
}
