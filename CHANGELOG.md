# Change Log

## [0.25.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.25.1) (2017-03-08)

- Fixed bug where unused arguments in a failable initializer could be incorrectly formatted
- Fixed bug where backtick escaping would be incorrectly removed from certain keywords

## [0.25.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.25.0) (2017-03-07)

- The `stripHeaders` rule is now `fileHeaders`, which can strip or replace header comments with a custom template (see README for details)
- Added `hoistPatternLet` rule that moves `let` and `var` to the beginning of `switch/case` patterns, or tuple assignments
- Added `redundantReturn` rule that strips the `return` keyword from single-line closures
- Added `redundantBackticks` rule that removes unnecessary ``escaping`` of keywords

## [0.24.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.7) (2017-02-28)

- Fixed a bug where switch cases containing a `..<` operator were parsed incorrectly, resulting in incorrect indentation
- Fixed a potential bug where source code could be truncated after an error when running with `--fragment` enabled
- Command-line tool installation via CocoaPods no longer requires a minimum deployment target of iOS 9 / macOS 10.11

## [0.24.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.6) (2017-02-16)

- Fixed critical bug where automatic removal of Void return type in closures could alter the type signature
- Command-line tool can now be installed via CocoaPods

## [0.24.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.5) (2017-02-12)

- Fixed critical bug where trailing commas were incorrectly added to array or dictionary type declarations

## [0.24.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.4) (2017-02-09)

- Fixed format rules not being applied when processing input from stdin
- Fixed allman brace formatting of optional computed vars
- Allman brace rule now removes the blank line immediately after an opening brace

## [0.24.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.3) (2017-01-26)

- Fixed critical bug where unused `inout` closure arguments were mangled
- Fixed critical bug where comma was incorrectly inserted into subscript expressions
- Fixed critical bug where functions named "get" could be incorrectly stripped 
- Unused arguments are now handled correctly in `init` and `subscript` functions
- Fixed bug where `_` was doubled up for unused closure arguments

## [0.24.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.2) (2017-01-20)

- Unused arguments are now handled correctly in non-Void functions
- Fixed another bug where keywords used as function argument names were not parsed correctly
- Fixed bug when parsing generics containing a `&` protocol-combining operator
- Fixed bug where parsing error location was reported incorrectly

## [0.24.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.1) (2017-01-19)

- Fixed crash in Xcode extension when formatted file has no changes
- Fixed caching bug that meant enabled/disabled rules were not taken into account
- Unix shebang/hashbang directive at start of a source file is no longer treated as an error

## [0.24](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24) (2017-01-18)

- Fixed a critical bug where closure arguments could be mangled by the `unusedArguments` rule
- Added `trailingClosures` rule, to automatically convert closure arguments to trailing closure syntax
- Added `--enable` option to enable optional rules such as `trailingClosures` (which is disabled by default)
- Added `--stripunusedargs` option to provide more fine-grained control of the `unusedArguments` rule
- Added `--decimalgrouping`, `--hexgrouping`, `--binarygrouping` and `--octalgrouping` options
- Added `--exponentcase` option for controlling the case of "e" in exponential literals, e.g. `3.4e-5`
- Merged `hexLiterals` rule into new `numberFormatting` rule that handles case and grouping of numbers
- Renamed `--hexliterals` option to `--hexliteralcase`
- The `void` rule now converts `(_: Void)` to `()` automatically
- The `redundantParens` rule now removes empty `()` before a trailing closure
- Fixed some bugs with floating-point hex literal support
- Fixed bug where keywords used as function argument names were not parsed correctly
- Added Swift Package Manager support

## [0.23.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.23.1) (2017-01-14)

- Fixed critical bug where closure return types could be mangled by the `unusedArguments` rule
- Fixed issue where console text appeared as black instead of user's chosen default color

## [0.23](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.23) (2017-01-09)

- You can now specify a whitelist of specific rules to apply using the `--rules` option
- Input files are now processed concurrently, yielding a ~2x speed improvement
- SwiftFormat now continues if it encounters an error when processing multiple files
- Improved error messaging, and added color coding to the command line output
- `--inferoptions` now accepts multiple space-delimited file paths, or piped input, just like formatting
- `redundantVoidReturnType` now removes Void return from closures as well as ordinary functions
- `unusedArguments` now works on closures as well as ordinary functions
- `unusedArguments` is now more effective at detecting when an argument is unused 
- Fixed crash in `wrapArguments` rule due to linebreak being incorrectly removed after a single-line comment
- Format rules displayed using the `--rules` option are now sorted alphabetically

