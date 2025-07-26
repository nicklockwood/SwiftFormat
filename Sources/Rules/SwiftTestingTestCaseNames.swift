// Created by Cal Stephens on 2/19/25.
// Copyright © 2025 Airbnb Inc. All rights reserved.

public extension FormatRule {
    static let swiftTestingTestCaseNames = FormatRule(
        help: "In Swift Testing, don't prefix @Test methods with 'test'."
    ) { formatter in
        guard formatter.hasImport("Testing") else { return }

        formatter.forEach(.keyword("func")) { funcKeywordIndex, _ in
            if formatter.modifiersForDeclaration(at: funcKeywordIndex, contains: "@Test") {
                formatter.removeTestPrefix(fromFunctionAt: funcKeywordIndex)
            }
        }
    } examples: {
        """
        ```diff
          import Testing

          struct MyFeatureTests {
        -     @Test func testMyFeatureHasNoBugs() {
        +     @Test func myFeatureHasNoBugs() {
                  let myFeature = MyFeature()
                  myFeature.runAction()
                  #expect(!myFeature.hasBugs, "My feature has no bugs")
                  #expect(myFeature.crashes.isEmpty, "My feature doesn't crash")
                  #expect(myFeature.crashReport == nil)
              }

        -     @Test func `test feature works as expected`(_ feature: Feature) {
        +     @Test func `feature works as expected`(_ feature: Feature) {
                let myFeature = MyFeature()
                myFeature.run(feature)
                #expect(myFeature.worksAsExpected)
            }
          }
        ```
        """
    }
}
