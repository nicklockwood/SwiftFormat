//  Copyright © 2017 Schibsted. All rights reserved.

import XCTest
@testable import Layout

class RuntimeTypeTests: XCTestCase {
    // MARK: Sanitized type names

    func testSanitizeURLName() {
        XCTAssertEqual(sanitizedTypeName("URL"), "url")
    }

    func testSanitizeURLRequestName() {
        XCTAssertEqual(sanitizedTypeName("URLRequest"), "urlRequest")
    }

    func testSanitizeStringName() {
        XCTAssertEqual(sanitizedTypeName("String"), "string")
    }

    func testSanitizeAttributedStringName() {
        XCTAssertEqual(sanitizedTypeName("NSAttributedString"), "nsAttributedString")
    }

    func testSanitizeUINavigationItem_LargeTitleDisplayModeName() {
        XCTAssertEqual(sanitizedTypeName("UINavigationItem.LargeTitleDisplayMode"), "uiNavigationItem_LargeTitleDisplayMode")
    }

    func testSanitizeEmptyName() {
        XCTAssertEqual(sanitizedTypeName(""), "")
    }

    // MARK: Type classification

    func testCGImageType() {
        let runtimeType = RuntimeType(CGImage.self)
        guard case let .pointer(name) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertEqual(name, "CGImage")
        XCTAssert(runtimeType.swiftType == CGImage.self)
    }

    func testCGColorType() {
        let runtimeType = RuntimeType(CGColor.self)
        guard case let .pointer(name) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertEqual(name, "CGColor")
        XCTAssert(runtimeType.swiftType == CGColor.self)
    }

    func testCGPathType() {
        let runtimeType = RuntimeType(CGPath.self)
        guard case let .pointer(name) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertEqual(name, "CGPath")
        XCTAssert(runtimeType.swiftType == CGPath.self)
    }

    func testCGRectType() {
        let runtimeType = RuntimeType(CGRect.self)
        guard case let .any(type) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(type == CGRect.self)
        XCTAssert(runtimeType.swiftType == CGRect.self)
    }

    func testProtocolType() {
        let runtimeType = RuntimeType(UITableViewDelegate.self)
        guard case .protocol = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(runtimeType.swiftType == Protocol.self)
    }

    func testDynamicProtocolType() {
        let type: Any.Type = UITableViewDelegate.self
        let runtimeType = RuntimeType(type)
        guard case .protocol = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(runtimeType.swiftType == Protocol.self)
    }

    func testArrayType() {
        let runtimeType = RuntimeType([Int].self)
        guard case .array = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(runtimeType.swiftType == [Any].self)
    }

    func testDynamicArrayType() {
        let type: Any.Type = [Int].self
        let runtimeType = RuntimeType(type)
        guard case .array = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(runtimeType.swiftType == [Any].self)
    }

    func testArrayTypeByName() {
        guard let runtimeType = RuntimeType.type(named: "Array<Int>") else {
            XCTFail()
            return
        }
        guard case let .array(subtype) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertEqual(subtype, .int)
        XCTAssert(runtimeType.swiftType == [Any].self)
    }

    func testArrayTypeByShortName() {
        guard let runtimeType = RuntimeType.type(named: "[Int]") else {
            XCTFail()
            return
        }
        guard case let .array(subtype) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertEqual(subtype, .int)
        XCTAssert(runtimeType.swiftType == [Any].self)
    }

    func testNSArrayTypeByName() {
        guard let runtimeType = RuntimeType.type(named: "NSArray") else {
            XCTFail()
            return
        }
        guard case .array = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(runtimeType.swiftType == [Any].self)
    }

    func testStringTypeByName() {
        guard let runtimeType = RuntimeType.type(named: "String") else {
            XCTFail()
            return
        }
        guard case let .any(type) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(type == String.self)
        XCTAssert(runtimeType.swiftType == String.self)
    }

