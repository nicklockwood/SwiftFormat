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
        examplesByRuleName[name]
    }
}

extension _FormatRules {
    var examplesByName: [String: String] {
        examplesByRuleName
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

    let blankLinesBetweenImports = """
    ```diff
      import A
    -
      import B
      import C
    -
    -
      @testable import D
      import E
    ```
    """

    let blankLineAfterImports = """
    ```diff
      import A
      import B
      @testable import D
    +
      class Foo {
        // foo
      }
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

    let wrapConditionalBodies = """
    ```diff
    - guard let foo = bar else { return baz }
    + guard let foo = bar else {
    +     return baz
    + }
    ```

    ```diff
    - if foo { return bar }
    + if foo {
    +    return bar
    + }
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

    let hoistAwait = """
    ```diff
    - greet(await forename, await surname)
    + await greet(forename, surname)
    ```

    ```diff
    - let foo = String(try await getFoo())
    + let foo = await String(try getFoo())
    ```
    """

    let hoistTry = """
    ```diff
    - foo(try bar(), try baz())
    + try foo(bar(), baz())
    ```

    ```diff
    - let foo = String(try await getFoo())
    + let foo = try String(await getFoo())
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

    ***NOTE:*** In rare cases, the `isEmpty` rule may insert an `isEmpty` call for
    a type that doesn't implement that property, breaking the program. For this
    reason, the rule is disabled by default, and must be manually enabled via the
    `--enable isEmpty` option.
    """

    let initCoderUnavailable = """
    ```diff
    + @available(*, unavailable)
      required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }
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
    + @IBAction func goBack() {}
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

      // Swift 5.1+ (SE-0255)
      var foo: String {
    -     return "foo"
    +     "foo"
      }

      // Swift 5.8+ (SE-0380)
      func foo(_ condition: Bool) -> String {
          if condition {
    -         return "foo"
    +         "foo"
          } else {
    -         return "bar"
    +         "bar"
          }
      }
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
    - func foo() {/* ... */}
    + func foo() { /* ... */ }
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
    - func foo() { /*...*/ }
    + func foo() { /* ... */ }
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

    let redundantType = """
    ```diff
    // inferred
    - let view: UIView = UIView()
    + let view = UIView()

    // explicit
    - let view: UIView = UIView()
    + let view: UIView = .init()

    // infer-locals-only
      class Foo {
    -     let view: UIView = UIView()
    +     let view: UIView = .init()

          func method() {
    -         let view: UIView = UIView()
    +         let view = UIView()
          }
      }

    // Swift 5.8+, inferred (SE-0380)
    - let foo: Foo = if condition {
    + let foo = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }

    // Swift 5.8+, explicit (SE-0380)
      let foo: Foo = if condition {
    -     Foo("foo")
    +     .init("foo")
      } else {
    -     Foo("bar")
    +     .init("foo")
      }
    ```
    """

    let modifierOrder = """
    ```diff
    - lazy public weak private(set) var foo: UIView?
    + public private(set) lazy weak var foo: UIView?
    ```

    ```diff
    - final public override func foo()
    + override public final func foo()
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
    above, so the `strongifiedSelf` rule is disabled unless the Swift version is
    set to 4.2 or above.
    """

    let strongOutlets = """
    As per Apple's recommendation
    (https://developer.apple.com/videos/play/wwdc2015/407/ @ 32:30).

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
        ...
      }

    + func foo(_: Int) {
        ...
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

    let wrapEnumCases = """
    ```diff
      enum Foo {
    -   case bar, baz
      }

      enum Foo {
    +   case bar
    +   case baz
      }
    ```
    """

    let wrapSwitchCases = """
    ```diff
      switch foo {
    -   case .bar, .baz:
          break
      }

      switch foo {
    +   case .foo,
    +        .bar:
          break
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

    ```diff
    - callback = { _ in Void() }
    + callback = { _ in () }
    ```
    """

    let wrapArguments = """
    **NOTE:** For backwards compatibility with previous versions, if no value is
    provided for `--wrapparameters`, the value for `--wraparguments` will be used.

    `--wraparguments before-first`

    ```diff
    - foo(bar: Int,
    -     baz: String)

    + foo(
    +   bar: Int,
    +   baz: String
    + )
    ```

    ```diff
    - class Foo<Bar,
    -           Baz>

    + class Foo<
    +   Bar,
    +   Baz
    + >
    ```

    `--wrapparameters after-first`

    ```diff
    - func foo(
    -   bar: Int,
    -   baz: String
    - ) {
        ...
      }

    + func foo(bar: Int,
    +          baz: String) {
        ...
      }
    ```

    `--wrapcollections before-first`:

    ```diff
    - let foo = [bar,
                 baz,
    -            quuz]

    + let foo = [
    +   bar,
        baz,
    +   quuz
    + ]
    ```

    `--conditionswrap auto`:

    ```diff
    - guard let foo = foo, let bar = bar, let third = third
    + guard let foo = foo,
    +       let bar = bar,
    +       let third = third
      else {}
    ```

    """

    let wrapMultilineStatementBraces = """
    ```diff
      if foo,
    -   bar {
        // ...
      }

      if foo,
    +   bar
    + {
        // ...
      }
    ```

    ```diff
      guard foo,
    -   bar else {
        // ...
      }

      guard foo,
    +   bar else
    + {
        // ...
      }
    ```

    ```diff
      func foo(
        bar: Int,
    -   baz: Int) {
        // ...
      }

      func foo(
        bar: Int,
    +   baz: Int)
    + {
        // ...
      }
    ```

    ```diff
      class Foo: NSObject,
    -   BarProtocol {
        // ...
      }

      class Foo: NSObject,
    +   BarProtocol
    + {
        // ...
      }
    ```
    """

    let leadingDelimiters = """
    ```diff
    - guard let foo = maybeFoo // first
    -     , let bar = maybeBar else { ... }

    + guard let foo = maybeFoo, // first
    +      let bar = maybeBar else { ... }
    ```
    """

    let wrapAttributes = """
    `--funcattributes prev-line`

    ```diff
    - @objc func foo() {}

    + @objc
    + func foo() { }
    ```

    `--funcattributes same-line`

    ```diff
    - @objc
    - func foo() { }

    + @objc func foo() {}
    ```

    `--typeattributes prev-line`

    ```diff
    - @objc class Foo {}

    + @objc
    + class Foo { }
    ```

    `--typeattributes same-line`

    ```diff
    - @objc
    - enum Foo { }

    + @objc enum Foo {}
    ```
    """

    let preferKeyPath = """
    ```diff
    - let barArray = fooArray.map { $0.bar }
    + let barArray = fooArray.map(\\.bar)

    - let barArray = fooArray.compactMap { $0.optionalBar }
    + let barArray = fooArray.compactMap(\\.optionalBar)
    ```
    """

    let organizeDeclarations = """
    ```diff
      public class Foo {
    -     public func c() -> String {}
    -
    -     public let a: Int = 1
    -     private let g: Int = 2
    -     let e: Int = 2
    -     public let b: Int = 3
    -
    -     public func d() {}
    -     func f() {}
    -     init() {}
    -     deinit() {}
     }

      public class Foo {
    +
    +     // MARK: Lifecycle
    +
    +     init() {}
    +     deinit() {}
    +
    +     // MARK: Public
    +
    +     public let a: Int = 1
    +     public let b: Int = 3
    +
    +     public func c() -> String {}
    +     public func d() {}
    +
    +     // MARK: Internal
    +
    +     let e: Int = 2
    +
    +     func f() {}
    +
    +     // MARK: Private
    +
    +     private let g: Int = 2
    +
     }
    ```
    """

    let extensionAccessControl = """
    `--extensionacl on-extension` (default)

    ```diff
    - extension Foo {
    -     public func bar() {}
    -     public func baz() {}
      }

    + public extension Foo {
    +     func bar() {}
    +     func baz() {}
      }
    ```

    `--extensionacl on-declarations`

    ```diff
    - public extension Foo {
    -     func bar() {}
    -     func baz() {}
    -     internal func quux() {}
      }

    + extension Foo {
    +     public func bar() {}
    +     public func baz() {}
    +     func quux() {}
      }
    ```
    """

    let markTypes = """
    ```diff
    + // MARK: - FooViewController
    +
     final class FooViewController: UIViewController { }

    + // MARK: UICollectionViewDelegate
    +
     extension FooViewController: UICollectionViewDelegate { }

    + // MARK: - String + FooProtocol
    +
     extension String: FooProtocol { }
    ```
    """

    let assertionFailures = """
    ```diff
    - assert(false)
    + assertionFailure()
    ```

    ```diff
    - assert(false, "message", 2, 1)
    + assertionFailure("message", 2, 1)
    ```

    ```diff
    - precondition(false, "message", 2, 1)
    + preconditionFailure("message", 2, 1)
    ```
    """

    let acronyms = """
    ```diff
    - let destinationUrl: URL
    - let urlRouter: UrlRouter
    - let screenId: String
    - let entityUuid: UUID

    + let destinationURL: URL
    + let urlRouter: URLRouter
    + let screenID: String
    + let entityUUID: UUID
    ```
    """

    let blockComments = """
    ```diff
    - /*
    -  * foo
    -  * bar
    -  */

    + // foo
    + // bar
    ```

    ```diff
    - /**
    -  * foo
    -  * bar
    -  */

    + /// foo
    + /// bar
    ```
    """

    let redundantClosure = """
    ```diff
    - let foo = { Foo() }()
    + let foo = Foo()
    ```

    ```diff
    - lazy var bar = {
    -     Bar(baaz: baaz,
    -         quux: quux)
    - }()
    + lazy var bar = Bar(baaz: baaz,
    +                    quux: quux)
    ```
    """

    let sortDeclarations = """
    ```diff
      // swiftformat:sort
      enum FeatureFlags {
    -     case upsellB
    -     case fooFeature
    -     case barFeature
    -     case upsellA(
    -         fooConfiguration: Foo,
    -         barConfiguration: Bar)
    +     case barFeature
    +     case fooFeature
    +     case upsellA(
    +         fooConfiguration: Foo,
    +         barConfiguration: Bar)
    +     case upsellB
      }

      enum FeatureFlags {
          // swiftformat:sort:begin
    -     case upsellB
    -     case fooFeature
    -     case barFeature
    -     case upsellA(
    -         fooConfiguration: Foo,
    -         barConfiguration: Bar)
    +     case barFeature
    +     case fooFeature
    +     case upsellA(
    +         fooConfiguration: Foo,
    +         barConfiguration: Bar)
    +     case upsellB
          // swiftformat:sort:end

          var anUnsortedProperty: Foo {
              Foo()
          }
      }
    ```
    """

    let redundantOptionalBinding = """
    ```diff
    - if let foo = foo {
    + if let foo {
          print(foo)
      }

    - guard let self = self else {
    + guard let self else {
          return
      }
    ```
    """

    let opaqueGenericParameters = """
    ```diff
    - func handle<T: Fooable>(_ value: T) {
    + func handle(_ value: some Fooable) {
          print(value)
      }

    - func handle<T>(_ value: T) where T: Fooable, T: Barable {
    + func handle(_ value: some Fooable & Barable) {
          print(value)
      }

    - func handle<T: Collection>(_ value: T) where T.Element == Foo {
    + func handle(_ value: some Collection<Foo>) {
          print(value)
      }

    // With `--someAny enabled` (the default)
    - func handle<T>(_ value: T) {
    + func handle(_ value: some Any) {
          print(value)
      }
    ```
    """

    let genericExtensions = """
    ```diff
    - extension Array where Element == Foo {}
    - extension Optional where Wrapped == Foo {}
    - extension Dictionary where Key == Foo, Value == Bar {}
    - extension Collection where Element == Foo {}
    + extension Array<Foo> {}
    + extension Optional<Foo> {}
    + extension Dictionary<Key, Value> {}
    + extension Collection<Foo> {}

    // With `typeSugar` also enabled:
    - extension Array where Element == Foo {}
    - extension Optional where Wrapped == Foo {}
    - extension Dictionary where Key == Foo, Value == Bar {}
    + extension [Foo] {}
    + extension Foo? {}
    + extension [Key: Value] {}

    // Also supports user-defined types!
    - extension LinkedList where Element == Foo {}
    - extension Reducer where
    -     State == FooState,
    -     Action == FooAction,
    -     Environment == FooEnvironment {}
    + extension LinkedList<Foo> {}
    + extension Reducer<FooState, FooAction, FooEnvironment> {}
    ```
    """

    let docComments = """
    ```diff
    - // A placeholder type used to demonstrate syntax rules
    + /// A placeholder type used to demonstrate syntax rules
      class Foo {
    -     // This function doesn't really do anything
    +     /// This function doesn't really do anything
          func bar() {
    -         /// TODO: implement Foo.bar() algorithm
    +         // TODO: implement Foo.bar() algorithm
          }
      }
    ```
    """

    let fileHeader = """
    You can use the following tokens in the text:

    Token | Description
    --- | ---
    `{file}` | File name
    `{year}` | Current year
    `{created}` | File creation date
    `{created.year}` | File creation year

    **Example**:

    `--header \\n {file}\\n\\n Copyright © {created.year} CompanyName.\\n`

    ```diff
    - // SomeFile.swift

    + //
    + //  SomeFile.swift
    + //  Copyright © 2023 CompanyName.
    + //
    ```
    """

    let conditionalAssignment = """
    ```diff
    - let foo: String
    - if condition {
    + let foo = if condition {
    -     foo = "foo"
    +     "foo"
      } else {
    -     bar = "bar"
    +     "bar"
      }
    ```

    ```diff
    - let foo: String
    - switch condition {
    + let foo = switch condition {
      case true:
    -     foo = "foo"
    +     "foo"
      case false:
    -     foo = "bar"
    +     "bar"
      }
    ```
    """
}
