//
//  Examples.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 07/02/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Foundation

extension FormatRule {
    var examples: String? {
        return name.flatMap { examplesByRuleName[$0] }
    }
}

private let examplesByRuleName: [String: String] = {
    var examples = [String: String]()
    for (label, value) in Mirror(reflecting: Examples()).children {
        guard let name = label, let text = value as? String, !text.isEmpty else {
            continue
        }
        examples[name] = text
    }
    return examples
}()

private struct Examples {
    let andOperator = """
    ```diff
    - if true && true {
    + if true, true {
    ```

    ```diff
    - guard true && true else {
    + guard true, true else {
    ```

    ```diff
    - if functionReturnsBool() && true {
    + if functionReturnsBool(), true {
    ```

    ```diff
    - if functionReturnsBool() && variable {
    + if functionReturnsBool(), variable {
    ```
    """

    let anyObjectProtocol = """
    ```diff
    - protocol Foo: class {}
    + protocol Foo: AnyObject {}
    ```

    **NOTE:** The guideline to use `AnyObject` instead of `class` was only
    introduced in Swift 4.1, so the `anyObjectProtocol` rule is disabled unless the
    swift version is set to 4.1 or above.
    """

    let blankLinesAtEndOfScope = """
    ```diff
      func foo() {
        // foo
    -
      }

      func foo() {
        // foo
      }
    ```

    ```diff
      array = [
        foo,
        bar,
        baz,
    -
      ]

      array = [
        foo,
        bar,
        baz,
      ]
    ```
    """

    let blankLinesAtStartOfScope = """
    ```diff
      func foo() {
    -
        // foo
      }

      func foo() {
        // foo
      }
    ```

    ```diff
      array = [
    -
        foo,
        bar,
        baz,
      ]

      array = [
        foo,
        bar,
        baz,
      ]
    ```
    """

    let blankLinesBetweenScopes = """
    ```diff
      func foo() {
        // foo
      }
      func bar() {
        // bar
      }
      var baz: Bool
      var quux: Int

      func foo() {
        // foo
      }
    +
      func bar() {
        // bar
      }
    +
      var baz: Bool
      var quux: Int
    ```
    """

    let blankLinesAroundMark = """
    ```diff
      func foo() {
        // foo
      }
      // MARK: bar
      func bar() {
        // bar
      }

      func foo() {
        // foo
      }
    +
      // MARK: bar
    +
      func bar() {
        // bar
      }
    ```
    """

    let braces = """
    ```diff
    - if x
    - {
        // foo
      }
    - else
    - {
        // bar
      }

    + if x {
        // foo
      }
    + else {
        // bar
      }
    ```
    """

    let consecutiveBlankLines = """
    ```diff
      func foo() {
        let x = "bar"
    -

        print(x)
      }

      func foo() {
        let x = "bar"

        print(x)
      }
    ```
    """

    let consecutiveSpaces = """
    ```diff
    - let     foo = 5
    + let foo = 5
    ```
    """

    let duplicateImports = """
    ```diff
      import Foo
      import Bar
    - import Foo
    ```

    ```diff
      import B
      #if os(iOS)
        import A
    -   import B
      #endif
    ```
    """

    let elseOnSameLine = """
    ```diff
      if x {
        // foo
    - }
    - else {
        // bar
      }

      if x {
        // foo
    + } else {
        // bar
      }
    ```

    ```diff
      do {
        // try foo
    - }
    - catch {
        // bar
      }

      do {
        // try foo
    + } catch {
        // bar
      }
    ```

    ```diff
      repeat {
        // foo
    - }
    - while {
        // bar
      }

      repeat {
        // foo
    + } while {
        // bar
      }
    ```
    """

    let emptyBraces = """
    ```diff
    - func foo() {
    -
    - }

    + func foo() {}
    ```
    """

    let hoistPatternLet = """
    ```diff
    - (let foo, let bar) = baz()
    + let (foo, bar) = baz()
    ```

    ```diff
    - if case .foo(let bar, let baz) = quux {
        // inner foo
      }

    + if case let .foo(bar, baz) = quux {
        // inner foo
      }
    ```
    """

