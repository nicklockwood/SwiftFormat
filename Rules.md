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
* [linebreakAtEndOfFile](#linebreakAtEndOfFile)
* [linebreaks](#linebreaks)
* [numberFormatting](#numberFormatting)
* [ranges](#ranges)
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
* [wrapArguments](#wrapArguments)

----------

## andOperator

Replaces the `&&` operator with a comma inside `if`, `guard` and `while`
conditions.

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

Replaces `class` with `AnyObject` in protocol definitions, as recommended in
modern Swift guidelines.

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

Adds a blank line before and after each `MARK:` comment.

Option | Description
--- | ---
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Removes trailing blank lines from inside braces, brackets, parens or chevrons.

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

Removes leading blank lines from inside braces, brackets, parens or chevrons.

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

Adds a blank line before each class, struct, enum, extension, protocol or
function.

Option | Description
--- | ---
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Implements K&R or Allman-style braces.

Option | Description
--- | ---
`--allman` | Use allman indentation style: "true" or "false" (default)
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Reduces multiple sequential blank lines to a single blank line.

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

Reduces a sequence of spaces to a single space.

<details>
<summary>Examples</summary>

```diff
- let     foo = 5
+ let foo = 5
```

</details>
<br/>

## duplicateImports

Removes duplicate import statements.

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

Controls whether an `else`, `catch` or `while` keyword after a `}` appears on
the same line.

Option | Description
--- | ---
`--elseposition` | Placement of else/catch: "same-line" (default) or "next-line"
`--allman` | Use allman indentation style: "true" or "false" (default)
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Removes all white space between otherwise empty braces.

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

Allows the replacement or removal of Xcode source file comment headers.

Option | Description
--- | ---
`--header` | Header comments: "strip", "ignore", or the text you wish use
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

## hoistPatternLet

Moves `let` or `var` bindings inside patterns to the start of the expression
(or vice-versa).

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

Adjusts leading whitespace based on scope and line wrapping.

Option | Description
--- | ---
`--indent` | Number of spaces to indent, or "tab" to use tabs
`--indentcase` | Indent cases inside a switch: "true" or "false" (default)
`--comments` | Indenting of comment bodies: "indent" (default) or "ignore"
`--ifdef` | #if indenting: "indent" (default), "no-indent" or "outdent"
`--trimwhitespace` | Trim trailing space: "always" (default) or "nonblank-lines"
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Replaces `count == 0` checks with `isEmpty`, which is preferred for performance
reasons (especially for Strings where count has O(n) complexity).

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

</details>
<br/>

## linebreakAtEndOfFile

Ensures that the last line of the file is empty.

Option | Description
--- | ---
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

## linebreaks

Normalizes all linebreaks to use the same character.

Option | Description
--- | ---
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

## numberFormatting

Handles case and grouping of number literals.

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

Controls the spacing around range operators.

Option | Description
--- | ---
`--ranges` | Spacing for ranges: "spaced" (default) or "no-space"

<details>
<summary>Examples</summary>

```diff
- for i in 0..<5 {}
+ for i in 0 ..< 5 {}
```

```diff
- if (0...5).contains(i) {}
+ if (0 ... 5).contains(i) {}
```

</details>
<br/>

## redundantBackticks

Removes unnecessary escaping of identifiers using backticks, e.g. in cases
where the escaped word is not a keyword, or is not ambiguous in that context.

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

Removes redundant `break` statements from inside switch cases.

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

Removes access control level keywords from extension members when the access
level matches the extension itself.

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

Replaces `fileprivate` access control keyword with `private` when they are
equivalent, e.g. for top-level constants, functions or types within a file.

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

Removes unnecessary `get { }` clauses from inside read-only computed properties.

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

Removes unnecessary `init` when instantiating types.

<details>
<summary>Examples</summary>

```diff
- String.init("text")
+ String("text")
```

</details>
<br/>

## redundantLet

Removes redundant `let` or `var` from ignored variables in bindings (which is a
warning in Xcode).

<details>
<summary>Examples</summary>

```diff
- let _ = foo()
+ _ = foo()
```

</details>
<br/>

## redundantLetError

Removes redundant `let error` from `catch` statements, where it is declared
implicitly.

<details>
<summary>Examples</summary>

```diff
- do { ... } catch let error { log(error) }
+ do { ... } catch { log(error) }
```

</details>
<br/>

## redundantNilInit

Removes unnecessary nil initialization of Optional vars (which are nil by
default anyway).

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

Removes unnecessary `@objc` annotation from properties and functions.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantParens

Removes unnecessary parens from expressions and branch conditions.

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

Removes redundant pattern matching arguments for ignored variables.

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

Removes raw string values from enum cases when they match the case name.

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

Removes unnecessary `return` keyword from single-line closures.

<details>
<summary>Examples</summary>

```diff
- array.filter { return $0.foo == bar }
+ array.filter { $0.foo == bar }
```

</details>
<br/>

## redundantSelf

Adds or removes explicit `self` prefix from class and instance member
references.

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

Removes unnecessary `Void` return type from function declarations.

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

Removes semicolons at the end of lines, and (optionally) replaces inline
semicolons with a linebreak.

Option | Description
--- | ---
`--semicolons` | Allow semicolons: "never" or "inline" (default)
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Rearranges import statements so that they are sorted.

Option | Description
--- | ---
`--importgrouping` | "testable-top", "testable-bottom" or "alphabetized" (default)
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

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

Contextually adds or removes space around `{ ... }`.

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

Contextually adjusts the space around `[ ... ]`.

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

Adds space around `/* ... */` comments and before `//` comments, depending on
the `--comments` option (`indent` (default) or `ignore`).

<details>
<summary>Examples</summary>

```diff
- let a = 5// assignment
+ let a = 5 // assignment
```

```diff
- func foo() {/* no-op */}
+ func foo() { /* no-op */ }
```

</details>
<br/>

## spaceAroundGenerics

Removes the space around `< ... >`.

<details>
<summary>Examples</summary>

```diff
- Foo <Bar> ()
+ Foo<Bar>()
```

</details>
<br/>

## spaceAroundOperators

Contextually adjusts the space around infix operators. Also adds or removes the
space between an operator function declaration and its arguments.

Option | Description
--- | ---
`--operatorfunc` | Spacing for operator funcs: "spaced" (default) or "no-space"

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

Contextually adjusts the space around `( ... )`.

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

Adds space inside `{ ... }`.

<details>
<summary>Examples</summary>

```diff
- foo.filter {return true}
+ foo.filter { return true }
```

</details>
<br/>

## spaceInsideBrackets

Removes the space inside `[ ... ]`.

<details>
<summary>Examples</summary>

```diff
- [ 1, 2, 3 ]
+ [1, 2, 3]
```

</details>
<br/>

## spaceInsideComments

Adds a space inside `/* ... */` comments and at the start of `//` comments.

Option | Description
--- | ---
`--comments` | Indenting of comment bodies: "indent" (default) or "ignore"

<details>
<summary>Examples</summary>

```diff
- let a = 5 //assignment
+ let a = 5 // assignment
```

```diff
- func foo() { /*no-op*/ }
+ func foo() { /* no-op */ }
```

</details>
<br/>

## spaceInsideGenerics

Removes the space inside `< ... >`.

<details>
<summary>Examples</summary>

```diff
- Foo< Bar, Baz >
+ Foo<Bar, Baz>
```

</details>
<br/>

## spaceInsideParens

Removes the space inside `( ... )`.

<details>
<summary>Examples</summary>

```diff
- ( a, b)
+ (a, b)
```

</details>
<br/>

## specifiers

Normalizes the order for property/function/class specifiers (public, weak,
lazy, etc.).

<details>
<summary>Examples</summary>

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

</details>
<br/>

## strongOutlets

Removes the `weak` specifier from `@IBOutlet` properties.

<details>
<summary>Examples</summary>

As per Apple's recommendation
(https://developer.apple.com/videos/play/wwdc2015/407/).

```diff
- @IBOutlet weak var label: UILabel!
+ @IBOutlet var label: UILabel!
```

</details>
<br/>

## strongifiedSelf

Replaces `` `self` `` with `self` when using the common ``guard let `self` = self``
pattern for strongifying weak self references.

<details>
<summary>Examples</summary>

```diff
- guard let `self` = self else { return }
+ guard let self = self else { return }
```

**NOTE:** assignment to un-escaped `self` is only supported in Swift 4.2 and
above, so the `strongifiedSelf` rule is disabled unless the swift version is
set to 4.2 or above.

</details>
<br/>

## todos

Ensures that `TODO:`, `MARK:` and `FIXME:` comments include the trailing colon
(else they're ignored by Xcode).

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

Converts the last closure argument in a function call to trailing closure
syntax where possible. By default this is restricted to anonymous closure
arguments, as removing named closures can result in call-site ambiguity..

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

Adds or removes trailing commas from the last item in an array or dictionary
literal.

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

Removes the whitespace at the end of a line.

Option | Description
--- | ---
`--trimwhitespace` | Trim trailing space: "always" (default) or "nonblank-lines"

## typeSugar

Replaces Array, Dictionary and Optional types with their shorthand forms.

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

Marks unused arguments in functions and closures with `_` to make it clear they
aren't used.

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

</details>
<br/>

## void

Standardizes the use of `Void` vs an empty tuple `()`.

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

## wrapArguments

Wraps function arguments and collection literals.

Option | Description
--- | ---
`--wraparguments` | Wrap function args: "before-first", "after-first", "preserve"
`--wrapcollections` | Wrap array/dict: "before-first", "after-first", "preserve"
`--closingparen` | Closing paren position: "balanced" (default) or "same-line"
`--indent` | Number of spaces to indent, or "tab" to use tabs
`--trimwhitespace` | Trim trailing space: "always" (default) or "nonblank-lines"
`--linebreaks` | Linebreak character to use: "cr", "crlf" or "lf" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>
