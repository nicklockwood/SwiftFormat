//
//  RedundantExtendedLifetimeTests.swift
//  SwiftFormatTests
//
//  Created by Cal Stephens on 2026-08-26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import XCTest
@testable import SwiftFormat

final class RedundantExtendedLifetimeTests: XCTestCase {
    func testRemovesEmptyCallInSwiftTestingTestCase() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                #expect(observer.isRunning)
                withExtendedLifetime(observer) {}
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                #expect(observer.isRunning)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantExtendedLifetime)
    }

    func testRemovesEmptyCallInXCTestTestCase() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeature() {
                let observer = Observer()
                observer.start()
                XCTAssertTrue(observer.isRunning)
                withExtendedLifetime(observer) {
                }
            }
        }
        """
        let output = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeature() {
                let observer = Observer()
                observer.start()
                XCTAssertTrue(observer.isRunning)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantExtendedLifetime)
    }

    func testHoistsClosureBody() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) {
                    observer.start()
                    #expect(observer.isRunning)
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                #expect(observer.isRunning)
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testPreservesCallWhereVariableIsNotOtherwiseReferenced() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeature() {
                let observer = Observer(handler: { XCTFail("unexpected") })
                withExtendedLifetime(observer) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallOnStoredProperty() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            private var observer: Observer!

            func testMyFeature() {
                observer = Observer()
                observer.start()
                withExtendedLifetime(observer) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallInNestedScope() {
        let input = """
        import XCTest

        final class MyFeatureTests: XCTestCase {
            func testMyFeature() {
                let observer = Observer()
                observer.start()
                DispatchQueue.main.async {
                    withExtendedLifetime(observer) {}
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallOutsideOfTestCase() {
        let input = """
        import XCTest

        final class MyFeatureHelper {
            func startObserving() {
                let observer = Observer()
                observer.start()
                withExtendedLifetime(observer) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallInFileWithNoTestingFramework() {
        let input = """
        final class MyFeatureTests {
            func testMyFeature() {
                let observer = Observer()
                observer.start()
                withExtendedLifetime(observer) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testHoistsClosureBodyWithShorthandArgument() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) {
                    $0.start()
                    $0.stop()
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                observer.stop()
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testHoistsClosureBodyWithNamedArgument() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) { observer in
                    observer.start()
                    observer.stop()
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                observer.stop()
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testRenamesDifferentlyNamedClosureArgument() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) { subject in
                    subject.start()
                    #expect(subject.isRunning)
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                #expect(observer.isRunning)
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testPreservesShorthandArgumentOfNestedClosure() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) {
                    $0.start()
                    events.forEach { $0.send() }
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                events.forEach { $0.send() }
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testHoistsClosureBodyWithDiscardedArgument() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) { _ in
                    observer.start()
                }
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
            }
        }
        """
        testFormatting(for: input, [output], rules: [.redundantExtendedLifetime, .indent])
    }

    func testPreservesClosureWithCaptureList() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                withExtendedLifetime(observer) { [weak observer] in
                    observer?.stop()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesClosureContainingReturn() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                withExtendedLifetime(observer) {
                    guard observer.isRunning else { return }

                    observer.stop()
                }
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallWithNonVariableArgument() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                withExtendedLifetime(observer.child) {}
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testPreservesCallWhoseResultIsUsed() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                observer.start()
                let isRunning = withExtendedLifetime(observer) {
                    observer.isRunning
                }
                #expect(isRunning)
            }
        }
        """
        testFormatting(for: input, rule: .redundantExtendedLifetime)
    }

    func testRemovesMultipleCallsInSameTestCase() {
        let input = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                let subscription = observer.subscribe()
                observer.start()
                #expect(subscription.isActive)
                withExtendedLifetime(observer) {}
                withExtendedLifetime(subscription) {}
            }
        }
        """
        let output = """
        import Testing

        struct MyFeatureTests {
            @Test
            func myFeature() {
                let observer = Observer()
                let subscription = observer.subscribe()
                observer.start()
                #expect(subscription.isActive)
            }
        }
        """
        testFormatting(for: input, output, rule: .redundantExtendedLifetime)
    }
}