    let indent = """
    ```diff
      if x {
    -     // foo
      } else {
    -     // bar
    -       }

      if x {
    +   // foo
      } else {
    +   // bar
    + }
    ```

    ```diff
      let array = [
        foo,
    -     bar,
    -       baz
    -   ]

      let array = [
        foo,
    +   bar,
    +   baz
    + ]
    ```

    ```diff
      switch foo {
    -   case bar: break
    -   case baz: break
      }

      switch foo {
    + case bar: break
    + case baz: break
      }
    ```
    """

    let isEmpty = """
    ```diff
    - if foo.count == 0 {
    + if foo.isEmpty {

    - if foo.count > 0 {
    + if !foo.isEmpty {

    - if foo?.count == 0 {
    + if foo?.isEmpty == true {
    ```
    """

    let numberFormatting = """
    ```diff
    - let color = 0xFF77A5
    + let color = 0xff77a5
    ```

    ```diff
    - let big = 123456.123
    + let big = 123_456.123
    ```
    """

    let ranges = """
    ```diff
    - for i in 0..<5 {}
    + for i in 0 ..< 5 {}
    ```

    ```diff
    - if (0...5).contains(i) {}
    + if (0 ... 5).contains(i) {}
    ```
    """

    let redundantBackticks = """
    ```diff
    - let `infix` = bar
    + let infix = bar
    ```

    ```diff
    - func foo(with `default`: Int) {}
    + func foo(with default: Int) {}
    ```
    """

    let redundantBreak = """
    ```diff
      switch foo {
        case bar:
            print("bar")
    -       break
        default:
            print("default")
    -       break
      }
    ```
    """

    let redundantGet = """
    ```diff
      var foo: Int {
    -   get {
    -     return 5
    -   }
      }

      var foo: Int {
    +   return 5
      }
    ```
    """

    let redundantExtensionACL = """
    ```diff
      public extension URL {
    -   public func queryParameter(_ name: String) -> String { ... }
      }

      public extension URL {
    +   func queryParameter(_ name: String) -> String { ... }
      }
    ```
    """

    let redundantFileprivate = """
    ```diff
    -  fileprivate let someConstant = "someConstant"
    +  private let someConstant = "someConstant"
    ```

    In Swift 4 and above, `fileprivate` can also be replaced with `private` for
    members that are only accessed from extensions in the same file:

    ```diff
      class Foo {
    -   fileprivate var foo = "foo"
    +   private var foo = "foo"
      }

      extension Foo {
        func bar() {
          print(self.foo)
        }
      }
    ```
    """

    let redundantLet = """
    ```diff
    - let _ = foo()
    + _ = foo()
    ```
    """

    let redundantLetError = """
    ```diff
    - do { ... } catch let error { log(error) }
    + do { ... } catch { log(error) }
    ```
    """

    let redundantNilInit = """
    ```diff
    - var foo: Int? = nil
    + var foo: Int?
    ```

    ```diff
    // doesn't apply to `let` properties
    let foo: Int? = nil
    ```

    ```diff
    // doesn't affect non-nil initialization
    var foo: Int? = 0
    ```
    """

    let redundantObjc = """
    ```diff
    - @objc @IBOutlet var label: UILabel!
    + @IBOutlet var label: UILabel!
    ```

    ```diff
    - @IBAction @objc func goBack() {}
    + @IBOutlet func goBack() {}
    ```

    ```diff
    - @objc @NSManaged private var foo: String?
    + @NSManaged private var foo: String?
    ```
    """

    let redundantParens = """
    ```diff
    - if (foo == true) {}
    + if foo == true {}
    ```

    ```diff
    - while (i < bar.count) {}
    + while i < bar.count {}
    ```

    ```diff
    - queue.async() { ... }
    + queue.async { ... }
    ```

    ```diff
    - let foo: Int = ({ ... })()
    + let foo: Int = { ... }()
    ```
    """