    func testNSStringTypeByName() {
        guard let runtimeType = RuntimeType.type(named: "NSString") else {
            XCTFail()
            return
        }
        guard case let .any(type) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(type == String.self)
        XCTAssert(runtimeType.swiftType == String.self)
    }

    func testClassType() {
        let runtimeType = RuntimeType(class: NSIndexSet.self)
        guard case let .class(cls) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssert(cls == NSIndexSet.self)
        XCTAssert(runtimeType.swiftType == NSIndexSet.Type.self)
    }

    func testEnumType() {
        let runtimeType = RuntimeType.nsLineBreakMode
        guard case let .options(type, values) = runtimeType.kind else {
            XCTFail()
            return
        }
        XCTAssertFalse(values.isEmpty)
        XCTAssert(type == NSLineBreakMode.self)
        XCTAssert(runtimeType.swiftType == NSLineBreakMode.self)
    }

    // MARK: Type casting

    func testCastProtocol() {
        let runtimeType = RuntimeType(UITableViewDelegate.self)
        XCTAssertNil(runtimeType.cast(NSObject()))
        XCTAssertNil(runtimeType.cast(UITableViewDelegate.self))
        XCTAssertNotNil(runtimeType.cast(UITableViewController()))
    }

    func testCastNSArray() {
        let runtimeType = RuntimeType(NSArray.self)
        XCTAssertNotNil(runtimeType.cast(NSObject())) // Anything can be array-ified
        XCTAssertNotNil(runtimeType.cast(["foo"]))
        XCTAssertNotNil(runtimeType.cast([5, "foo"]))
        XCTAssertNotNil(runtimeType.cast([5]))
        XCTAssertNotNil(runtimeType.cast(NSArray()))
        XCTAssertNotNil(runtimeType.cast([(1, 2, 3)]))
    }

    func testCastDoesntCopyNSArray() {
        let runtimeType = RuntimeType(NSArray.self)
        let array = NSArray(array: [1, 2, 3, "foo", "bar", "baz"])
        XCTAssertTrue(runtimeType.cast(array) as? NSArray === array)
    }

    func testCastIntArray() {
        let runtimeType = RuntimeType([Int].self)
        XCTAssertNil(runtimeType.cast(NSObject()))
        XCTAssertNil(runtimeType.cast(["foo"]))
        XCTAssertNil(runtimeType.cast([5, "foo"]))
        XCTAssertNil(runtimeType.cast([[5]])) // Nested arrays are not flattened
        XCTAssertNotNil(runtimeType.cast([5]))
        XCTAssertNotNil(runtimeType.cast([5.0]))
        XCTAssertNotNil(runtimeType.cast(NSArray()))
        XCTAssertNotNil(runtimeType.cast([String]()))
        XCTAssertEqual(runtimeType.cast(5) as! [Int], [5]) // Stringified and array-ified
    }

    func testCastStringArray() {
        let runtimeType = RuntimeType([String].self)
        XCTAssertNotNil(runtimeType.cast(["foo"]))
        XCTAssertEqual(runtimeType.cast([5]) as! [String], ["5"]) // Anything can be stringified
        XCTAssertEqual(runtimeType.cast("foo") as! [String], ["foo"]) // Is array-ified
        XCTAssertEqual(runtimeType.cast(5) as! [String], ["5"]) // Stringified and array-ified
    }

    func testCastArrayArray() {
        let runtimeType = RuntimeType([[Int]].self)
        XCTAssertNotNil(runtimeType.cast([[5]]))
        XCTAssertNotNil(runtimeType.cast([5]) as? [[Int]]) // Inner values is array-ified
    }

    func testCastEnum() {
        let runtimeType = RuntimeType.nsLineBreakMode
        XCTAssertNotNil(runtimeType.cast(NSLineBreakMode.byClipping) as? NSLineBreakMode)
        XCTAssertNotNil(runtimeType.cast(NSLineBreakMode.byClipping.rawValue) as? NSLineBreakMode)
        XCTAssertNil(runtimeType.cast("byClipping") as? NSLineBreakMode)
    }

