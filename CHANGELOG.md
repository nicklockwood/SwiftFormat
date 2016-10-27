# Change Log

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