    let redundantPattern = """
    ```diff
    - if case .foo(_, _) = bar {}
    + if case .foo = bar {}
    ```

    ```diff
    - let (_, _) = bar
    + let _ = bar
    ```
    """

    let redundantRawValues = """
    ```diff
      enum Foo: String {
    -   case bar = "bar"
        case baz = "quux"
      }

      enum Foo: String {
    +   case bar
        case baz = "quux"
      }
    ```
    """

    let redundantReturn = """
    ```diff
    - array.filter { return $0.foo == bar }
    + array.filter { $0.foo == bar }
    ```
    """

    let redundantSelf = """
    ```diff
      func foobar(foo: Int, bar: Int) {
        self.foo = foo
        self.bar = bar
    -   self.baz = 42
      }

      func foobar(foo: Int, bar: Int) {
        self.foo = foo
        self.bar = bar
    +   baz = 42
      }
    ```

    In the rare case of functions with `@autoclosure` arguments, `self` may be
    required at the call site, but SwiftFormat is unable to detect this
    automatically. You can use the `--selfrequired` command-line option to specify
    a list of such methods, and the `redundantSelf` rule will then ignore them.

    An example of such a method is the `expect()` function in the Nimble unit
    testing framework (https://github.com/Quick/Nimble), which is common enough that
    SwiftFormat excludes it by default.

    There is also an option to always use explicit `self` but *only* inside `init`,
    by using `--self init-only`:

    ```diff
      init(foo: Int, bar: Int) {
        self.foo = foo
        self.bar = bar
    -   baz = 42
      }

      init(foo: Int, bar: Int) {
        self.foo = foo
        self.bar = bar
    +   self.baz = 42
      }
    ```
    """

    let redundantVoidReturnType = """
    ```diff
    - func foo() -> Void {
        // returns nothing
      }

    + func foo() {
        // returns nothing
      }
    ```
    """

    let redundantInit = """
    ```diff
    - String.init("text")
    + String("text")
    ```
    """

    let semicolons = """
    ```diff
    - let foo = 5;
    + let foo = 5
    ```

    ```diff
    - let foo = 5; let bar = 6
    + let foo = 5
    + let bar = 6
    ```

    ```diff
    // semicolon is not removed if it would affect the behavior of the code
    return;
    goto(fail)
    ```
    """

    let sortedImports = """
    ```diff
    - import Foo
    - import Bar
    + import Bar
    + import Foo
    ```

    ```diff
    - import B
    - import A
    - #if os(iOS)
    -   import Foo-iOS
    -   import Bar-iOS
    - #endif
    + import A
    + import B
    + #if os(iOS)
    +   import Bar-iOS
    +   import Foo-iOS
    + #endif
    ```
    """

    let spaceAroundBraces = """
    ```diff
    - foo.filter{ return true }.map{ $0 }
    + foo.filter { return true }.map { $0 }
    ```

    ```diff
    - foo( {} )
    + foo({})
    ```
    """

    let spaceAroundBrackets = """
    ```diff
    - foo as[String]
    + foo as [String]
    ```

    ```diff
    - foo = bar [5]
    + foo = bar[5]
    ```
    """

    let spaceAroundComments = """
    ```diff
    - let a = 5// assignment
    + let a = 5 // assignment
    ```

    ```diff
    - func foo() {/* no-op */}
    + func foo() { /* no-op */ }
    ```
    """

    let spaceAroundGenerics = """
    ```diff
    - Foo <Bar> ()
    + Foo<Bar>()
    ```
    """

    let spaceAroundOperators = """
    ```diff
    - foo . bar()
    + foo.bar()
    ```

    ```diff
    - a+b+c
    + a + b + c
    ```

    ```diff
    - func ==(lhs: Int, rhs: Int) -> Bool
    + func == (lhs: Int, rhs: Int) -> Bool
    ```
    """

    let spaceAroundParens = """
    ```diff
    - init (foo)
    + init(foo)
    ```

    ```diff
    - switch(x){
    + switch (x) {
    ```
    """

