import XCTest
@testable import SwiftFormat

final class StepstoneRulesTests: RulesTests {
    func testStStRedundantOneLineVarReturn() {
        let input = """
        var something: Int {
            return 5
        }
        var somethingElse: Int {
            return 6
        }
        """
        let output = """
        var something: Int { 5 }
        var somethingElse: Int { 6 }
        """

        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantOneLineVarReturn], options: .default), output)
    }

    func testStStRedundantOneLineVarReturnMoreStatementsNoChange() {
        let input = """
        override var something: Type {
            doOtherThing()
            return somethingElse
        }
        """
        let output = input

        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantOneLineVarReturn], options: .default), output)
    }

    func testStStRedundantOneLineVarReturnInsideFunctionNoChange() {
        let input = """
        var offset: CGFloat = 0
        if subviews.isEmpty {
            return offset
        }
        """
        let output = input

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantOneLineVarReturn, FormatRules.consecutiveSpaces], options: options), output)
    }

    func testStstLinebreakAfterGuard() {
        let input = """
        guard let something = something else { return }
        Aaaa()
        """
        let output = """
        guard let something = something else { return }

        Aaaa()
        """

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakAfterGuard], options: options), output)
    }

    func testStstLinebreakAfterGuardNoChange() {
        let input = """
        guard let something = something else { return }

        Aaaa()
        """
        let output = input
        let options = FormatOptions(removeBlankLines: true)

        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakAfterGuard], options: options), output)
    }

    func testStstLinebreakAfterGuardAtTheEndNoChange() {
        let input = """
        {
            guard let something = something else { return }
            }
        """
        let output = input
        let options = FormatOptions(removeBlankLines: true)

        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakAfterGuard], options: options), output)
    }

    func testStstLinebreakBeforeReturn() {
        let input = """
        guard let something = something else { return }
        return Aaaa()
        """
        let output = """
        guard let something = something else { return }

        return Aaaa()
        """

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakBeforeReturn], options: options), output)
    }

    func testStstLinebreakBeforeReturnNoChange() {
        let input = """
        guard let something = something else { return }

        return Aaaa()
        """
        let output = input

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakBeforeReturn], options: options), output)
    }

    func testStstLinebreakBeforeReturnSingleLinesNoChange() {
        let input = """
        if expression {
            return iPhoneValue
        } else {
            return iPadValue
        }
        """
        let output = input

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakBeforeReturn], options: options), output)
    }

    func testStstRedundantTypeNameBool() {
        let input = "var something: Bool = true"
        let output = "var something = true"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeNameString() {
        let input = "var something: String = \"value\" "
        let output = "var something = \"value\" "

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeNameStatic() {
        let input = "var something: Type = Type.make()!"
        let output = "var something = Type.make()!"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeName() {
        let input = "var something: Type = Type(value: 5)"
        let output = "var something = Type(value: 5)"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeNameCGFloat() {
        let input = "var something: CGFloat = CGFloat(apply(233))"
        let output = "var something: CGFloat = apply(233)"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeNameEnum() {
        let input = "var something: UIColor = UIColor.red"
        let output = "var something = UIColor.red"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), output)
    }

    func testStstRedundantTypeNameInsideFunArgsNoChange() {
        let input = "func doSomething(with test: Bool = true)"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), input)
    }

    func testStstRedundantTypeNameFailableInitNoChange() {
        let input = "let image: UIImage = UIImage(named: \"aaa\")!"

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststRedundantTypeName], options: options), input)
    }

    func testStstLinebreakAfterClass() {
        let input = """
        class StepBaseView<ContentView: UIView>: SCBaseView, SingleStepView {
            private struct Constants {
                let backgroundColor = UIColor.white
                let horizontalMargin: CGFloat = 16
            }
        }
        """
        let output = """
        class StepBaseView<ContentView: UIView>: SCBaseView, SingleStepView {

            private struct Constants {

                let backgroundColor = UIColor.white
                let horizontalMargin: CGFloat = 16
            }
        }
        """

        let options = FormatOptions(removeBlankLines: true)
        XCTAssertEqual(try format(input, rules: [FormatRules.ststLinebreakAfterClassExtensionStruct], options: options), output)
    }
}