    private enum NonRawRepresentableEnum {
        case foo
        case bar
    }

    func testCastNonRawRepresentableEnum() {
        let runtimeType = RuntimeType(NonRawRepresentableEnum.self, ["foo": .foo, "bar": .bar])
        XCTAssertNotNil(runtimeType.cast(NonRawRepresentableEnum.foo) as? NonRawRepresentableEnum)
        XCTAssertNil(runtimeType.cast("foo") as? NonRawRepresentableEnum)
    }

    private struct TestStruct {
        let foo: Int
    }

    private enum NonHashableEnum: RawRepresentable {
        case foo
        case bar

        var rawValue: RuntimeTypeTests.TestStruct {
            return TestStruct(foo: 0)
        }

        init?(rawValue: RuntimeTypeTests.TestStruct) {
            switch rawValue.foo {
            case 0:
                self = .foo
            case 1:
                self = .bar
            default:
                return nil
            }
        }
    }

    func testCastNonHashableEnum() {
        let runtimeType = RuntimeType(NonHashableEnum.self, ["foo": .foo, "bar": .bar])
        XCTAssertNotNil(runtimeType.cast(NonHashableEnum.foo) as? NonHashableEnum)
        XCTAssertNotNil(runtimeType.cast(TestStruct(foo: 0)) as? NonHashableEnum)
        XCTAssertNil(runtimeType.cast(TestStruct(foo: 2)) as? NonHashableEnum)
        XCTAssertNil(runtimeType.cast("foo") as? NonHashableEnum)
    }

    private enum NonRawRepresentableOrHashableEnum {
        case foo
        case bar(Int)
    }

    func testCastNonRawRepresentableOrHashableEnum() {
        let runtimeType = RuntimeType(NonRawRepresentableOrHashableEnum.self, ["foo": .foo, "bar": .bar(0)])
        XCTAssertNotNil(runtimeType.cast(NonRawRepresentableOrHashableEnum.foo) as? NonRawRepresentableOrHashableEnum)
        XCTAssertNil(runtimeType.cast("foo") as? NonRawRepresentableOrHashableEnum)
    }

    func testCastOptionSet() {
        let runtimeType = RuntimeType.uiRectEdge
        XCTAssertNotNil(runtimeType.cast(UIRectEdge.top) as? UIRectEdge)
        XCTAssertNotNil(runtimeType.cast([UIRectEdge.top, UIRectEdge.left]) as? UIRectEdge)
        XCTAssertNotNil(runtimeType.cast(UIRectEdge.top.union(UIRectEdge.left)) as? UIRectEdge)
        XCTAssertNotNil(runtimeType.cast(UIRectEdge.top.rawValue) as? UIRectEdge)
        XCTAssertNotNil(runtimeType.cast(UIRectEdge.top.rawValue + UIRectEdge.left.rawValue) as? UIRectEdge)
        XCTAssertNil(runtimeType.cast("top") as? UIRectEdge)
    }

    #if swift(>=4.2)

        func testCastRawRepresentable() {
            let runtimeType = RuntimeType.uiScrollView_DecelerationRate
            XCTAssertNotNil(runtimeType.cast(UIScrollView.DecelerationRate.fast) as? UIScrollView.DecelerationRate)
            XCTAssertNotNil(runtimeType.cast(UIScrollView.DecelerationRate.fast.rawValue) as? UIScrollView.DecelerationRate)
            XCTAssertNotNil(runtimeType.cast(15 as CGFloat) as? UIScrollView.DecelerationRate)
            XCTAssertNotNil(runtimeType.cast(15) as? UIScrollView.DecelerationRate)
            XCTAssertNil(runtimeType.cast("fast") as? UIScrollView.DecelerationRate)
        }

    #endif
}
