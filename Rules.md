# Default Rules (enabled by default)

* [andOperator](#andOperator)
* [anyObjectProtocol](#anyObjectProtocol)
* [assertionFailures](#assertionFailures)
* [blankLinesAroundMark](#blankLinesAroundMark)
* [blankLinesAtEndOfScope](#blankLinesAtEndOfScope)
* [blankLinesAtStartOfScope](#blankLinesAtStartOfScope)
* [blankLinesBetweenScopes](#blankLinesBetweenScopes)
* [braces](#braces)
* [conditionalAssignment](#conditionalAssignment)
* [consecutiveBlankLines](#consecutiveBlankLines)
* [consecutiveSpaces](#consecutiveSpaces)
* [duplicateImports](#duplicateImports)
* [elseOnSameLine](#elseOnSameLine)
* [emptyBraces](#emptyBraces)
* [enumNamespaces](#enumNamespaces)
* [extensionAccessControl](#extensionAccessControl)
* [fileHeader](#fileHeader)
* [genericExtensions](#genericExtensions)
* [hoistAwait](#hoistAwait)
* [hoistPatternLet](#hoistPatternLet)
* [hoistTry](#hoistTry)
* [indent](#indent)
* [initCoderUnavailable](#initCoderUnavailable)
* [leadingDelimiters](#leadingDelimiters)
* [linebreakAtEndOfFile](#linebreakAtEndOfFile)
* [linebreaks](#linebreaks)
* [modifierOrder](#modifierOrder)
* [numberFormatting](#numberFormatting)
* [opaqueGenericParameters](#opaqueGenericParameters)
* [preferKeyPath](#preferKeyPath)
* [redundantBackticks](#redundantBackticks)
* [redundantBreak](#redundantBreak)
* [redundantClosure](#redundantClosure)
* [redundantExtensionACL](#redundantExtensionACL)
* [redundantFileprivate](#redundantFileprivate)
* [redundantGet](#redundantGet)
* [redundantInit](#redundantInit)
* [redundantLet](#redundantLet)
* [redundantLetError](#redundantLetError)
* [redundantNilInit](#redundantNilInit)
* [redundantObjc](#redundantObjc)
* [redundantOptionalBinding](#redundantOptionalBinding)
* [redundantParens](#redundantParens)
* [redundantPattern](#redundantPattern)
* [redundantRawValues](#redundantRawValues)
* [redundantReturn](#redundantReturn)
* [redundantSelf](#redundantSelf)
* [redundantType](#redundantType)
* [redundantVoidReturnType](#redundantVoidReturnType)
* [semicolons](#semicolons)
* [sortDeclarations](#sortDeclarations)
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
* [wrapSingleLineComments](#wrapSingleLineComments)
* [yodaConditions](#yodaConditions)

# Opt-in Rules (disabled by default)

* [acronyms](#acronyms)
* [blankLineAfterImports](#blankLineAfterImports)
* [blankLinesBetweenImports](#blankLinesBetweenImports)
* [blockComments](#blockComments)
* [docComments](#docComments)
* [isEmpty](#isEmpty)
* [markTypes](#markTypes)
* [organizeDeclarations](#organizeDeclarations)
* [sortedSwitchCases](#sortedSwitchCases)
* [wrapConditionalBodies](#wrapConditionalBodies)
* [wrapEnumCases](#wrapEnumCases)
* [wrapSwitchCases](#wrapSwitchCases)

# Deprecated Rules (do not use)

* [specifiers](#specifiers)

----------

## acronyms

Capitalizes acronyms when the first character is capitalized.

Option | Description
--- | ---
`--acronyms` | Acronyms to auto-capitalize. Defaults to "ID,URL,UUID".

<details>
<summary>Examples</summary>

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

</details>
<br/>

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

## assertionFailures

Changes all instances of assert(false, ...) to assertionFailure(...)
and precondition(false, ...) to preconditionFailure(...).

<details>
<summary>Examples</summary>

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

</details>
<br/>

## blankLineAfterImports

Insert blank line after import statements.

<details>
<summary>Examples</summary>

```diff
  import A
  import B
  @testable import D
+
  class Foo {
    // foo
  }
```

</details>
<br/>

## blankLinesAroundMark

Insert blank line before and after `MARK:` comments.

Option | Description
--- | ---
`--lineaftermarks` | Insert blank line after "MARK:": "true" (default) or "false"

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

Option | Description
--- | ---
`--typeblanklines` | "remove" (default) or "preserve" blank lines from types

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

## blankLinesBetweenImports

Remove blank lines between import statements.

<details>
<summary>Examples</summary>

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

## blockComments

Changes block comments to single line comments.

<details>
<summary>Examples</summary>

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

## conditionalAssignment

Assign properties using if / switch expressions.

<details>
<summary>Examples</summary>

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

## docComments

Use doc comments for comments preceding declarations.

<details>
<summary>Examples</summary>

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
`--guardelse` | Guard else: "same-line", "next-line" or "auto" (default)

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

Option | Description
--- | ---
`--emptybraces` | Empty braces: "no-space" (default), "spaced" or "linebreak"

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

## enumNamespaces

Converts types used for hosting only static members into enums (an empty enum is
the canonical way to create a namespace in Swift as it can't be instantiated).

Option | Description
--- | ---
`--enumnamespaces` | Change type to enum: "always" (default) or "structs-only"

## extensionAccessControl

Configure the placement of an extension's access control keyword.

Option | Description
--- | ---
`--extensionacl` | Place ACL "on-extension" (default) or "on-declarations"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## fileHeader

Use specified source file header template for all files.

Option | Description
--- | ---
`--header` | Header comments: "strip", "ignore", or the text you wish use

<details>
<summary>Examples</summary>

You can use the following tokens in the text:

Token | Description
--- | ---
`{file}` | File name
`{year}` | Current year
`{created}` | File creation date
`{created.year}` | File creation year

**Example**:

`--header \n {file}\n\n Copyright © {created.year} CompanyName.\n`

```diff
- // SomeFile.swift

+ //
+ //  SomeFile.swift
+ //  Copyright © 2023 CompanyName.
+ //
```

</details>
<br/>

## genericExtensions

When extending generic types, use angle brackets (`extension Array<Foo>`)
instead of generic type constraints (`extension Array where Element == Foo`).

Option | Description
--- | ---
`--generictypes` | Semicolon-delimited list of generic types and type parameters

<details>
<summary>Examples</summary>

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

</details>
<br/>

## hoistAwait

Move inline `await` keyword(s) to start of expression.

Option | Description
--- | ---
`--asynccapturing` | List of functions with async @autoclosure arguments

<details>
<summary>Examples</summary>

```diff
- greet(await forename, await surname)
+ await greet(forename, surname)
```

```diff
- let foo = String(try await getFoo())
+ let foo = await String(try getFoo())
```

</details>
<br/>

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

## hoistTry

Move inline `try` keyword(s) to start of expression.

Option | Description
--- | ---
`--throwcapturing` | List of functions with throwing @autoclosure arguments

<details>
<summary>Examples</summary>

```diff
- foo(try bar(), try baz())
+ try foo(bar(), baz())
```

```diff
- let foo = String(try await getFoo())
+ let foo = try String(await getFoo())
```

</details>
<br/>

## indent

Indent code in accordance with the scope level.

Option | Description
--- | ---
`--indent` | Number of spaces to indent, or "tab" to use tabs
`--tabwidth` | The width of a tab character. Defaults to "unspecified"
`--smarttabs` | Align code independently of tab width. defaults to "enabled"
`--indentcase` | Indent cases inside a switch: "true" or "false" (default)
`--ifdef` | #if indenting: "indent" (default), "no-indent" or "outdent"
`--xcodeindentation` | Match Xcode indenting: "enabled" or "disabled" (default)
`--indentstrings` | Indent multiline strings: "false" (default) or "true"

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

## initCoderUnavailable

Add `@available(*, unavailable)` attribute to required `init(coder:)` when
it hasn't been implemented.

<details>
<summary>Examples</summary>

```diff
+ @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

## markTypes

Adds a mark comment before top-level types and extensions.

Option | Description
--- | ---
`--marktypes` | Mark types "always" (default), "never", "if-not-empty"
`--typemark` | Template for type mark comments. Defaults to "MARK: - %t"
`--markextensions` | Mark extensions "always" (default), "never", "if-not-empty"
`--extensionmark` | Mark for standalone extensions. Defaults to "MARK: - %t + %c"
`--groupedextension` | Mark for extension grouped with extended type. ("MARK: %c")

<details>
<summary>Examples</summary>

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

</details>
<br/>

## modifierOrder

Use consistent ordering for member modifiers.

Option | Description
--- | ---
`--modifierorder` | Comma-delimited list of modifiers in preferred order

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

## numberFormatting

Use consistent grouping for numeric literals. Groups will be separated by `_`
delimiters to improve readability. For each numeric type you can specify a group
size (the number of digits in each group) and a threshold (the minimum number of
digits in a number before grouping is applied).

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

## opaqueGenericParameters

Use opaque generic parameters (`some Protocol`) instead of generic parameters
with constraints (`T where T: Protocol`, etc) where equivalent. Also supports
primary associated types for common standard library types, so definitions like
`T where T: Collection, T.Element == Foo` are updated to `some Collection<Foo>`.

Option | Description
--- | ---
`--someAny` | Use `some Any` types: "true" (default) or "false"

<details>
<summary>Examples</summary>

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

</details>
<br/>

## organizeDeclarations

Organizes declarations within class, struct, enum, actor, and extension bodies.

Option | Description
--- | ---
`--categorymark` | Template for category mark comments. Defaults to "MARK: %c"
`--markcategories` | Insert MARK comments between categories (true by default)
`--beforemarks` | Declarations placed before first mark (e.g. `typealias,struct`)
`--lifecycle` | Names of additional Lifecycle methods (e.g. `viewDidLoad`)
`--organizetypes` | Declarations to organize (default: `class,actor,struct,enum`)
`--structthreshold` | Minimum line count to organize struct body. Defaults to 0
`--classthreshold` | Minimum line count to organize class body. Defaults to 0
`--enumthreshold` | Minimum line count to organize enum body. Defaults to 0
`--extensionlength` | Minimum line count to organize extension body. Defaults to 0

<details>
<summary>Examples</summary>

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

</details>
<br/>

## preferKeyPath

Convert trivial `map { $0.foo }` closures to keyPath-based syntax.

<details>
<summary>Examples</summary>

```diff
- let barArray = fooArray.map { $0.bar }
+ let barArray = fooArray.map(\.bar)

- let barArray = fooArray.compactMap { $0.optionalBar }
+ let barArray = fooArray.compactMap(\.optionalBar)
```

</details>
<br/>

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

## redundantClosure

Removes redundant closures bodies, containing a single statement,
which are called immediately.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantExtensionACL

Remove redundant access control modifiers.

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

## redundantOptionalBinding

Removes redundant identifiers in optional binding conditions.

<details>
<summary>Examples</summary>

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

## redundantType

Remove redundant type from variable declarations.

Option | Description
--- | ---
`--redundanttype` | "inferred", "explicit", or "infer-locals-only" (default)

<details>
<summary>Examples</summary>

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

</details>
<br/>

## redundantVoidReturnType

Remove explicit `Void` return type.

Option | Description
--- | ---
`--closurevoid` | Closure void returns: "remove" (default) or "preserve"

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

## sortDeclarations

Sorts the body of declarations with // swiftformat:sort
and declarations between // swiftformat:sort:begin and
// swiftformat:sort:end comments.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## sortedImports

Sort import statements alphabetically.

Option | Description
--- | ---
`--importgrouping` | "testable-first/last", "alpha" (default) or "length"

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

## sortedSwitchCases

Sorts switch cases alphabetically.

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
`--ranges` | Spacing for ranges: "spaced" (default) or "no-space"
`--typedelimiter` | "trailing" (default) or "leading-trailing"

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

Use consistent ordering for member modifiers.

*Note: specifiers rule is deprecated. Use modifierOrder instead.*

## strongOutlets

Remove `weak` modifier from `@IBOutlet` properties.

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
`--nevertrailing` | List of functions that should never use trailing closures

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
`--shortoptionals` | Use ? for optionals "always" (default) or "except-properties"

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
`--voidtype` | How void types are represented: "void" (default) or "tuple"

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

```diff
- callback = { _ in Void() }
+ callback = { _ in () }
```

</details>
<br/>

## wrap

Wrap lines that exceed the specified maximum width.

Option | Description
--- | ---
`--maxwidth` | Maximum length of a line before wrapping. defaults to "none"
`--nowrapoperators` | Comma-delimited list of operators that shouldn't be wrapped
`--assetliterals` | Color/image literal width. "actual-width" or "visual-width"
`--wrapternary` | Wrap ternary operators: "default", "before-operators"

## wrapArguments

Align wrapped function arguments or collection elements.

Option | Description
--- | ---
`--wraparguments` | Wrap all arguments: "before-first", "after-first", "preserve"
`--wrapparameters` | Wrap func params: "before-first", "after-first", "preserve"
`--wrapcollections` | Wrap array/dict: "before-first", "after-first", "preserve"
`--closingparen` | Closing paren position: "balanced" (default) or "same-line"
`--wrapreturntype` | Wrap return type: "if-multiline", "preserve" (default)
`--wrapconditions` | Wrap conditions: "before-first", "after-first", "preserve"
`--wraptypealiases` | Wrap typealiases: "before-first", "after-first", "preserve"
`--wrapeffects` | Wrap effects: "if-multiline", "never", "preserve"
`--conditionswrap` | Wrap conditions as Xcode 12:"auto", "always", "disabled"

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

`--conditionswrap auto`:

```diff
- guard let foo = foo, let bar = bar, let third = third
+ guard let foo = foo,
+       let bar = bar,
+       let third = third
  else {}
```


</details>
<br/>

## wrapAttributes

Wrap @attributes onto a separate line, or keep them on the same line.

Option | Description
--- | ---
`--funcattributes` | Function @attributes: "preserve", "prev-line", or "same-line"
`--typeattributes` | Type @attributes: "preserve", "prev-line", or "same-line"
`--varattributes` | Property @attributes: "preserve", "prev-line", or "same-line"

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

## wrapConditionalBodies

Wrap the bodies of inline conditional statements onto a new line.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## wrapEnumCases

Writes one enum case per line.

Option | Description
--- | ---
`--wrapenumcases` | Wrap enum cases: "always" (default) or "with-values"

<details>
<summary>Examples</summary>

```diff
  enum Foo {
-   case bar, baz
  }

  enum Foo {
+   case bar
+   case baz
  }
```

</details>
<br/>

## wrapMultilineStatementBraces

Wrap the opening brace of multiline statements.

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

</details>
<br/>

## wrapSingleLineComments

Wrap single line `//` comments that exceed the specified `--maxwidth`.

## wrapSwitchCases

Writes one switch case per line.

<details>
<summary>Examples</summary>

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

</details>
<br/>

## yodaConditions

Prefer constant values to be on the right-hand-side of expressions.

Option | Description
--- | ---
`--yodaswap` | Swap yoda values: "always" (default) or "literals-only"
