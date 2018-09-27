[![Travis](https://img.shields.io/travis/nicklockwood/SwiftFormat.svg)](https://travis-ci.org/nicklockwood/SwiftFormat)
[![Coveralls](https://coveralls.io/repos/github/nicklockwood/SwiftFormat/badge.svg)](https://coveralls.io/github/nicklockwood/SwiftFormat)
[![Swift 3.4](https://img.shields.io/badge/swift-3.4-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Swift 4.2](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

Table of Contents
-----------------

- [What?](#what-is-this)
- [Why?](#why-would-i-want-to-do-that)
- [How?](#how-do-i-install-it)
    - [Command-Line Tool](#command-line-tool)
    - [Xcode Source Editor Extension](#xcode-source-editor-extension)
    - [Xcode Build Phase](#xcode-build-phase)
    - [Git Pre-Commit Hook](#git-pre-commit-hook)
    - [On CI using Danger](#on-ci-using-danger)
- [Usage](#so-what-does-swiftformat-actually-do)
    - [Options](#options)
    - [Rules](#rules)
    - [Config](#config)
    - [Linting](#linting)
- [FAQ](#faq)
- [Cache](#cache)
- [File Headers](#file-headers)
- [Known Issues](#known-issues)
- [Credits](#credits)


What is this?
----------------

SwiftFormat is a code library and command-line tool for reformatting swift code.

It applies a set of rules to the formatting and space around the code, leaving the behavior intact.


Why would I want to do that?
-----------------------------

Many programmers have a preferred style for formatting their code, and others seem entirely blind to the existing formatting conventions of a project (to the enragement of their colleagues).

When collaborating on a project, it can be helpful to agree on a common coding style, but enforcing that manually is tedious and error-prone, and can lead to bad feeling if some participants take it more seriously than others.

Having a tool to automatically enforce a common style eliminates those issues, and lets you focus on the *operation* of the code, not its presentation.


How do I install it?
---------------------

That depends. There are four ways you can use SwiftFormat:

1. As a command-line tool that you run manually, or as part of some other toolchain
2. As a Source Editor Extension that you can invoke via the Editor > SwiftFormat menu within Xcode
3. As a build phase in your Xcode project, so that it runs every time you press Cmd-R or Cmd-B, or
4. As a Git pre-commit hook, so that it runs on any files you've changed before you check them in


Command-line tool
-------------------

**Installation:**

You can install the `swiftformat` command-line tool using [Homebrew](http://brew.sh/). Assuming you already have Homebrew installed, just type:

```bash
> brew update
> brew install swiftformat
```

Alternatively, you can install the tool using [Mint](https://github.com/yonaskolb/Mint) as follows:

```bash
> mint install nicklockwood/SwiftFormat
```
    
And then run it using:

```bash
> mint run swiftformat
```

If you are installing SwiftFormat into your project directory, you can use [CocoaPods](https://cocoapods.org/) to automatically install the swiftformat binary along with your other pods - see the Xcode build phase instructions below for details.

If you would prefer not to use a package manager, you can build the command-line app manually:

1. open `SwiftFormat.xcodeproj` and build the `SwiftFormat (Application)` scheme.

2. Drag the `swiftformat` binary into `/usr/local/bin/` (this is a hidden folder, but you can use the Finder's `Go > Go to Folder...` menu to open it).

3. Open `~/.bash_profile` in your favorite text editor (this is a hidden file, but you can type `open ~/.bash_profile` in the terminal to open it).

4. Add the following line to the file: `alias swiftformat="/usr/local/bin/swiftformat --indent 4"` (you can omit the `--indent 4`, or replace it with something else. Run `swiftformat --help` to see the available options).

5. Save the `.bash_profile` file and run the command `source ~/.bash_profile` for the changes to take effect.

**Usage:**

If you followed the installation instructions above, you can now just type

```bash
> swiftformat .
```
    
(that's a space and then a period after the command) in the terminal to format any Swift files in the current directory.

**WARNING:** `swiftformat .` will overwrite any Swift files it finds in the current directory, and any subfolders therein. If you run it from your home directory, it will probably reformat every Swift file on your hard drive.

To use it safely, do the following:

1. Choose a file or directory that you want to apply the changes to.

2. Make sure that you have committed all your changes to that code safely in git (or whatever source control system you use).

3. (Optional) In Terminal, type `swiftformat --inferoptions "/path/to/your/code/"`. This will suggest a set of formatting options to use that match your existing project style (but you are free to ignore these and use the defaults, or your own settings if you prefer).

    The path can point to either a single Swift file or a directory of files. It can be either be absolute, or relative to the current directory. The `""` quotes around the path are optional, but if the path contains spaces then you either need to use quotes, or escape each space with `\`. You may include multiple paths separated by spaces.

4. In Terminal, type `swiftformat "/path/to/your/code/"`. The same rules apply as above with respect to paths, and multiple space-delimited paths are allowed.

    If you used `--inferoptions` to generate a suggested set of options in step 3, you should copy and paste them into the command, either before or after the path(s) to your source files.
    
    If you have created a [configuration file](#config), you can specify its path using `--config "/path/to/your/config-file/".

5. Press enter to begin formatting. Once the formatting is complete, use your source control system to check the changes, and verify that no undesirable changes have been introduced. If they have, revert the changes, tweak the options and try again.

6. (Optional) commit the changes.

Following these instructions *should* ensure that you avoid catastrophic data loss, but in the unlikely event that it wipes your hard drive, **please note that I accept no responsibility**.

If you prefer, you can also use unix pipes to include swiftformat as part of a command chain. For example, this is an alternative way to format a file:

```bash
> cat /path/to/file.swift | swiftformat --output /path/to/file.swift
```
    
Omitting the `--output /path/to/file.swift` will print the formatted file to `stdout`.


Xcode Source Editor Extension
-----------------------------

**Installation:**

You'll find the latest version of the SwiftFormat for Xcode application inside the EditorExtension folder included in the SwiftFormat repository. Drag it into your `Applications` folder, then double-click to launch it, and follow the on-screen instructions.

**NOTE:** The Extension requires Xcode 8 and macOS 10.12 Sierra or higher.

**Usage:**

In Xcode, you'll find a SwiftFormat option under the Editor menu. You can use this to format either the current selection or the whole file.

You can configure the formatting [rules](#rules) and [options](#options) used by the Xcode Source Editor Extension using the host application. There is currently no way to override these per-project, however you can import and export different configurations using the File menu. You will need to do this again each time you switch project.

The format of the configuration file is described in the [Config section](#config) below.

**Note:** SwiftFormat for Xcode cannot automatically detect changes to an imported configuration file. If you update the `.swiftformat` file for your project, you will need to manually re-import that file into SwiftFormat for Xcode in order for the Xcode Source Editor Extension to use the new configuration.


Xcode build phase
-------------------

To set up SwiftFormat as an Xcode build phase, do the following:

1. Add the `swiftformat` binary to your project directory (this is better than referencing a locally installed copy because it means that project will still compile on machines that don't have the `swiftformat` command-line tool installed). You can install the binary manually, or via [CocoaPods](https://cocoapods.org/), by adding the following line to your Podfile then running `pod install`:

    ```ruby
    pod 'SwiftFormat/CLI'
    ```

    **NOTE:** This will only install the pre-built command-line app, not the source code for the SwiftFormat framework.

2. In the Build Phases section of your project target, add a new Run Script phase before the Compile Sources step. The script should be

    ```bash
    "${SRCROOT}/path/to/swiftformat" "${SRCROOT}/path/to/your/swift/code/"
    ```
        
	Both paths should be relative to the directory containing your Xcode project. If you are installing SwiftFormat as a Cocoapod, the swiftformat path will be

    ```bash
    "${PODS_ROOT}/SwiftFormat/CommandLineTool/swiftformat"
    ```
	    
    **NOTE:** Adding this script will slightly increase your build time, and will make changes to your source files as you work on them, which can have annoying side-effects such as clearing the undo buffer. You may wish to add the script to your test target rather than your main target, so that it is invoked only when you run the unit tests, and not every time you build the app.

Alternatively, you can skip installation of the SwiftFormat pod and configure Xcode to use the locally installed swiftformat command-line tool instead by putting the following in your Run Script build phase:

```bash
if which swiftformat >/dev/null; then
  swiftformat .
else
  echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi
```

This is not recommended for shared projects however, as different team members using different versions of SwiftFormat may result in noise in the commits as code gets reformatted inconsistently.


Git pre-commit hook
---------------------

1. Follow the instructions for installing the swiftformat command-line tool.

2. Edit or create a `.git/hooks/pre-commit` file in your project folder. The .git folder is hidden but should already exist if you are using Git with your project, so open in with the terminal, or the Finder's `Go > Go to Folder...` menu.

3. Add the following line in the pre-commit file (unlike the Xcode build phase approach, this uses your locally installed version of SwiftFormat, not a separate copy in your project repository)

    ```bash
    #!/bin/bash
    git diff --diff-filter=d --staged --name-only | grep -e '\(.*\).swift$' | while read line; do
      swiftformat "${line}";
      git add "$line";
    done
    ```

4. enable the hook by typing `chmod +x .git/hooks/pre-commit` in the terminal
 
The pre-commit hook will now run whenever you run `git commit`. Running `git commit --no-verify` will skip the pre-commit hook.

**NOTE:** If you are using Git via a GUI client such as [Tower](https://www.git-tower.com), [additional steps](https://www.git-tower.com/help/mac/faq-and-tips/faq/hook-scripts) may be needed.

**NOTE (2):** Unlike the Xcode build phase approach, git pre-commit hook won't be checked in to source control, and there's no way to guarantee that all users of the project are using the same version of SwiftFormat. For a collaborative project, you might want to consider a *post*-commit hook instead, which would run on your continuous integration server.

On CI using Danger
-------------------

To setup SwiftFormat to be used by your continuous integration system using [Danger](http://danger.systems/ruby/), do the following:

1. Follow the [`instructions`](http://danger.systems/guides/getting_started.html) to setup Danger.
2. Add the [`danger-swiftformat`](https://github.com/garriguv/danger-ruby-swiftformat) plugin to your `Gemfile`.
3. Add the following to your `Dangerfile`:

    ```ruby
    swiftformat.binary_path = "/path/to/swiftformat" # optional
    swiftformat.additional_args = "--indent tab --self insert" # optional
    swiftformat.check_format(fail_on_error: true)
    ```
    
    **NOTE:** It is recommended to add the `swiftformat` binary to your project directory to ensure the same version is used each time (see the [Xcode build phase](#xcode-build-phase) instructions above).

So what does SwiftFormat actually do?
--------------------------------------

SwiftFormat first converts the source file into tokens, then iteratively applies a set of rules to the tokens to adjust the formatting. The tokens are then converted back into text.

SwiftFormat's configuration is split between **rules** and **options**. Rules are functions in the SwiftFormat library that apply changes to the code. Options are settings that control the behavior of the rules. 


Options
-------

The options available in SwiftFormat can be displayed using the `--help` command-line argument. The default value for each option is indicated in the help text.

Rules are configured by adding `--[rulename] [value]` to your command-line arguments, or by creating a [config file](#config) as explained below.

A given option may affect multiple rules. See the [Rules](#rules) section below for details about which options affect which rule.


Rules
-----

The rules used by SwiftFormat can be displayed using the `--rules` command-line argument. Rules can be either enabled or disabled. Most are enabled by default. Disabled rules are marked with "(disabled)" when using the `--rules` argument.

You can disable rules individually using `--disable` followed by a list of one or more comma-delimited rule names, or enable additional rules using `--enable` followed by the names. 

To see exactly which rules were applied to a given file, you can use the `--verbose` command-line option to force SwiftFormat to print a more detailed log as it applies the formatting. **NOTE:** running in verbose mode is slower than the default mode.

You can also enable/disable rules for specific files or code ranges by using `swiftformat:` directives in comments inside your Swift files. To temporarily disable one or more rules inside a source file, use:

```swift
// swiftformat:disable <rule1> [<rule2> [rule<3> ...]]
```

To enable the rule(s) again, use:

```swift
// swiftformat:enable <rule1> [<rule2> [rule<3> ...]]
```

To disable all rules use:

```swift
// swiftformat:disable all
```

And to enable them all again, use:

```swift
// swiftformat:enable all
```

To temporarily prevent one or more rules being applied to just the next line, use:

```swift
// swiftformat:disable:next <rule1> [<rule2> [rule<3> ...]]
let foo = bar // rule(s) will be disabled for this line
let bar = baz // rule(s) will be re-enabled for this line
```

There is no need to manually re-enable a rule after using the `next` directive.

**Note:** The `swiftformat:enable` directives only serves to counter a previous `swiftformat:disable` directive in the same file. It is not possible to use `swiftformat:enable` to enable a rule that was not already enabled when formatting started.

Here are all the rules that SwiftFormat currently applies, and the effects that they have:

***blankLinesAtEndOfScope*** - removes trailing blank lines from inside braces, brackets, parens or chevrons:

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

***blankLinesAtStartOfScope*** - removes leading blank lines from inside braces, brackets, parens or chevrons:

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

***blankLinesBetweenScopes*** - adds a blank line before each class, struct, enum, extension, protocol or function:

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

***blankLinesAroundMark*** - adds a blank line before and after each `MARK:` comment:

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
                         
***braces*** - implements K&R (default, `--allman false`) or Allman-style indentation (`--allman true`):

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
                         
***consecutiveBlankLines*** - reduces multiple sequential blank lines to a single blank line:

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

***consecutiveSpaces*** - reduces a sequence of spaces to a single space:

```diff
- let     foo = 5
+ let foo = 5
```

***duplicateImports*** - removes duplicate import statements:

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

***elseOnSameLine*** - controls whether an `else`, `catch` or `while` keyword after a `}` appears on the same line, depending on the `--elseposition` option (`same-line` (default) or `next-line`):

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

***emptyBraces*** - removes all white space between otherwise empty braces:

```diff
- func foo() {
- 
- }


+ func foo() {}
```
   
***fileHeader*** - allows the replacement or removal of Xcode's automated comment header blocks. By default, no action is taken, but passing one of the following arguments to the command-line will activate its function.

- `--header strip`: removes all automated comment header blocks
- `--header "Copyright Text {year}"`: replaces all automated comment header blocks with the text specified

    See the File Headers section below for more information.

***hoistPatternLet*** - moves `let` or `var` bindings inside patterns to the start of the expression, or vice-versa, depending on the `--patternlet` option (`hoist` or `inline`).

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

***indent*** - adjusts leading whitespace based on scope and line wrapping. Uses either tabs (`--indent tab`) or spaces (`--indent 4`). By default, `case` statements will be indented level with their containing `switch`, but this can be controlled with the `--indentcase` options. Also affects comments and `#if ...` statements, depending on the configuration of the `--comments` option (`indent` or `ignore`) and the `--ifdef` option (`indent` (default), `noindent` or `ignore`):

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

***linebreakAtEndOfFile*** - ensures that the last line of the file is empty:
       
***linebreaks*** - normalizes all linebreaks to use the same character, depending on the `--linebreaks` option (`cr`, `crlf` or `lf`).

***numberFormatting*** - handles case and grouping of number literals, depending on the following options:
- `--hexliteralcase` and `--exponentcase` (`uppercase` (default) or `lowercase`)
- `--hexgrouping`, `--binarygrouping`, `--octalgrouping` (`4,8` (default grouping,threshold), `none` or `ignore`) 
- `--decimalgrouping` (`3,6` (default grouping,threshold), `none` or `ignore`)
- `--fractiongrouping` and `--exponentgrouping` (`disabled` (default) or `enabled`)

```diff
- let color = 0xFF77A5
+ let color = 0xff77a5
```

```diff
- let big = 123456.123
+ let big = 123_456.123
```

***ranges*** - controls the spacing around range operators. By default, a space is added, but this can be configured using the `--ranges` option (`spaced` (default) or `nospace`).

***redundantBackticks*** - removes unnecessary escaping of identifiers using backticks, e.g. in cases where the escaped word is not a keyword, or is not ambiguous in that context:

```diff
- let `infix` = bar
+ let infix = bar
```

```diff
- func foo(with `default`: Int) {}
+ func foo(with default: Int) {}
```

***redundantGet*** - removes unnecessary `get { }` clauses from inside read-only computed properties:

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

***redundantLet*** - removes redundant `let` or `var` from ignored variables in bindings (which is a warning in Xcode):

```diff
- let _ = resultIgnorableFunction()
+ _ = resultIgnorableFunction()
```

```diff
- if case (let foo, let _) = bar {}
+ if case (let foo, _) = bar {}
```

```diff
- if case .foo(var /* unused */ _) = bar {}
+ if case .foo( /* unused */ _) = bar {}
```

***redundantNilInit*** - removes unnecessary nil initialization of Optional vars (which are nil by default anyway):

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

***redundantParens*** - removes unnecessary parens from expressions and branch conditions:

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
    
***redundantPattern*** - removes redundant pattern matching arguments for ignored variables:

```diff
- if case .foo(_, _) = bar {}
+ if case .foo = bar {}
```

```diff
- let (_, _) = bar
+ let _ = bar
```
    
***redundantRawValues*** - removes raw string values from enum cases when they match the case name:

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

***redundantReturn*** - removes unnecessary `return` keyword from single-line closures:

```diff
- array.filter { return $0.foo == bar }
+ array.filter { $0.foo == bar }
```
    
***redundantSelf*** - removes or inserts `self` prefix from class and instance member references, depending on the `--self` option:

```diff
  init(foo: Int, bar: Int) {
    self.foo = foo
    self.bar = bar
-   self.baz = 42
  }

  init(foo: Int, bar: Int) {
    self.foo = foo
    self.bar = bar
+   baz = 42
  }  
```
    
***redundantVoidReturnType*** - removes unnecessary `Void` return type from function declarations:

```diff
- func foo() -> Void {
    // returns nothing
  }

+ func foo() {
    // returns nothing
  }
```

***redundantInit*** - removes unnecessary `init` when instantiating Types:

```diff
- String.init("text")
+ String("text")
```
    
***semicolons*** - removes semicolons at the end of lines.  Also replaces inline semicolons with a linebreak, depending on the `--semicolons` option (`inline` (default) or `never`).

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

***sortedImports*** - rearranges import statements so that they are sorted:

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

***spaceAroundBraces*** - contextually adds or removes space around `{ ... }`:

```diff
- foo.filter{ return true }.map{ $0 }
+ foo.filter { return true }.map { $0 }
```

```diff
- foo( {} )
+ foo({})
```

***spaceAroundBrackets*** - contextually adjusts the space around `[ ... ]`:

```diff
- foo as[String]
+ foo as [String]
```

```diff
- foo = bar [5]
+ foo = bar[5]
```

***spaceAroundComments*** - adds space around `/* ... */` comments and before `//` comments, depending on the `--comments` option (`indent` (default) or `ignore`).

```diff
- let a = 5// assignment
+ let a = 5 // assignment
```

```diff
- func foo() {/* no-op */}
+ func foo() { /* no-op */ }
```

***spaceAroundGenerics*** - removes the space around `< ... >`:

```diff
- Foo <Bar> ()
+ Foo<Bar>()
```

***spaceAroundOperators*** - contextually adjusts the space around infix operators. Also adds or removes the space between an operator function declaration and its arguments, depending on the `--operatorfunc` option (`spaced` (default) or `nospace`).

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

***spaceAroundParens*** - contextually adjusts the space around `( ... )`:

```diff
- init (foo)
+ init(foo)
```

```diff
- switch(x){
+ switch (x) {
```

***spaceInsideBraces*** - adds space inside `{ ... }`:

```diff
- foo.filter {return true}
+ foo.filter { return true }
```

***spaceInsideBrackets*** - removes the space inside `[ ... ]`:

```diff
- [ 1, 2, 3 ]
+ [1, 2, 3]
```

***spaceInsideComments*** - adds a space inside `/* ... */` comments and at the start of `//` comments, depending on the `--comments` option (`indent` (default) or `ignore`).

```diff
- let a = 5 //assignment
+ let a = 5 // assignment
```

```diff
- func foo() { /*no-op*/ }
+ func foo() { /* no-op */ }
```

***spaceInsideGenerics*** - removes the space inside `< ... >`:

```diff
- Foo< Bar, Baz >
+ Foo<Bar, Baz>
```

***spaceInsideParens*** - removes the space inside `( ... )`:

```diff
- ( a, b )
+ (a, b)
```

***specifiers*** - normalizes the order for access specifiers, and other property/function/class/etc. specifiers:

```diff
- lazy public weak private(set) var foo: UIView?
+ private(set) public lazy weak var foo: UIView?
```

```diff
- public override final func foo()
+ final override public func foo()
```

```diff
- convenience private init() 
+ private convenience init()
```

***strongOutlets*** - removes the `weak` specifier from `@IBOutlet` properties, as per [Apple's recommendation](https://developer.apple.com/videos/play/wwdc2015/407/):

```diff
- @IBOutlet weak var label: UILabel!
+ @IBOutlet var label: UILabel!
```

***trailingClosures*** - converts the last closure argument in a function call to trailing closure syntax where possible:

```diff
- DispatchQueue.main.async(execute: {
    // do stuff
- })

+ DispatchQueue.main.async {
    // do stuff
+ }
```

**NOTE:** Occasionally, using trailing closure syntax makes a function call ambiguous, and the compiler can't understand it. Since SwiftFormat isn't able to detect this in all cases, the `trailingClosures` rule is disabled by default, and must be manually enabled via the `--enable trailingClosures` option.

***trailingCommas*** - adds or removes trailing commas from the last item in an array or dictionary literal, depending on the `--commas` option (`always` (default) or `inline`).

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

***trailingSpace*** - removes the whitespace at the end of a line, depending on the `--trimwhitespace` option (`always` (default) or `nonblank-lines`).
 
***todos*** - ensures that `TODO:`, `MARK:` and `FIXME:` comments include the trailing colon (else they're ignored by Xcode):

```diff
- /* TODO fix this properly */
+ /* TODO: fix this properly */
```

```diff
- // MARK - UIScrollViewDelegate
+ // MARK: - UIScrollViewDelegate
```

***unusedArguments*** - marks unused arguments in functions and closures with `_` to make it clear they aren't used. Use the `--stripunusedargs` option to configure which argument types are affected (`always` (default), `closure-only` or `unnamed-only`).

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
    
***void*** - standardizes the use of `Void` vs an empty tuple `()` to represent empty argument lists and return values, depending on the `--empty` option (`void` (default) or `tuple`).

```diff
- let foo: () -> (
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

***wrapArguments*** - wraps function arguments and collection literals depending on the `--wraparguments` and `--wrapcollections` options (`beforefirst`, `afterfirst` or `preserve`) and the `--closingparen` option (`balanced` (default) or `same-line`). E.g. for `--wraparguments beforefirst` and `--closingparen balanced`:

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

Or for `--wrapcollections beforefirst`:

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


Config
------

Although it is possible to configure SwiftFormat directly by using the command-line [options](#options) and [rules](#rules) detailed above, it is sometimes more convenient to create a configuration file, which can be added to your project and shared with other developers.

A SwiftFormat configuration file consists of one or more command-line options, split onto separate lines, e.g:

```
--allman true
--indent tabs
--disable elseOnSameLine,semicolons
```

While formatting, SwiftFormat will automatically check inside each subdirectory for the presence of a ".swiftformat" file and will apply any options that it finds there to the files in that directory.

This allows you to override certain rules or formatting options just for a particular directory of files. You can also specify excluded files relative to that directory using `--exclude`, which may be more convenient than specifying them at the top-level.

Files named ".swiftformat" will be processed automatically, however you can select an additional configuration file to use for formatting using the `--config "path/to/config/file"` command-line argument. A configuration file selected using `--config` does not need to be named ".swiftformat", and can be located outside of the project directory.

The config file format is designed to be human editable. You may include blank lines for readability, and can also add comments using a hash prefix (#), e.g.

```
# format options
--allman true
--indent tabs # tabs FTW!

# file options
--exclude Pods

# rules
--disable elseOnSameLine,semicolons
```

If you would prefer not to edit the configuration file by hand, you can use the [SwiftFormat for Xcode](#xcode-source-editor-extension) app to edit the configuration and export a configuration file. Alternatively, you can use the swiftformat command-line-tool's `--inferoptions` command to generate a config file from your existing project, like this:

```bash
> cd /path/to/project
> swiftformat --inferoptions . --output .swiftformat
```


Linting
-------

SwiftFormat is primarily designed as a formatter rather than a linter, i.e. it is designed to fix your code rather than tell you what's wrong with it. However, sometimes it can be useful to verify that code has been formatted in a context where it is not desirable to actually change it.

A typical example would be as part of a CI (Continuous Integration) process, where you may wish to have an automated script that checks committed code for style violations. While you could use a separate tool such as [SwiftLint](https://github.com/realm/SwiftLint) for this, it makes sense to be able to validate the formatting against the exact same rules as you are using to apply it.

In order to run SwiftFormat as a linter, you can use the `--lint` command-line option:

```bash
> swiftformat --lint path/to/project
```

This works exactly the same way as when running in format mode, and all the same configuration options apply, however no files will be modified. SwiftFormat will simply format each file in memory and then compare the result against the input. If any formatting changes would have been applied, it will report an error.

The `--lint` option is very similar to `--dryrun`, except that `--lint` will return a nonzero error code if any changes are detected, which is useful if you want it to fail a build step on your CI server.

By default, `--lint` will only report the number of files that were changed, but you can use the additional `--verbose` flag to display a detailed report about which specific rules were applied to which specific files.


FAQ
-----

There haven't been many questions yet, but here's what I'd like to think people are wondering:


*Q. What versions of Swift are supported?*

> A. The framework compiles on Swift 3.x or 4.x and can format programs written in Swift 3.x or 4.x. Swift 2.x is no longer actively supported. If you are still using Swift 2.x, and find that SwiftFormat breaks your code, the best solution is probably to revert to an earlier SwiftFormat release, or enable only a small subset of rules.


*Q. I don't like how SwiftFormat formatted my code*

> A. That's not a question (but see below).


*Q. How can I modify the formatting rules?*

> A. Many configuration options are exposed in the command-line interface or .swiftformat configuration file. You can either set these manually, or use the `--inferoptions` argument to automatically generate the configuration from your existing project.

> If there is a rule that you don't like, and which cannot be configured to your liking via the command-line options, you can disable the rule by using the `--disable` argument, followed by the name of the rule. You can display a list of all rules using the `--rules` argument, and their behaviors are documented above this section in the README.

> If you are using the Xcode Source Editor Extension, rules and options can be configured using the [SwiftFormat for Xcode](#xcode-source-editor-extension) host application. Unfortunately, due to limitation of the Extensions API, there is no way to configure these on a per-project basis.

> If the options you want aren't exposed, and disabling the rule doesn't solve the problem, the rules are implemented as functions in the file `Rules.swift`, so you can modify them and build a new version of the command-line tool. If you think your changes might be generally useful, make a pull request.


*Q. Why can't I set the indent width or choose between tabs/spaces in the [SwiftFormat for Xcode](#xcode-source-editor-extension) options?*

> Indent width and tabs/spaces can be configured in Xcode on a per project-basis. You'll find the option under "Text Settings" in the right-hand sidebar.


*Q. After applying SwiftFormat, my code won't compile. Is that a bug?*

> A. SwiftFormat should never break your code. Check the known issues below, and if it's not already listed there, or the suggested workaround doesn't solve your problem, please [raise an issue on Github](https://github.com/nicklockwood/SwiftFormat/issues).


*Q. Why did you write yet another Swift formatting tool?*

> A. Surprisingly, there really aren't that many other options out there, and none of them currently support all the rules I wanted. The only other comparable ones I'm aware of are Realm's [SwiftLint](https://github.com/realm/SwiftLint) and Jintin's [Swimat](https://github.com/Jintin/Swimat) - you might want to try those if SwiftFormat doesn't meet your requirements.


*Q. Does it use SourceKit?*

> A. No.


*Q. Why would you write a parser from scratch instead of just using SourceKit?*

> A. The fact that there aren't already dozens of full-featured Swift formatters using SourceKit would suggest that the "just" isn't warranted.


*Q. You wrote a Swift parser from scratch!? Are you a wizard?*

> A. Yes. Yes I am.


*Q. How does it work?*

> A. First it loops through the source file character-by-character and breaks it into tokens, such as `number`, `identifier`, `linebreak`, etc. That's handled by the functions in `Tokenizer.swift`.

> Next, it applies a series of formatting rules to the token array, such as removing whitespace at the end of a line, or ensuring each opening brace appears on the same line as the preceding non-space token. The rules are defined as methods of the `FormatRules` class in `Rules.swift`, and are detected automatically using runtime magic. Each rule is designed to be independent of the others, so they can be enabled or disabled individually.

> Rules are applied recursively until no changes are detected. Finally, the modified token array is stitched back together to re-generate the source file.


*Q. Why aren't you using regular expressions?*

> A. See https://xkcd.com/1171/ for details.


*Q. Can I use SwiftFormat to lint my code without changing it?*

> A. Yes, see the [linting](#linting) section above for details.


*Q. Can I use the `SwiftFormat.framework` inside another app?*

> A. Yes, the SwiftFormat framework can be included in an app or test target, and used for many kinds of parsing and processing of Swift source code besides formatting. The SwiftFormat framework is available as a [CocoaPod](https://cocoapods.org/pods/SwiftFormat) for easy integration.


Cache
------

SwiftFormat uses a cache file to avoid reformatting files that haven't changed. For a large project, this can significantly reduce processing time.

By default, the cache is stored in `~/Library/Caches/com.charcoaldesign.swiftformat`. Use the command-line option `--cache ignore` to ignore the cached version and re-apply formatting to all files. Alternatively, you can use `--cache clear` to delete the cache (or you can just manually delete the cache file).

The cache is shared between all projects. The file is fairly small, as it only stores the path and size for each file, not the contents. If you do start experiencing slowdown due to the cache growing too large, you might want to consider using a separate cache file for each project.

You can specify a custom cache file location by passing a path as the `--cache` option value. For example, you might want to store the cache file inside your project directory. It is fine to check in the cache file if you want to share it between different users of your project, as the paths stored in the cache are relative to the location of the formatted files.


File headers
-------------

SwiftFormat can be configured to strip or replace the header comments in every file with a template. The "header comment" is defined as a comment block that begins on the first nonblank line in the file, and is followed by at least one blank line. This may consist of a single comment body, or multiple comments on consecutive lines:

```swift
// This is a header comment
```

```swift
// This is a regular comment
func foo(bar: Int) -> Void { ... }
```

The header template is a string that you provide using the `--header` command-line option. Passing a value of `ignore` (the default) will leave the header comments unmodified. Passing `strip` or an empty string `""` will remove them. If you wish to provide a custom header template, the format is as follows:

For a single-line template: `--header "Copyright (c) 2017 Foobar Industries"`

For a multiline comment, mark linebreaks with `\n`: `--header "First line\nSecond line"`

You can optionally include Swift comment markup in the template if you wish: `--header "/*--- Header comment ---*/"`

If you do not include comment markup, each line in the template will be prepended with `//` and a single space.

Finally, it is common practice to include the current year in a comment header copyright notice. To do that, use the following syntax:

```bash
--header "Copyright (c) {year} Foobar Industries"
```
    
And the `{year}` token will be automatically replaced by the current year whenever SwiftFormat is applied (**Note:** the year is determined from the locale and timezone of the machine running the script).


Known issues
---------------

* When using the `--self remove` option, the `redundantSelf` rule will remove references to `self` in autoclosure arguments, which may change the meaning of the code, or cause it not to compile. To work around this issue, use the `// swiftformat:disable:next redundantSelf` comment directive to disable the rule for any affected lines of code (or just disable the `redundantSelf` rule completely). If you are using the `--self insert` option then this is not an issue.

* If you assign `SomeClass.self` to a variable and then instantiate an instance of the class using that variable, Swift requires that you use an explicit `.init()`, however the   `redundantInit` rule is not currently capable of detecting this situation and will remove the `.init`. To work around this issue, use the `// swiftformat:disable:next redundantInit` comment directive to disable the rule for any affected lines of code (or just disable the `redundantInit` rule completely).

* The `--self insert` option can only recognize locally declared member variables, not ones inherited from superclasses or extensions in other files, so it cannot insert missing `self` references for those. Note that the reverse is not true: `--self remove` should remove *all* redundant `self` references.

* The `trailingClosures` rule will sometimes generate ambiguous code that breaks your program. For this reason, the rule is disabled by default. It is recommended that you apply this rule manually and review the changes, rather than including it in an automated formatting process.

* Under rare circumstances, SwiftFormat may misinterpret a generic type followed by an `=` sign as a pair of `<` and `>=` expressions. For example, the following case would be handled incorrectly:

    ```swift
    let foo: Dictionary<String, String>=["Hello": "World"]
    ```    

    To work around this, either manually add spaces around the `=` character to eliminate the ambiguity, or add a comment directive above that line in the file:
    
    ```swift
    // swiftformat:disable:next spaceAroundOperators
    let foo: Dictionary<String, String>=["Hello": "World"]
    ```

* If a file begins with a comment, the `stripHeaders` rule will remove it if is followed by a blank line. To avoid this, make sure that the first comment is directly followed by a line of code.

* SwiftFormat currently reformats multiline comment blocks without regard for the original indenting. That means

    ```swift
    /* some documentation
    
          func codeExample() {
              print("Hello World")
          }
 
     */
    ```
         
    Will become
    
    ```swift
    /* some documentation
    
     func codeExample() {
     print("Hello World")
     }
     
     */
    ```
         
    To work around that, you can disable automatic indenting of comments using the `comments` command-line flag.
    
    Alternatively, if you prefer to leave the comment indenting feature enabled, you can rewrite your multiline comment as a block of single-line comments...
    
    ```swift
    // some documentation
    //
    //    func codeExample() {
    //        print("Hello World")
    //    }
    //
    //
    ```
        
    Or begin each line with a `*` (or any other non-whitespace character)
    
    ```swift
    /* some documentation
     *
     *    func codeExample() {
     *        print("Hello World")
     *    }
     *  
     */
    ```
         
* The formatted file cache is based on a hash of the file contents, so it's possible (though unlikely) that an edited file will have the exact same hash as the previously formatted version, causing SwiftFormat to incorrectly identify it as not having changed, and fail to update it.

    To fix this, you can use the command-line option `--cache ignore` to force SwiftFormat to ignore the cache for this run, or just type an extra space in the file (which SwiftFormat will then remove again when it applies the correct formatting).


Credits
------------

* @tonyarnold - Xcode source editor extension
* @vinceburn - Xcode extension settings UI
* @bourvill - Git pre-commit hook script
* @palleas - Homebrew formula
* @aliak00 - Several path-related CLI enhancements
* @yonaskolb - Swift Package Manager integration
* @nicklockwood - Everything else

([Full list of contributors](https://github.com/nicklockwood/SwiftFormat/graphs/contributors))
