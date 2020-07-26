# Rules

* [andOperator](#andOperator)
* [anyObjectProtocol](#anyObjectProtocol)
* [blankLinesAroundMark](#blankLinesAroundMark)
* [blankLinesAtEndOfScope](#blankLinesAtEndOfScope)
* [blankLinesAtStartOfScope](#blankLinesAtStartOfScope)
* [blankLinesBetweenScopes](#blankLinesBetweenScopes)
* [braces](#braces)
* [consecutiveBlankLines](#consecutiveBlankLines)
* [consecutiveSpaces](#consecutiveSpaces)
* [duplicateImports](#duplicateImports)
* [elseOnSameLine](#elseOnSameLine)
* [emptyBraces](#emptyBraces)
* [fileHeader](#fileHeader)
* [hoistPatternLet](#hoistPatternLet)
* [indent](#indent)
* [isEmpty](#isEmpty)
* [leadingDelimiters](#leadingDelimiters)
* [linebreakAtEndOfFile](#linebreakAtEndOfFile)
* [linebreaks](#linebreaks)
* [numberFormatting](#numberFormatting)
* [ranges *(deprecated)*](#ranges)
* [redundantBackticks](#redundantBackticks)
* [redundantBreak](#redundantBreak)
* [redundantExtensionACL](#redundantExtensionACL)
* [redundantFileprivate](#redundantFileprivate)
* [redundantGet](#redundantGet)
* [redundantInit](#redundantInit)
* [redundantLet](#redundantLet)
* [redundantLetError](#redundantLetError)
* [redundantNilInit](#redundantNilInit)
* [redundantObjc](#redundantObjc)
* [redundantParens](#redundantParens)
* [redundantPattern](#redundantPattern)
* [redundantRawValues](#redundantRawValues)
* [redundantReturn](#redundantReturn)
* [redundantSelf](#redundantSelf)
* [redundantVoidReturnType](#redundantVoidReturnType)
* [semicolons](#semicolons)
* [sortedImports](#sortedImports)
* [spaceAroundBraces](#spaceAroundBraces)
* [spaceAroundBrackets](#spaceAroundBrackets)
* [spaceAroundComments](#spaceAroundComments)
* [spaceAroundGenerics](#spaceAroundGenerics)
* [spaceAroundOperators](#spaceAroundOperators)
* [spaceAroundParens](#spaceAroundParens)
* [spaceInsideBraces](#spaceInsideBraces)
* [spaceInsideBrackets](#spaceInsideBrackets)
* [spaceInsideComments](#spaceInsideComments)
* [spaceInsideGenerics](#spaceInsideGenerics)
* [spaceInsideParens](#spaceInsideParens)
* [specifiers](#specifiers)
* [strongOutlets](#strongOutlets)
* [strongifiedSelf](#strongifiedSelf)
* [todos](#todos)
* [trailingClosures](#trailingClosures)
* [trailingCommas](#trailingCommas)
* [trailingSpace](#trailingSpace)
* [typeSugar](#typeSugar)
* [unusedArguments](#unusedArguments)
* [void](#void)
* [wrap](#wrap)
* [wrapArguments](#wrapArguments)
* [wrapAttributes](#wrapAttributes)
* [wrapMultilineStatementBraces](#wrapMultilineStatementBraces)
* [yodaConditions](#yodaConditions)

----------

## andOperator

Prefer comma over `&&` in `if`, `guard` or `while` conditions.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## anyObjectProtocol

Prefer `AnyObject` over `class` in protocol definitions.

<details>
<summary>Examples</summary>

```diff
- protocol Foo: class {}
+ protocol Foo: AnyObject {}
```

**NOTE:** The guideline to use `AnyObject` instead of `class` was only
introduced in Swift 4.1, so the `anyObjectProtocol` rule is disabled unless the
swift version is set to 4.1 or above.

</details>
<br/>

## blankLinesAroundMark

Insert blank line before and after `MARK:` comments.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## blankLinesAtEndOfScope

Remove trailing blank line at the end of a scope.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## blankLinesAtStartOfScope

Remove leading blank line at the start of a scope.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## blankLinesBetweenScopes

Insert blank line before class, struct, enum, extension, protocol or function
declarations.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## braces

Wrap braces in accordance with selected style (K&R or Allman).

Option | Description
--- | ---
`--allman` | Use allman indentation style: "true" or "false" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>

## consecutiveBlankLines

Replace consecutive blank lines with a single blank line.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## consecutiveSpaces

Replace consecutive spaces with a single space.

<details>
<summary>Examples</summary>

```diff
- let     foo = 5
+ let foo = 5
```

</details>
<br/>

## duplicateImports

Remove duplicate import statements.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## elseOnSameLine

Place `else`, `catch` or `while` keyword in accordance with current style (same or
next line).

Option | Description
--- | ---
`--elseposition` | Placement of else/catch: "same-line" (default) or "next-line"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## emptyBraces

Remove whitespace inside empty braces.

<details>
<summary>Examples</summary>

```diff
- func foo() {
-
- }

+ func foo() {}
```

</details>
<br/>

## fileHeader

Use specified source file header template for all files.

Option | Description
--- | ---
`--header` | Header comments: "strip", "ignore", or the text you wish use

## hoistPatternLet

Reposition `let` or `var` bindings within pattern.

Option | Description
--- | ---
`--patternlet` | let/var placement in patterns: "hoist" (default) or "inline"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## indent

Indent code in accordance with the scope level.

Option | Description
--- | ---
`--indent` | Number of spaces to indent, or "tab" to use tabs
`--tabwidth` | The width of a tab character. Defaults to "unspecified"
`--indentcase` | Indent cases inside a switch: "true" or "false" (default)
`--ifdef` | #if indenting: "indent" (default), "no-indent" or "outdent"
`--xcodeindentation` | Xcode indent guard/enum: "enabled" or "disabled" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>

## isEmpty

Prefer `isEmpty` over comparing `count` against zero.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## leadingDelimiters

Move leading delimiters to the end of the previous line.

<details>
<summary>Examples</summary>

```diff
- guard let foo = maybeFoo // first
-     , let bar = maybeBar else { ... }

+ guard let foo = maybeFoo, // first
+      let bar = maybeBar else { ... }
```

</details>
<br/>

## linebreakAtEndOfFile

Add empty blank line at end of file.

## linebreaks

Use specified linebreak character for all linebreaks (CR, LF or CRLF).

Option | Description
--- | ---
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

## numberFormatting

Use consistent grouping for numeric literals.

Option | Description
--- | ---
`--decimalgrouping` | Decimal grouping,threshold (default: 3,6) or "none", "ignore"
`--binarygrouping` | Binary grouping,threshold (default: 4,8) or "none", "ignore"
`--octalgrouping` | Octal grouping,threshold (default: 4,8) or "none", "ignore"
`--hexgrouping` | Hex grouping,threshold (default: 4,8) or "none", "ignore"
`--fractiongrouping` | Group digits after '.': "enabled" or "disabled" (default)
`--exponentgrouping` | Group exponent digits: "enabled" or "disabled" (default)
`--hexliteralcase` | Casing for hex literals: "uppercase" (default) or "lowercase"
`--exponentcase` | Case of 'e' in numbers: "lowercase" or "uppercase" (default)

<details>
<summary>Examples</summary>

```diff
- let color = 0xFF77A5
+ let color = 0xff77a5
```

```diff
- let big = 123456.123
+ let big = 123_456.123
```

</details>
<br/>

## ranges

Add or remove space around range operators.

*Note: ranges rule is deprecated. Use spaceAroundOperators instead.*

## redundantBackticks

Remove redundant backticks around identifiers.

<details>
<summary>Examples</summary>

```diff
- let `infix` = bar
+ let infix = bar
```

```diff
- func foo(with `default`: Int) {}
+ func foo(with default: Int) {}
```

</details>
<br/>

## redundantBreak

Remove redundant `break` in switch case.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantExtensionACL

Remove redundant access control specifiers.

<details>
<summary>Examples</summary>

```diff
  public extension URL {
-   public func queryParameter(_ name: String) -> String { ... }
  }

  public extension URL {
+   func queryParameter(_ name: String) -> String { ... }
  }
```

</details>
<br/>

## redundantFileprivate

Prefer `private` over `fileprivate` where equivalent.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantGet

Remove unneeded `get` clause inside computed properties.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantInit

Remove explicit `init` if not required.

<details>
<summary>Examples</summary>

```diff
- String.init("text")
+ String("text")
```

</details>
<br/>

## redundantLet

Remove redundant `let`/`var` from ignored variables.

<details>
<summary>Examples</summary>

```diff
- let _ = foo()
+ _ = foo()
```

</details>
<br/>

## redundantLetError

Remove redundant `let error` from `catch` clause.

<details>
<summary>Examples</summary>

```diff
- do { ... } catch let error { log(error) }
+ do { ... } catch { log(error) }
```

</details>
<br/>

## redundantNilInit

Remove redundant `nil` default value (Optional vars are nil by default).

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantObjc

Remove redundant `@objc` annotations.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantParens

Remove redundant parentheses.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantPattern

Remove redundant pattern matching parameter syntax.

<details>
<summary>Examples</summary>

```diff
- if case .foo(_, _) = bar {}
+ if case .foo = bar {}
```

```diff
- let (_, _) = bar
+ let _ = bar
```

</details>
<br/>

## redundantRawValues

Remove redundant raw string values for enum cases.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantReturn

Remove unneeded `return` keyword.

<details>
<summary>Examples</summary>

```diff
- array.filter { return $0.foo == bar }
+ array.filter { $0.foo == bar }
```

</details>
<br/>

## redundantSelf

Insert/remove explicit `self` where applicable.

Option | Description
--- | ---
`--self` | Explicit self: "insert", "remove" (default) or "init-only"
`--selfrequired` | Comma-delimited list of functions with @autoclosure arguments

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantVoidReturnType

Remove explicit `Void` return type.

<details>
<summary>Examples</summary>

```diff
- func foo() -> Void {
    // returns nothing
  }

+ func foo() {
    // returns nothing
  }
```

</details>
<br/>

## semicolons

Remove semicolons.

Option | Description
--- | ---
`--semicolons` | Allow semicolons: "never" or "inline" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>

## sortedImports

Sort import statements alphabetically.

Option | Description
--- | ---
`--importgrouping` | "testable-top", "testable-bottom" or "alphabetized" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>

## spaceAroundBraces

Add or remove space around curly braces.

<details>
<summary>Examples</summary>

```diff
- foo.filter{ return true }.map{ $0 }
+ foo.filter { return true }.map { $0 }
```

```diff
- foo( {} )
+ foo({})
```

</details>
<br/>

## spaceAroundBrackets

Add or remove space around square brackets.

<details>
<summary>Examples</summary>

```diff
- foo as[String]
+ foo as [String]
```

```diff
- foo = bar [5]
+ foo = bar[5]
```

</details>
<br/>

## spaceAroundComments

Add space before and/or after comments.

<details>
<summary>Examples</summary>

```diff
- let a = 5// assignment
+ let a = 5 // assignment
```

```diff
- func foo() {/* ... */}
+ func foo() { /* ... */ }
```

</details>
<br/>

## spaceAroundGenerics

Remove space around angle brackets.

<details>
<summary>Examples</summary>

```diff
- Foo <Bar> ()
+ Foo<Bar>()
```

</details>
<br/>

## spaceAroundOperators

Add or remove space around operators or delimiters.

Option | Description
--- | ---
`--operatorfunc` | Spacing for operator funcs: "spaced" (default) or "no-space"
`--nospaceoperators` | Comma-delimited list of operators without surrounding space

<details>
<summary>Examples</summary>

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

</details>
<br/>

## spaceAroundParens

Add or remove space around parentheses.

<details>
<summary>Examples</summary>

```diff
- init (foo)
+ init(foo)
```

```diff
- switch(x){
+ switch (x) {
```

</details>
<br/>

## spaceInsideBraces

Add space inside curly braces.

<details>
<summary>Examples</summary>

```diff
- foo.filter {return true}
+ foo.filter { return true }
```

</details>
<br/>

## spaceInsideBrackets

Remove space inside square brackets.

<details>
<summary>Examples</summary>

```diff
- [ 1, 2, 3 ]
+ [1, 2, 3]
```

</details>
<br/>

## spaceInsideComments

Add leading and/or trailing space inside comments.

<details>
<summary>Examples</summary>

```diff
- let a = 5 //assignment
+ let a = 5 // assignment
```

```diff
- func foo() { /*...*/ }
+ func foo() { /* ... */ }
```

</details>
<br/>

## spaceInsideGenerics

Remove space inside angle brackets.

<details>
<summary>Examples</summary>

```diff
- Foo< Bar, Baz >
+ Foo<Bar, Baz>
```

</details>
<br/>

## spaceInsideParens

Remove space inside parentheses.

<details>
<summary>Examples</summary>

```diff
- ( a, b)
+ (a, b)
```

</details>
<br/>

## specifiers

Use consistent ordering for member specifiers.

Option | Description
--- | ---
`--specifierorder` | Comma-delimited list of specifiers in preferred order

<details>
<summary>Examples</summary>

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

</details>
<br/>

## strongOutlets

Remove `weak` specifier from `@IBOutlet` properties.

<details>
<summary>Examples</summary>

As per Apple's recommendation
(https://developer.apple.com/videos/play/wwdc2015/407/ @ 32:30).

```diff
- @IBOutlet weak var label: UILabel!
+ @IBOutlet var label: UILabel!
```

</details>
<br/>

## strongifiedSelf

Remove backticks around `self` in Optional unwrap expressions.

<details>
<summary>Examples</summary>

```diff
- guard let `self` = self else { return }
+ guard let self = self else { return }
```

**NOTE:** assignment to un-escaped `self` is only supported in Swift 4.2 and
above, so the `strongifiedSelf` rule is disabled unless the Swift version is
set to 4.2 or above.

</details>
<br/>

## todos

Use correct formatting for `TODO:`, `MARK:` or `FIXME:` comments.

<details>
<summary>Examples</summary>

```diff
- /* TODO fix this properly */
+ /* TODO: fix this properly */
```

```diff
- // MARK - UIScrollViewDelegate
+ // MARK: - UIScrollViewDelegate
```

</details>
<br/>

## trailingClosures

Use trailing closure syntax where applicable.

Option | Description
--- | ---
`--trailingclosures` | Comma-delimited list of functions that use trailing closures

<details>
<summary>Examples</summary>

```diff
- DispatchQueue.main.async(execute: { ... })
+ DispatchQueue.main.async {
```

```diff
- let foo = bar.map({ ... }).joined()
+ let foo = bar.map { ... }.joined()
```

</details>
<br/>

## trailingCommas

Add or remove trailing comma from the last item in a collection literal.

Option | Description
--- | ---
`--commas` | Commas in collection literals: "always" (default) or "inline"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## trailingSpace

Remove trailing space at end of a line.

Option | Description
--- | ---
`--trimwhitespace` | Trim trailing space: "always" (default) or "nonblank-lines"

## typeSugar

Prefer shorthand syntax for Arrays, Dictionaries and Optionals.

Option | Description
--- | ---
`--shortoptionals` | Use ? for Optionals "always" (default) or "except-properties"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## unusedArguments

Mark unused function arguments with `_`.

Option | Description
--- | ---
`--stripunusedargs` | "closure-only", "unnamed-only" or "always" (default)

<details>
<summary>Examples</summary>

```diff
- func foo(bar: Int, baz: String) {
    print("Hello \(baz)")
  }

+ func foo(bar _: Int, baz: String) {
    print("Hello \(baz)")
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

</details>
<br/>

## void

Use `Void` for type declarations and `()` for values.

Option | Description
--- | ---
`--empty` | How empty values are represented: "void" (default) or "tuple"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## wrap

Wrap lines that exceed the specified maximum width.

Option | Description
--- | ---
`--maxwidth` | Maximum length of a line before wrapping. defaults to "none"
`--nowrapoperators` | Comma-delimited list of operators that shouldn't be wrapped

## wrapArguments

Align wrapped function arguments or collection elements.

Option | Description
--- | ---
`--wraparguments` | Wrap all arguments: "before-first", "after-first", "preserve"
`--wrapparameters` | Wrap func params: "before-first", "after-first", "preserve"
`--wrapcollections` | Wrap array/dict: "before-first", "after-first", "preserve"
`--closingparen` | Closing paren position: "balanced" (default) or "same-line"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## wrapAttributes

Wrap @attributes onto a separate line, or keep them on the same line.

Option | Description
--- | ---
`--funcattributes` | Function @attributes: "preserve", "prev-line", or "same-line"
`--typeattributes` | Type @attributes: "preserve", "prev-line", or "same-line"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## wrapMultilineStatementBraces

Wrap the opening brace of multiline statements (if/guard/while/func).

<details>
<summary>Examples</summary>

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

</details>
<br/>

## yodaConditions

Prefer constant values to be on the right-hand-side of expressions.