## [0.22](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.22) (2017-01-03)

- Fixed critical bug where `>=` operator was misidentified as end of generic argument list
- Added `redundantRawValues` rule to remove string enum literals that match the associated case name
- Added `redundantVoidReturnType` rule to remove unnecessary `Void` return type from function declarations
- Added `unusedArguments` rule, to replace unused arguments in function declarations with an underscore
- Fixed bug with `--inferoptions` and argument wrapping
- Fixed bug where extra space was added inside empty `TODO:` comments

## [0.21](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.21) (2016-12-19)

- Added `redundantLet` rule to remove unnecessary `let` keyword in statements like  `let _ = foo()`
- Added `redundantPattern` rule to simplify wildcard patterns like `.foo(_, _)` to just `.foo`
- Rules are now run repeatedly until no changes are detected, fixing an issue where changes could be missed
- Fixed a bug where extra space was inserted between `?` and `.` in optional chaining expressions
- A space is no longer added between a comment and the following comma
- Fixed some performance regressions

## [0.20](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.20) (2016-12-09)

- Added `redundantNilInit` rule, to remove unnecessary nil initialization of Optional vars
- The `trailingCommas` rule now removes trailing commas for inline array literals
- Fixed bug in `void` rule when handling chains of throwing functions
- Fixed some performance regressions

## [0.19](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.19) (2016-12-02)

- Fixed a critical bug where `redundantParens` rule failed to insert space before a prefix operator
- Fixed a crash when encountering generic arguments followed by ...
- Added `--disable` option for individually disabling rules without needing to recompile
- Added `--rules` command to display all the supported rules (useful in conjunction with `--disable`)
- Added `--wraparguments` option for controlling how function arguments are wrapped
- Added `--wrapelements` option for controlling how array and dictionary elements are wrapped
- Added `--symlinks` option for specifying if symlinks/aliases should be followed and formatted
- Fixed bug where symlinks to Swift files would be replaced by a copy of the file

## [0.18](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.18) (2016-11-17)

- Added `--inferoptions` command line argument for auto-configuring format options from existing source
- Added `--ifdef` command line argument for controlling how `#if`...`#endif` clauses are indented
- Added `--hexliterals` command line argument for specifying the case to use for hex literals
- Added `redundantGet` rule to remove unneeded `get {}` clause in read-only computed properties
- Fixed bug where `redundantParens` rule merged identifiers on either side of a removed paren
- `redundantParens` now removes unneeded parens from expressions and closure arguments

## [0.17.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.17.2) (2016-11-11)

- Fixed critical bug with `redundantParens` rule removing required parens around a closure
- Fixed bug with indenting of wrapped closures after a var declaration

## [0.17.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.17.1) (2016-11-09)

- Xcode Source Editor Extension now works with Playground files
- Fixed operator being incorrectly formatted when file ends with a single-line comment
- Fixed bug where the space at the start of a single line comment could increase after each format
- Fixed bug where `--cache clear` just ignored cache without actually clearing it
- Added `--cache ignore` option, which replicates previous `--cache clear` behavior

## [0.17](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.17) (2016-11-08)

- Added cache, allowing SwiftFormat to skip formatting for files that haven't changed
- Added `stripHeaders` rule to remove Xcode's copyright header comments (off by default)
- Disabled `linebreakAtEndOfFile` rule when formatted text is a fragment
- Fixed bug where generics were wrongly formatted if followed by a greater-than sign in the same file
- Fixed space incorrectly added after `#available`, `#colorLiteral`, etc
- Fixed several bugs with indenting of blocks containing wrapped lines

## [0.16.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.16.4) (2016-11-07)

- SwiftFormat is now ~3X faster!
- Fixed bug with spacing after an @convention() attribute
- Fixed bug where the space at the start of a multi-line comment could increase after each format
- Fixed bug where wrong indent was applied to wrapped array literal values
- Fixed bug where K&R indenting would remove the linebreak before an inline block

## [0.16.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.16.3) (2016-11-03)

- Fixed bug with operators containing chevrons
- Fixed wrong indent after where statement in switch case

## [0.16.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.16.2) (2016-11-03)