    let spaceInsideBraces = """
    ```diff
    - foo.filter {return true}
    + foo.filter { return true }
    ```
    """

    let spaceInsideBrackets = """
    ```diff
    - [ 1, 2, 3 ]
    + [1, 2, 3]
    ```
    """

    let spaceInsideComments = """
    ```diff
    - let a = 5 //assignment
    + let a = 5 // assignment
    ```

    ```diff
    - func foo() { /*no-op*/ }
    + func foo() { /* no-op */ }
    ```
    """

    let spaceInsideGenerics = """
    ```diff
    - Foo< Bar, Baz >
    + Foo<Bar, Baz>
    ```
    """

    let spaceInsideParens = """
    ```diff
    - ( a, b)
    + (a, b)
    ```
    """

    let specifiers = """
    ```diff
    - lazy public weak private(set) var foo: UIView?
    + public private(set) lazy weak var foo: UIView?
    ```

    ```diff
    - override public final func foo()
    + public final override func foo()
    ```

    ```diff
    - convenience private init()
    + private convenience init()
    ```
    """

    let strongifiedSelf = """
    ```diff
    - guard let `self` = self else { return }
    + guard let self = self else { return }
    ```

    **NOTE:** assignment to un-escaped `self` is only supported in Swift 4.2 and
    above, so the `strongifiedSelf` rule is disabled unless the swift version is
    set to 4.2 or above.
    """

    let strongOutlets = """
    As per Apple's recommendation
    (https://developer.apple.com/videos/play/wwdc2015/407/).

    ```diff
    - @IBOutlet weak var label: UILabel!
    + @IBOutlet var label: UILabel!
    ```
    """

    let trailingClosures = """
    ```diff
    - DispatchQueue.main.async(execute: { ... })
    + DispatchQueue.main.async {
    ```

    ```diff
    - let foo = bar.map({ ... }).joined()
    + let foo = bar.map { ... }.joined()
    ```
    """

    let trailingCommas = """
    ```diff
      let array = [
        foo,
        bar,
    -   baz
      ]

      let array = [
        foo,
        bar,
    +   baz,
      ]
    ```
    """

    let todos = """
    ```diff
    - /* TODO fix this properly */
    + /* TODO: fix this properly */
    ```

    ```diff
    - // MARK - UIScrollViewDelegate
    + // MARK: - UIScrollViewDelegate
    ```
    """

    let typeSugar = """
    ```diff
    - var foo: Array<String>
    + var foo: [String]
    ```

    ```diff
    - var foo: Dictionary<String, Int>
    + var foo: [String: Int]
    ```

    ```diff
    - var foo: Optional<(Int) -> Void>
    + var foo: ((Int) -> Void)?
    ```
    """

    let unusedArguments = """
    ```diff
    - func foo(bar: Int, baz: String) {
        print("Hello \\(baz)")
      }

    + func foo(bar _: Int, baz: String) {
        print("Hello \\(baz)")
      }
    ```

    ```diff
    - func foo(_ bar: Int) {
        // no-op
      }

    + func foo(_: Int) {
        // no-op
      }
    ```

    ```diff
    - request { response, data in
        self.data += data
      }

    + request { _, data in
        self.data += data
      }
    ```
    """

    let void = """
    ```diff
    - let foo: () -> ()
    + let foo: () -> Void
    ```

    ```diff
    - let bar: Void -> Void
    + let bar: () -> Void
    ```

    ```diff
    - let baz: (Void) -> Void
    + let baz: () -> Void
    ```

    ```diff
    - func quux() -> (Void)
    + func quux() -> Void
    ```
    """

    let wrapArguments = """
    ```diff
    - func foo(bar: Int,
    -          baz: String) {
        // foo function
      }

    + func foo(
    +   bar: Int,
    +   baz: String
    + ) {
        // foo function
      }
    ```

    Or for `--wrapcollections before-first`:

    ```diff
    - let foo = [bar,
                 baz,
    -            quuz]

    + let foo = [
    +   bar,
        baz,
    +   quuz
    ]
    ```
    """
}
