//
//  InitCoderUnavailableTests.swift
//  SwiftFormatTests
//
//  Created by Facundo Menzella on 8/20/20.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class InitCoderUnavailableTests: XCTestCase {
    func testInitCoderUnavailableEmptyFunction() {
        let input = """
        struct A: UIView {
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        let output = """
        struct A: UIView {
            @available(*, unavailable)
            required init?(coder aDecoder: NSCoder) {}
        }
        """
        testFormatting(for: input, output, rule: .initCoderUnavailable,
                       exclude: [.unusedArguments])
    }

    func testInitCoderUnavailableFatalErrorNilDisabled() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder _: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }
            }
        }
        """
        let output = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }
            }
        }
        """
        let options = FormatOptions(initCoderNil: false)
        testFormatting(for: input, output, rule: .initCoderUnavailable, options: options)
    }

    func testInitCoderUnavailableFatalErrorNilEnabled() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder _: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }
            }
        }
        """
        let output = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    nil
                }
            }
        }
        """
        let options = FormatOptions(initCoderNil: true)
        testFormatting(for: input, output, rule: .initCoderUnavailable, options: options)
    }

    func testInitCoderUnavailableAlreadyPresent() {
        let input = """
        extension Module {
            final class A: UIView {
                @available(*, unavailable)
                required init?(coder _: NSCoder) {
                    fatalError()
                }
            }
        }
        """
        testFormatting(for: input, rule: .initCoderUnavailable)
    }

    func testInitCoderUnavailableImplemented() {
        let input = """
        extension Module {
            final class A: UIView {
                required init?(coder aCoder: NSCoder) {
                    aCoder.doSomething()
                }
            }
        }
        """
        testFormatting(for: input, rule: .initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable() {
        let input = """
        public class Foo: UIView {
            public required init?(coder _: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        """
        let output = """
        public class Foo: UIView {
            @available(*, unavailable)
            public required init?(coder _: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        """
        testFormatting(for: input, output, rule: .initCoderUnavailable)
    }

    func testPublicInitCoderUnavailable2() {
        let input = """
        public class Foo: UIView {
            required public init?(coder _: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        """
        let output = """
        public class Foo: UIView {
            @available(*, unavailable)
            required public init?(coder _: NSCoder) {
                nil
            }
        }
        """
        let options = FormatOptions(initCoderNil: true)
        testFormatting(for: input, output, rule: .initCoderUnavailable,
                       options: options, exclude: [.modifierOrder])
    }
}