- Fixed bug with spacing of deeply nested generic arguments, or generic operator functions
- Fixed spacing of `@autoclosure(escaping)` syntax (only used in Swift 2.2)
- Fixed bug where `(Void) throws -> Void` was handled incorrectly

## [0.16.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.16.1) (2016-11-03)

- Fixed critical bug where `redundantParens` would remove parens from tuple in `switch` condition
- Fixed incorrect spacing around attributes that have arguments, e.g. `@convention(block)`
- `--comments ignore` command line option now disables leading space insertion in single-line comments

## [0.16](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.16) (2016-11-02)

- Added `redundantParens` rule to remove parens around `if`, `while` and `switch` conditions
- Added ability to specify multiple file paths for processing in a single command
- Fixed a bug with the formatting of `repeat ... while` loops
- Added performance tests
- API refactoring

## [0.15](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.15) (2016-10-27)

- Added `allman` command line option to enable Allman style indenting instead of K&R style
- Added `removelines` command line option to disable automatic removal of blank lines
- Added `insertlines` command line option to disable automatic blank line insertion
- Added `trimwhitespace` command line option for disabling truncation of blank lines
- Added `comments` command line option for disabling indenting of comments
- Added `experimental` command line option for opting-in to bleeding-edge features
- Fixed broken `commas` command line option from version 0.14
- Made `blankLinesBetweenScopes` rule less aggressive

## [0.14](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.14) (2016-10-21)

- Xcode Source Editor Extension now automatically infers formatting options from the file
- Wrapped function arguments and array/dictionary literal value indenting now works more like Xcode
- Added `void` rule for normalizing how Void return values are represented
- Added `empty` command line option for configuring the void rule
- Added `commas` command line option for disabling trailing commas
- Improved formatting of fragments containing unbalanced braces

## [0.13](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.13) (2016-10-17)

- Added Xcode Source Editor Extension (thanks @tonyarnold!)
- Fixed indenting of the line after a return statement (which is treated as the return value)

## [0.12.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.12.1) (2016-10-14)

- Fixed stripping of space after `@escaping`, `@autoclosure` and `inout`
- Fixed stripping of trailing linebreaks when using --fragment option

## [0.12](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.12) (2016-10-08)

- Linewrapped `case` elements are now vertically aligned
- The `else` keyword in a `guard` statement is no longer indented
- The `elseOnSameLine` rule is no longer applied if previous `} is not on its own line
- Fixed handling of `case` after comma in an `if` statement
- Added support for formatting partial file fragments
- Reduced compilation time by ~500ms

## [0.11.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.11.4) (2016-10-05)

- Fixed critical bug where optionals with a default value were not handled correctly
- Fixed rare bug where code would be incorrectly indented after a custom operator declaration

## [0.11.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.11.3) (2016-10-04)

- Fixed spacing between closure capture list and arguments
- Fixed incorrect indenting of closures after and `if` statement, and other braced clauses

## [0.11.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.11.2) (2016-10-04)

- Fixed incorrect indenting of closures inside `for` loops, and other braced clauses

## [0.11.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.11.1) (2016-10-04)

- Fixed incorrect wrapping of chained closures
- Improved the logic for wrapped lines; now behaves more like Apple's implementation
- Fixed some bugs in command line tool when file paths contain escaped characters

## [0.11](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.11) (2016-09-24)

- Fixed handling of `prefix` and `postfix` specifiers
- Fixed bug where trailing comma was added to empty array or dictionary literal
- Fixed bug where trailing whitespace was added at the start of doc comments
- Improved correctness of numeric literal parsing
- Converted to Swift 3 syntax

## [0.10](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.10) (2016-09-18)

- The `blankLinesAtEndOfScope` rule no longer removes trailing blank lines if immediately followed by other code
- The `blankLinesBetweenScopes` rule now adds a blank line after a scope as well as before it
- The `blankLinesBetweenScopes` rule no longer affects single-line functions, classes, etc.
- Fixed formatting of `while case` and `for case ... in` statements
- Fixed bug when using `switch` as an identifier inside a `switch` statement
- Fixed parsing of numeric literals containing underscores
- Fixed parsing of binary, octal and hexadecimal literals

## [0.9.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.6) (2016-09-16)

- Fixed parsing error when `switch` statement is followed by `enum`
- Fixed formatting of `guard case` statements

## [0.9.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.5) (2016-09-14)

- Fixed a number of cases where the use of keywords as identifiers was not being handled correctly

## [0.9.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.4) (2016-09-14)

- Fixed bug where parsing would fail if a `switch/case` statement contained `default` or `case` indentifiers (valid in Swift 3)

## [0.9.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.3) (2016-09-12)

- Fixed bug where functions would be prefixed with an additional blank line if the preceding line had a trailing comment

## [0.9.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.2) (2016-09-09)

- Fixed bug where `case` expressions containing a colon would not be parsed correctly

## [0.9.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9.1) (2016-09-08)

- Fixed bug where `trailingCommas` rule would place comma after a comment instead of before it

## [0.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.9) (2016-09-07)

- Added `blankLinesBetweenScopes` rule that adds a blank line before each class, struct, enum, extension, protocol or function
- Added `specifiers` rule, for normalizing the order of access modifiers, etc
- Fixed indent bugs when wrapping code before or after a `where` or `else` keyword
- Fixed indent bugs when using an operator as a value (e.g. let greaterThan = >)

## [0.8.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.8.2) (2016-09-01)

- Fixed bug where consecutive spaces would not be removed in lines that appeared after a `//` comment
- SwiftFormat will no longer try to format code containing unbalanced braces
- Added pre-commit hook instructions

## [0.8.1]() (2016-08-31)

- Fixed formatting of `/*! ... */` and `//!` headerdoc comments, and `/*: ... */` and `//:` Swift Playground comments

## [0.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.8) (2016-08-31)

- Added new `ranges` rules that adds or removes the spaces around range operators (e.g. `0 ..< count`, `"a"..."z"`)
- Added a new `--ranges` command-line option, which can be used to configure the spacing around range operators 
- Added new `spaceAroundComments` rule, which adds a space around /* ... */ comments and before // comments
- Added new `spaceInsideComments` rule, which adds a space inside /* ... */ comments and at the start of // comments
- Added new `blankLinesAtEndOfScope` rule, which removes blank lines at the end of braces, brackets and parens
- Removed double blank line at end of file

## [0.7.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.7.1) (2016-08-29)

- Fixed critical bug where failable generic init (e.g. `init?<T>()`) was not handled correctly

## [0.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.7) (2016-08-28)

- swiftformat command-line tool now correctly handles paths with `\` escaped spaces, or paths in quotes
- Removed extra space added inside `@objc` selectors
- Fixed incorrect spacing for tuple bindings
- Fixed space before enum case inside closure

## [0.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.6) (2016-08-26)

- Refactored how switch/case is handled, and fixed a bunch of bugs
- Better indenting logic, now handles multiple closure arguments in a single function call

## [0.5.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.5.1) (2016-08-25)

- Fixed critical bug where double unwrap (e.g. `foo??.bar()`) was not handled correctly
- Fixed bug where `case let .SomeEnum` was not handled correctly

## [0.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.5) (2016-08-25)

- swiftformat command-line tool now supports reading from stdin/writing to stdout
- Added new `linebreaks` rule for normalizing linebreak characters (defaults to LF)
- More robust handling of linebreaks and whitespace within comments
- Trailing whitespace within comments is now stripped, as it was for other lines

## [0.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.4) (2016-08-24)

- Added new `semicolons` rule, which removes semicolons wherever it's safe to do so
- Added `--semicolons` command-line argument for enabling inline semicolon stripping
- The `todos` rule now corrects `MARK :` to `MARK:` instead of `MARK: :`
- Paths containing ~ are now handled correctly by the command line tool
- Fixed some bugs in generics and custom operator parsing, and added more tests
- Removed trailing whitespace on blank lines caused by the `indent` rule

## [0.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.3) (2016-08-23)

- Fixed several cases where generics were misidentified as operators
- Fixed a bug where a comment on a line before a brace broke K&R indenting
- Fixed a bug where a comment on a previous line caused incorrect indenting for wrapped lines
- Added new `todos` rule, for ensuring `TODO:`, `MARK:`, and `FIXME:` comments are formatted correctly
- Whitespace at the start of comments is now handled differently, but it shouldn't affect output

## [0.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.2) (2016-08-22)

- Fixed formatting of generic function types
- Fixed indenting of `if case` statements
- Fixed indenting of `else` when separated from `if` statement by a comment
- Changed `private(set)` spacing to match Apple standard
- Added swiftformat as a build phase to SwiftFormat, so I'm eating my own dogfood

## [0.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.1) (2016-08-22)

- First release
