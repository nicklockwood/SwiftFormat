# Change Log

## [0.45.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.6) (2020-08-12)

- Added `--yodaswap` option for more fine-grained control of `yodaConditions` rule
- Fixed indentation of wrapped type declarations when using `--xcodeindentation enabled`
- Fixed alignment of closure braces when using `--allman` style

## [0.45.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.5) (2020-08-09)

- Fixed `.swiftformat` configuration file processing when using `--stdinpath` option
- Fixed bug where conditional imports could be mangled by `sortedImports` rule
- Fixed indenting of braces after throwing function with wrapped return type
- Fixed indenting of wrapped `in` keyword inside closure

## [0.45.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.4) (2020-08-08)

- Improved indenting of wrapped closure braces when using `--allman` indenting
- Fixed crash in `blankLinesBetweenScopes` rule when using `--linerange` argument
- Fixed `indent` rules behavior when using `--linerange` argument
- Audited all rules for `--linerange` compatibility
- Improved `Format Selection` behavior in Swiftformat for Xcode extension
- Fixed bug with `fileHeader` rule stripping formatting comment directives at top of file
- Documented known issue with `preferKeyPath` and `compactMap()` in README file
- The value for `--wrapparameters` now defaults to match `--wraparguments`
- Fixed indenting of wrapped guard else

## [0.45.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.3) (2020-08-03)

- Added `--linerange` command-line argument for partial file formatting or linting
- Added `--varattributes` option to complement `--funcattributes` and `--typeattributes`
- Fixed spurious "Unexpected static/class ..." warning in `redundantSelf` rule 
- Fixed bug in tokenIndex() calculation when last line does not end in a linebreak
- Fixed bug where `self` was incorrectly removed inside trailing closures on generic type init
- Blank lines are no longer indented when using `--trimwhitespace nonblank-lines`

## [0.45.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.2) (2020-08-01)

- You can now tweak formatting options inside source files using `// swiftformat:options ...` directive
- The `wrapMultilineStatementBraces` rule is now applied to more statement types
- Fixed spurious lint warnings due to conflict between `braces` and `wrapMultilineStatementBraces` rules
- Fixed several bugs in `redundantSelf` rule relating to for loops
- Fixed bug with indenting of closure arguments
- Fixed unsafe removal of backticks around `init`
- Rules can now raise an error if they encounter malformed code instead of failing silently
- SwiftFormat for Xcode app no longer shows deprecated rules in the rules tab

## [0.45.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.1) (2020-07-30)

- Fixed bug where `preferKeyPath` was incorrectly applied to function calls and compound expressions
- The `wrapMultilineStatementBraces` rule is now applied to `init` and `subscript` braces
- The `wrapAttributes` rule now handles `init` and `subscript` the same way as functions

## [0.45.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.45.0) (2020-07-29)

- Added `wrapAttributes` rule for controlling attribute position
- Added `wrapMultilineStatementBraces` rule for opening braces for wrapped expressions
- Added `preferKeyPath` rule for converting trivial closures to keyPaths in Swift 5.2
- Added `--smarttabs` option to support consistent indenting regardless of `--tabwidth`
- Updated Xcode extension for Xcode 12 and macOS Big Sur
- Added Swift version dropdown to SwiftFormat for Xcode configuration app
- Added `--guardelse` option to control wrapping of `else` clauses in `guard` statements
- Allman braces are now applied to closure braces, which were previously ignored
- The `void` rule now converts `Void()` literals to just `()`
- Improved indenting of closing parentheses and brackets
- Renamed `--empty` option to `--voidtype`, which better describes its function
- Renamed `specifiers` rule to `modifierOrder` for consistency with SwiftLint
- Renamed `--specifierorder` configuration option to `--modifierorder`
- Fixed bug where `--verbose` mode didn't log path for unchanged files
- Improved documentation of `numberFormatting` configuration options
- Added Sublime Text plugin instructions

## [0.44.17](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.17) (2020-07-12)

- The `wrapArguments` rule now keeps internal and external parameter labels on the same line
- Multiline string literals are now indented more consistently 
- Fixed infinite recursion bug in the `redundantSelf` rule
- Fixed duplicate file path logging in `--verbose` mode
- Indented braces are now always balanced
- Add `--stdinpath` option, allowing git pre-commit hook to support file header info
- Updated instructions for git pre-commit hook (again)
- Added inference for `--noSpaceOperators` option

## [0.44.16](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.16) (2020-07-02)

- Fixed bug in `--output stdout` processing
- Reverted git pre-commit hook instructions

## [0.44.15](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.15) (2020-07-01)

- Fixed incorrect indenting for double-nested closures
- Added inference for `--wrapparameters` option
- Fixed incorrect `--wraparguments` inference
- The `spaceInsideBraces` rule will no longer add space between nested braces
- Fixed bug in `isStartOfClosure()` helper
- Fixed indent logic for closing braces
- You can now use `--output stdout` even when using a file path for input
- SwiftFormat will now raise an error if missing info needed for `fileHeader` rule
- Improved SwiftFormat for Xcode app icon
- Updated instructions for git pre-commit hook

## [0.44.14](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.14) (2020-06-23)

- Added new icon for SwiftFormat for Xcode app (thanks to Vikram Kriplaney for the icon design)
- Fixed `redundantParens` rule stripping parens around `#file` (used to silence warning in Swift 5.3)
- Avoid raising "Malformed .swift-version file" error when using unusual formats (e.g. for beta releases)
- Fixed `redundantBackticks` rule unescaping `get` inside subscript with `where` clause
- Fixed `redundantReturn` failing to remove `return` in function or subscript with `where` clause
- Fixed SwiftFormat for Xcode version number

## [0.44.13](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.13) (2020-05-28)

- Fixed indenting of closing bracket when using `wrapArguments` rule
- Added `--shortoptionals` argument to selectively disable shortening of `Optional<T>` to `T?` for properties
- Added `--minversion` argument to specify minimum SwiftFormat version to use for a given codebase

## [0.44.12](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.12) (2020-05-27)

- Fixed indenting of chained methods with trailing closures
- SwiftFormat command-line tool now logs the location of .swiftformat configuration files that it encounters

## [0.44.11](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.11) (2020-05-23)

- Fixed failure to terminate when wrapping functions after first parameter
- First element in a wrapped collection or function is now correctly indented
- Added workaround for Swift type sugar parsing bug
- The `blankLinesBetweenScopes` rule no longer inserts a blank line before an `#else` block
- Downgraded "No eligible files found" error to a warning
- Removed "Failed to format any files" error, which was sometimes triggered erroneously
- Fixed deprecation warning when building on Linux

## [0.44.10](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.10) (2020-05-14)

- Fixed bug where `--specifierorder` option values were sorted alphabetically
- Fixed a couple of bugs in `hoistPatternLet` when `--patternlet` is set to `inline`
- Added support for hoisting/unhoisting `var` and `let` in `do ... catch` patterns
- Added error if `--specifierorder` contains duplicate values

## [0.44.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.9) (2020-05-05)

- Added `--specifierorder` argument for overriding default order used by `specifiers` rule
- Added `--nowrapoperators` argument for preventing `wrap` rule breaking at specific operators
- The `redundantNilInit` rule no longer removes `nil` defaults from vars in structs using synthesized init
- Fixed indenting of trailing comment delimiter in multiline comments

## [0.44.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.8) (2020-05-01)

- Fixed a significant performance regression introduced in 0.44.6
- Changed ordering of `override` keyword in specifier lists to match SwiftLint
- Fixed timeout due to infinite recursion when formatting nested comments
- The `trailingSpace` rule is now called before `indent` to avoid noise when linting
- Fixed bug where `unusedArguments` rule ignored all arguments if any was already ignored
- Fixed `redundantParens` rule breaking closure argument lists where argument is named `self`
- Fixed indenting of multiline string interpolations
- Fixed broken formatting of multiline string interpolations
- Fixed crash in `wrap` rule
- The `wrap` rule now favors wrapping function args over wrapping at `.` operator
- Fixed a bug with indenting of pre-formatted multiline comments
- Fixed a misleading error message relating to `--tabwidth` option

## [0.44.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.7) (2020-04-04)

- Fixed indenting of wrapped closures after a switch statement
- Fixed bug with `redundantNilInit` removing `nil` for properties using parameterized property wrappers
- Fixed `redundantRawValues` rule not removing values for back-tick-escaped case names
- Improved error messages for misnamed rules
- Documentation improvements

## [0.44.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.6) (2020-03-21)

- Fixed timeout when formatting files containing multiple trailing closures
- Added `--filelist` argument for specifying input source files list in a standalone file
- Fixed bug in the git pre-commit hook suggested in the README file

## [0.44.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.5) (2020-03-11)

- Fixed bug with indenting of chained closures
- Fixed bug where wrapped braces were over-indented
- Fixed indenting of comments inside enum declarations
- Improved consistency of `--xcodeindentation` output with Xcode's built-in formatting
- Extension braces are now correctly wrapped
- Switch statement braces are now correctly wrapped
- Fixed bug where `duplicateImports` rule could remove a required `@testable` import

## [0.44.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.4) (2020-02-27)

- Allman braces are now applied correctly for lines that end in a numeric literal
- Blank line is now removed when stripping a redundant `return` keyword on its own line
- Fixed space being inserted before the `.` in a nested PropertyWrapper expression
- Fixed `return` being incorrectly removed inside `if` statements containing an un-parenthesized closure

## [0.44.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.3) (2020-02-20)

- Fixed incorrect indenting of closing multiline string delimiter
- Fixed bug where `redundantReturn` rule incorrectly removed `return` after a brace without leading space
- Fixed edge case where closures without surrounding parentheses were misinterpreted in if statements
- Fixed failure to wrap braces after a struct or init declaration

## [0.44.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.2) (2020-02-02)

- Fixed crash in line wrapping logic
- Fixed several cases where braces were not correctly moved according to `wrap` rule
- Prevented wrapping of image and color literals
- Fixed bug with `trailingClosures` rule breaking unwrap operators

## [0.44.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.1) (2020-01-26)

- Fixed `spaceInsideComments` rule mangling preformatted comments with multiple slashes
- Fixed `redundantFileprivate` breaking code relying on type-inference for `init`
- Reverted overly aggressive argument wrapping change in 0.44.0
- Fixed `redundantParens` rule breaking `#if` statements without space before argument
- Fixed `// swiftformat:disable` directives not affecting `wrap` or `wrapArguments` rules
- Fixed bug where `yodaConditions` rule caused formatting to never terminate
- Fixed crash in `fileHeader` rule

## [0.44.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.44.0) (2020-01-15)

- Xcode Extension now includes Lint File option
- Xcode Extension now preserves selection after formatting
- Improved range-based formatting in Xcode Extension
- Wrapping of function calls can now be configured separately from function declarations via the `--wrapparameters` option
- Numerous improvements to wrapping and indenting logic (thanks to @AnthonyMDev for the fixes)
- Fixed indent logic for unbalanced closing parens
- Fixed `self` being removed incorrectly inside if statements
- Fixed duplicate lint warnings
- Fixed failure to fix indent at start of file
- Fixed reported line index for `consecutiveBlankLines` rule

## [0.43.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.5) (2020-01-04)

- Fixed bug where `redundantBreak` rule removed entire line if break appeared after a semicolon
- Fixed a couple of cases where `redundantSelf` failed to remove `self` as expected

## [0.43.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.4) (2020-01-02)

- Fixed regression in `indent` rule` that could cause multiline strings to become mis-formatted
- Fixed bug in `--nospaceoperators` option where `..<` operator was rejected
- Added instructions for installing SwiftFormat for Xcode via Homebrew cask

## [0.43.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.3) (2019-12-31)

- Deprecated `ranges` rule and `--ranges` option (use `--nospaceoperators` with `spaceAroundOperators` rule instead)
- The `redundantSelf` rule no longer removes self in cases where property requires backtick escaping
- Fixed bug with `--nospaceoperators` potentially removing required spaced near linebreaks
- Fixed spurious lint warnings in `spaceAroundOperators`, `indent` and `wrap` rules
- Improved wrapping heuristic for closures to avoid splitting expressions if avoidable
- Fixed indenting of closing brace for line-wrapped closures
- Fixed `indent` rule performance regression introduced in 0.43.2
- Added warnings for deprecated options in config file

## [0.43.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.2) (2019-12-28)

- Added `--nospaceoperators` option for selectively removing space around specific operators
- Allow `self` in lazy vars when Swift 4 and above
- Fixed spurious lint warning when using a custom header with `fileHeader` rule
- Fixed bugs with indenting of consecutive comments
- Fixed resolving of macOS aliases when using `--symlinks follow`
- Added explicit `stdin` parameter option
- Fixed stdin timeout flakiness
- Fixed bug with `andOperator` replacing `&&` with `,` inside ViewBuilders

## [0.43.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.1) (2019-12-22)

- Fixed indent regression in wrapped `let` expressions
- Fixed failure to remove `return` in `get` accessors

## [0.43.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.43.0) (2019-12-18)

- Added per-line warning when running in `--lint` mode
- Significantly improved Xcode integration when running as a build step in `--lint` mode
- Added `--lenient` option to suppress errors when running in `--lint` mode
- Fixed bug where required `self` was sometimes incorrectly removed inside a trailing closure
- Improved `wrap` rule heuristic for prioritizing where a line should be broken
- Fixed bug in `typeSugar` rule affecting namespaced types

## [0.42.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.42.0) (2019-11-30)

- Added `wrap` rule for automatic wrapping of long statements or expressions based on `--maxwidth` option
- Fixed bug with `braces` rule inserting a redundant blank line at the start of nested scopes

## [0.41.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.41.2) (2019-11-27)

- Fixed bug with `trailingCommas` rule incorrectly inserting a comma into wrapped collection type expressions

## [0.41.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.41.1) (2019-11-25)

- Fixed bug with `wrapArguments` rule incorrectly wrapping code inside interpolated String expressions

## [0.41.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.41.0) (2019-11-23)

- The `wrapArguments` rule can now automatically wrap functions and collections to `--maxwidth`
- Added `—maxwidth` option to specify the width at which code should wrap (currently only used by `wrapArguments` rule)
- Added `—tabwidth` option to help with code indenting and wrapping when using tabs for indent
- Fixed indenting of code wrapped after the `in` in a `for...in` loop
- Fixed indenting of code wrapped before the `is` in an expression
- Added version check for `redundantBackticks` rule to support fixes in Swift 5
- Fixed error when parsing escaped triple-quote in a multiline string
- Fixed bug where a multiline comments before an opening brace could result in corrupted output
- CLI will now fail if .swiftformat file contains an invalid option, instead of ignoring it
- Added support for formatting Swift package manifest files using Xcode Extension

## [0.40.14](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.14) (2019-10-28)

- The `redundantReturn` rule no longer incorrectly removes `return` inside `catch let` statements
- The `andOperator` rule no longer replaces `&&` with `,` inside function builder blocks
- Fixed a bug where `redundantFileprivate` rule incorrectly made overridden `fileprivate init` methods private
- The `fileHeader` rule no longer strips tools version header from `Package.swift` files
- The `todos` rule now recognizes and fixes a wider variety of typos

## [0.40.13](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.13) (2019-10-10)

- The `redundantReturn` rule now removes `return` from functions and computed properties in Swift 5.1
- Fixed a bug with `let` hoisting

## [0.40.12](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.12) (2019-09-20)

- Fixed crash when compiling with Xcode 11
- Fixed `redundantFileprivate` rule breaking inner types
- Fixed `--quiet` option preventing formatting code to stdout

## [0.40.11](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.11) (2019-07-29)

- Added `--xcodeindentation` option to use Xcode-style indentation for guards and enums
- The `redundantNilInit` rule no longer removes `nil` for properties using property wrappers
- Fixed bug where `redundantParens` rule incorrectly stripped Void generic arguments
- The `void` rule is now correctly applied to generic type parameters

## [0.40.10](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.10) (2019-06-23)

- The `emptyBraces` rule no longer removes linebreaks in chained `else`/`catch` blocks
- Fixed duplicate `fileHeader` insertion when comment isn't followed by blank line
- SwiftFormat command-line tool no longer times out when encountering an empty file
- Fixed bug in `yodaConditions` rule affecting parenthesized subexpressions
- The `consecutiveBlankLines` rule no longer strips blank lines inside multiline string literals
- The `redundantObjc` rule no longer strips `@objc` annotation from `fileprivate` members
- The `{file}` placeholder in `fileHeader` templates now works correctly

## [0.40.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.9) (2019-05-27)

- Fixed another case of `redundantSelf` removing required `self` in closures
- Fixed behavior of `redundantSelf` in cases where `self` is shadowed
- The `redundantObjc` rule no longer strips `@objc` annotation from private members
- Fixed bug where `isEmpty` rule mangled expressions containing an array count
- The `redundantSelf` rule now correctly inserts `self` in code following a declaration
- Fixed bug where `—trailingclosures` option was being ignored
- Removed extra newline when printing content to stdout
- Fixed some bugs in the `fileHeader` rule

## [0.40.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.8) (2019-04-16)

- Fixed several bugs when using the `--self insert` option

## [0.40.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.7) (2019-04-12)

- Fixed postfix operator followed by `.` being incorrectly interpreted as infix
- Fixed bug with `andOperator` in repeat/while loops
- Fixed bug with `redundantFileprivate` affecting local subclasses
- Fixed regression with `--self insert` adding `self` to function parameter labels
- Case-differing imports are now preserved

## [0.40.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.6) (2019-04-10)

- Fixed a regression when parsing a generic type followed by `& SomeProtocol`
- Fixed bug where `--self insert` option failed to insert `self` in the line after a `let` or `var` statement
- Added `--unexclude` file paths option
- Added regression test project suite

## [0.40.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.5) (2019-04-08)

- Fixed indenting of comments before an `#if`/`#else` clause inside a `switch` statement
- Fixed indenting of `#if` statement followed by comment inside a `switch` statement
- Fixed bug in `self` removal when followed by a `switch` containing an `#ifdef`
- Fixed bug when tokenizing chevron operators
- Fixed bug when tokenizing generic declarations
- Added `init-only` support to explicitSelf inference
- Added inference for inline semicolons

## [0.40.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.4) (2019-03-23)

- Multiple instances of `--disable` or other comma-delimited config options are now merged instead of replacing previous
- The `redundantParens` rule no longer removes explicit double-parens used to suppress warnings inside `Selector(...)`
- The `trailingCommas` rule no longer breaks calls to `UICollectionView.performBatchUpdates()` 
- Fixed bug in `yodaConditions` rule that broke KeyPaths

## [0.40.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.3) (2019-03-19)

- Fixed some bugs with the `redundantFileprivate` rule relating to struct members
- The `redundantFileprivate` rule no longer affects members required for protocol conformance
- Fixed a bug with `yodaConditions` rule inside ternary expressions

## [0.40.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.2) (2019-03-19)

- Fixed a bug where the `redundantParens` rule incorrectly removed parens in a subscript or function invocation
- Fixed a bug with the `trailingClosures` rule removing parens inside some conditional expressions
- Fixed a bug in the `yodaConditions` rule that broke expressions containing subscripts
- Fixed the `--swiftversion` option, which was being ignored under some circumstances
- Fixed bug that caused the `--fragment` and `--conflictmarkers` options to be ignored
- Fixed a bug in the `redundantObjc` rule that incorrectly stripped `@objc` from nested enum types

## [0.40.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.1) (2019-03-16)

- Fixed bug where `--trailingclosures` would incorrectly remove parentheses before an opening brace
- Fixed SwiftFormat for Xcode appearance when running in dark mode on macOS 10.14 (Mojave)

## [0.40.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.40.0) (2019-03-14)

- Added `--trailingclosures` option for whitelisting functions that should use trailing closure syntax
- The `trailingClosures` rule now only applies to a safe subset of methods by default
- Enabled `trailingClosures`  rule by default (use `--disable trailingClosures` to opt out)
- SwiftFormat now infers values to use for indentation, linebreaks, etc. if the associated rules are disabled
- Added new `yodaConditions` rule that moves constant values to the right-hand-side of expressions
- The `--dryrun` and `--lint` modes now only list modified files when running in `--verbose` mode
- Added an automatic timeout for buggy rules, or if a rule gets stuck when processing malformed input
- Fixed a bug in the `wrapArguments` that could corrupt argument lists containing commented lines
- Fixed bug where `wrapArguments` sometimes rewrapped parenthesized expressions
- Rule documentation is now available programmatically via the command-line
- Improved command-line UI, providing additional feedback and more detail in error messages
- Simplified SwiftFormat for Xcode app interface (big thanks to @VinceBurn for the UI implementation)

## [0.39.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.5) (2019-03-06)

- Fixed bug in `braces` rule where closing brace was not wrapped onto a new line
- Fixed bug with `braces` rule affecting closures inside a `switch` statements
- Relative indentation is now preserved inside multiline comment blocks
- Fixed indenting of `switch` cases using Swift 5's new `@unknown` attribute 
- Fixed some errors in documentation and warning messages
- The `.swift-version` file parser now permits cases like `3.0-PREVIEW-4`
- Fixed the performance test target, which was broken in Xcode 10.1

## [0.39.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.4) (2019-03-03)

- Added support for Swift 5's new raw string syntax
- Now correctly detects .swiftformat and .swift-version files placed anywhere in the input path
- The swiftformat command-line tool will no longer fail with an error if all matched files were ignored
- Fixed bug where `braces` rule failed to correctly apply Allman indenting to `switch`  statements
- Disabled the `isEmpty` rule again by default (you can enable it using `--enable isEmpty`)

## [0.39.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.3) (2019-02-15)

- Fixed a bug with `hoistPatternLet` rule for switch cases without a space
- Fixed a bug in the `typeSugar` rule when referencing nested types
- The `.swiftformat` configuration file type is now associated with the SwiftFormat for Xcode app

## [0.39.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.2) (2019-02-14)

- Fixed bug with indenting multi-line strings (introduced in 0.39.1)
- Fixed `redundantParens` bug (introduced in 0.39.1)
- Corrected documentation for `specifiers` rule

## [0.39.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.1) (2019-02-12)

- Fixed some cases where `redundantParens` failed to remove redundant parentheses
- Fixed rare instance where `indent` rule could incorrectly indent multiline string literals
- Added `Rules.md` file to the repository, providing permalinks to the documentation for each rule
- Rules documentation is now generated automatically from the SwiftFormat source code
- The Xcode Extension app now shows tooltips for rules in the Rules tab
- Fixed unit test failure in certain timezones

## [0.39.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.39.0) (2019-02-04)

- Added `redundantFileprivate` rule, which replaces `fileprivate` with `private` where possible
- Added `redundantExtensionACL` rule, to remove redundant access level keywords inside extensions
- Added `typeSugar` rule to replace Array, Dictionary and Optional types with shorthand forms
- Added `redundantObjc` rule, which removes unnecessary `@objc` annotations
- Added `—selfrequired` option for excluding `@autoclosure` arguments from `redundantSelf` rule
- The `isEmpty` rule is now enabled by default, as the risk of false positives is fairly low
- Enhanced the `fileHeader` rule with macros for file name and creation date
- Added AppleScript integration instructions (thanks to @Lutzifer)

## [0.38.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.38.0) (2019-01-29)

- Added support for building, running and testing SwiftFormat on Linux
- Added `--swiftversion` option for version-specific features 
- Added `anyObjectProtocol` rule to replace `class` with `AnyObject` in protocol declarations
- Added `redundantBreak` rule that removes unneeded breaks from switch cases
- Added `strongifiedSelf` rule which removed backticks in `if let ``self`` = self {}`
- The `redundantReturn` rule now removes void returns as well as ones that return a value
- Renamed some option values for consistency
- The Xcode Extension app now shows tooltips on Options tab

## [0.37.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.5) (2019-01-24)

- Fixed another regression in the `redundantReturn` rule

## [0.37.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.4) (2019-01-22)

- Fixed a regression in the `redundantReturn` rule, causing `return` to be removed when it shouldn't

## [0.37.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.3) (2019-01-19)

- Fixed bug in `wrapArguments` rule when using the `after-first` mode
- The `elseOnSameLine` rule no longer discards comments between clauses
- Fixed bug with `redundantBackticks` incorrectly stripping backticks inside keyPaths
- Wrapped closure chains inside a var declaration are now wrapped correctly
- Fixed some cases where `redundantReturn` rule was not being applied
- Fixed bug with `braces` rule affecting nested closures

## [0.37.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.2) (2019-01-01)

- Fixed codesign issues with bundled binaries
- Significantly improved performance when using globs/wildcards in `--exclude` rules
- Added glob syntax documentation to README file

## [0.37.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.1) (2018-12-18)

- Fixed a bug in the `isEmpty` rule when used inside a function argument
- Fixed bug where log messages included ANSI codes in non-terminal stderr output

## [0.37.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.37.0) (2018-12-17)

- Added `isEmpty` rule, which converts instances of `if foo.count == 0 {}` to `if foo.isEmpty` (disabled by default)
- Added `redundantLetError` rule, which removes `let error` from `catch let error {}` because it's implict
- The `todos` rule now converts `/// MARK:` to `// MARK:`, as the former isn't recognized by Xcode
- Fixed problem with the peformance tests target not building locally in Xcode 10.1

## [0.36.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.36.0) (2018-12-15)

- Fixed `--exclude` globs matching path prefix instead of whole path (this may break exclude paths that relied on the bug)
- Added new `andOperator` rule for replacing `&&` with `,` in `if`, `while` and `guard` statements
- Added `init-only` option for the `--self` argument, to enable explicit `self` only inside initializers
- Significantly improved performance when using complex `--exclude` rules
- Fixed infinite loop bug in `redundantSelf` rule relating to properties named "type"
- Fixed caching mechanism which was broken by an earlier Swift update
- Fixed spurious error message when `--exclude` option matched no files

## [0.35.10](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.10) (2018-12-13)

- Removed spurious `--verbose` argument warning
- Non-swift files are no longer logged as skipped in `--verbose` mode
- Fixed bug with comment indenting inside switch statements
- Fixed crash in wrapArguments rule

## [0.35.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.9) (2018-11-28)

- Fixed incorrect formatting of generic arguments containing function types
- Fixed inconsistent capitalization of the swiftformat executable in Package.swift

## [0.35.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.8) (2018-11-23)

- Updated `void` rule to support changes introduced in Swift 4
- Fixed a bug where `#endif` could be incorrectly indented if followed by a comment
- Added `--importgrouping` option to group imports inside by `@testable`
- Fixed a potential bug when loading options in the SwiftFormat for Xcode GUI

## [0.35.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.7) (2018-10-11)

- Fixed error when tokenizing an `enum` declaration with a `where` clause
- Fixed bug with spacing around an infix operator used before the `#file` keyword
- Fixed bug where `self` was incorrectly removed inside property getters/setters

## [0.35.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.6) (2018-09-29)

- Fixed bug where `self` could be incorrectly removed inside `#if` blocks
- Fixed some bugs when inserting or removing `self` inside `didSet` handlers
- The `strongOutlets` rule now ignores properties named `delegate` or `dataSource`
- The `wrapCollections` rule now behaves more consistently with nested collection literals
- Added "Open Recent" menu item to the SwiftFormat for Xcode app

## [0.35.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.5) (2018-09-08)

- Fixed a bug in `redundantParens` rule that affected closure types that take a single tuple argument

## [0.35.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.4) (2018-09-05)

- Added glob support (unix-style wildcard file pattern matching) for `--exclude` paths
- Added `--quiet` option to disable noncritical output messages when using the swiftformat CLI
- Fixed a bug where an `import func ...` statement caused the `redundantSelf` rule to loop indefinitely
- Disabled ANSI formatting for stderr if stdout is pointing to a terminal interface but stderr isn't
- SwiftFormat is now more tolerant of white space around paths in a .swiftformat configuration file
- A .swiftformat file generated by SwiftFormat will now always end with a linebreak 

## [0.35.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.3) (2018-08-21)

- Added `--closingparen` option for finer control over function argument wrapping
- Fixed bug in wraparguments/collections options inference
- Skipped files are now logged when running with the `--verbose` option
- SwiftFormat no longer mangles XCUITest tokens in comments by introducing spaces
- Dictionary values wrapped onto a different line from the key are now indented correctly
- Fixed a bug where automatic removal of spaces around range operators could introduce ambiguity
- Disabled ANSI formatting for non-terminal output
- Fixed typo in command-line help

## [0.35.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.2) (2018-08-10)

- Fixed a bug where `--rules` command incorrectly showed all rules as disabled
- Added close button to SwiftFormat for Xcode application window 

## [0.35.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.1) (2018-08-08)

- Added support for hierarchical config files with a standard naming convention (see README for details)
- You can now specify excluded file paths and file options such as `--symlinks` in configuration files 
- Standard .swiftformat configuration files are now visible in the SwiftFormat for Xcode open/save dialogs
- The .swiftformat configuration file can now contain comments, which are marked using a hash (#) character
- Improved cache invalidation. It should no longer be necessary to disable the cache in some cases
- Removed Indent from the SwiftFormat for Xcode options, as this is configured using Xcode project settings
- Fixed indent inference (really this time!)

## [0.35.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.35.0) (2018-08-04)

- Added `--config` argument for loading an external config file using the command-line tool
- The `--inferoptions` command can now write the result to a config file using the `--output` option
- Added `emptyBraces` rule for removing blank lines inside empty `{}` pairs
- Fixed handling of spaces and other special characters inside the `--header` option when using config files
- Fixed parsing and serialization of `--header` option in Xcode Source Editor Extension
- Fixed a bug in the `specifiers` rule affecting enum cases whose name matches a specifier
- Fixed bug where `redundantSelf` could incorrectly remove `self` from a closure instead a case with a `where` clause
- Fixed indent inference, which would previously calculate the wrong indent value

## [0.34.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.34.1) (2018-08-01)

- Added `// swiftformat:disable:next` directive for temporarily disabling a rule on just the following line
- Fixed bug where the `// swiftformat:disable all` directive could result in file contents being stripped
- Fixed a bug where `--verbose` mode incorrectly reported which rules were applied to each file
- Reset to Defaults menu item in SwiftFormat for Xcode now correctly resets the Infer Format Options setting

## [0.34.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.34.0) (2018-07-30)

- You can now configure format options for the Xcode Source Editor Extension (big thanks to @vinceburn for this feature)
- Restored ability to build the swiftformat command-line app using Xcode 9.2 on macOS Sierra
- Xcode Source Editor Extension no longer fails when using Playgrounds with multiple pages 
- The `--wrapelementss` option has been renamed to `--wrapcollections`
- Added new `--wraparguments preserve` and `--wrapcollections preserve` options
- Added `--fractiongrouping` & `--exponentgrouping` options
- Improved formatting of Xcode Source Editor Extension error messages
- Fixed a bug where parens were incorrectly removed after an image literal

## [0.33.13](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.13) (2018-07-25)

- Fixed bug where required parens were incorrectly removed from around a closure type
- Added `--lint` mode that is similar to `--dryrun` but returns a non-zero exit code if any files require formatting
- The swiftformat command-line tool now returns a non-zero exit code in the event of a fatal error while formatting

## [0.33.12](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.12) (2018-07-23)

- Added `swiftformat:disable all` and `swiftformat:enable all` directives
- Fixed a bug where redundant parens were not always removed correctly
- Fixed errors when parsing custom operators such as `<>`, `|>` or `<<>>`
- Fixed divide-by-zero crash when specifiying number groupings with a value of zero
- Rules are now always applied in alphabetical order to ensure consistency
- Fixed the `--conflictmarkers` command-line option

## [0.33.11](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.11) (2018-07-05)

- Fixed a bug where `--inferoptions` would always set `--self` to "insert" (this also affected the Xcode extension)
- Fixed bug with `redundantSelf` when parsing nested switch statements
- Fixed a bug in the `redundantParens` rule that incorrectly removed parens after an indexed tuple (e.g. `foo.1(bar)`)
- Spaces are now correctly removed around parens or square brackets after an indexed tuple

## [0.33.10](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.10) (2018-07-03)

- Fixed a bug where `sortedImports` rule could strip code between `import` statements
- Fixed a case where `self` was removed incorrectly inside a switch case condition

## [0.33.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.9) (2018-07-01)

- Fixed incorrect formatting of `!=` operator when used as a function reference
- Fixed some additional cases where `self` was not inserted or removed correctly

## [0.33.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.8) (2018-06-25)

- Fixed issue where `self` could be incorrectly inserted inside a `where` clause
- Fixed a bug where generics could be misidentified as greater-than / less-than operators
- Fixed formatting of `#if` blocks around case statements
- The `hoistPatternLet` rule no longer hoists the `let or `var` when there are no named variables
- Fixed nondeterministic behavior when applying spacing rules
- Fixed warning when compiling with Xcode 10 beta

## [0.33.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.7) (2018-05-18)

- Fixed an issue where headerdoc comments could be stripped by `fileHeader` rule
- Fixed a bug with handling absolute paths

## [0.33.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.6) (2018-04-18)

- Fixed a bug where a space could be incorrectly removed after a `try?` or `as?` operator
- Both the SwiftFormat command line tool and framework can now be built using Swift Package Manager
- Added .pre-commit-hook.yaml file for checking that formatter has been applied when committing
- The SwiftFormat command line tool can now be installed using Mint (see README for details) 

## [0.33.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.5) (2018-03-16)

- Fixed critical bug in `sortedImports` where code between blocks of import statements could be removed
- Fixed bug where wrapped arguments could be double-indented under some circumstances

## [0.33.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.4) (2018-02-26)

- Fixed a bug in the `unusedArguments` rule that could caused type names to get mangled in closure argument lists
- Fixed bug in `sortedImports` that could cause import statement to be moved above the file header comment

## [0.33.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.3) (2018-02-21)

- Fixed a bug in the `duplicateImports` rule that caused imports of specific types from the same module to be incorrectly stripped
- Fixed bugs with how the `duplicateImports` and `sortedImports` rules handle imports separated by semicolons or spanning multiple lines 
- Fixed a bug with `redundantParens` rule incorrectly removing parens around tuples whose first and last elements were closures
- Fixed a bug where the `redundantParens` rule incorrectly removed parens inside compound expressions

## [0.33.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.2) (2018-02-20)

- The `fileHeader` rule can now be disabled in an individual file by prefixing header with `// swiftformat:disable fileHeader`
- Fixed a bug in the `specifiers` rule that could mangle code if the previous line ended with certain identifiers
- Fixed typo in `--insertlines` deprecation warning message

## [0.33.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.1) (2018-02-10)

- Fixed bug preventing host app rule configuration from being read by the Xcode extension
- Added `duplicateImports` rule for removing duplicate import statements automatically
- Deprecated `--insertlines`/`--removelines` options - enable or disable the specific rules instead
- Fixed deprecation warnings in Swift 4.1 / Xcode 9.3

## [0.33.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.33.0) (2018-02-01)

- Added rules configuration UI to the Xcode Source Editor Extension (thanks @vinceburn and @tonyarnold!)
- Added `blankLinesAtStartOfScope` rule for removing leading blank lines at the start of functions, classes, etc
- Fixed indenting of blank lines within commented code blocks
- Added CONTRIBUTING.md

## [0.32.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.32.2) (2018-01-12)

- Fixed bug with parsing spaces inside interpolated values in multiline string literals
- Added instructions for using SwiftFormat on a CI server with Danger

## [0.32.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.32.1) (2017-12-07)

- Added `--dryrun` option, for testing SwiftFormat without making any file changes
- Fixed Xcode plugin, which was not deployed correctly in the previous release
- Fixed `spaceAroundOperators` rule not inserting space after a switch case or default clause colon

## [0.32.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.32.0) (2017-11-29)

- Added `swiftformat:` comment directives for enabling/disabling rules inside a source file (see README for details)
- Added `blankLinesAroundMark` rule, which inserts a blank line before and after a `// MARK:` comment
- When using the `--self insert` option, `self` is now inserted automatically in more places than it could be before
- Fixed some bugs in the `redundantSelf` rule that caused `self` not to be removed in some cases when it should
- Exposed the command-line formatting functions as part of the public API when using the SwiftFormat framework

## [0.31.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.31.0) (2017-11-24)

- Switched to a more conventional MIT license
- Added `strongOutlets` rule that removes weak from `@IBOutlet` properties in accordance with Apple guidelines
- Added `sortedImports` rule for sorting `import` statements alphabetically
- Fixed warnings in Xcode 9.1 and dropped support for compiling framework with Swift 3.1
- Fixed a bug where a double quote was incorrectly inserted into multiline strings
- Fixed a bug where the `--comments ignore` option was ignored for comments inside `switch` statements
- Code that has been temporarily commented out should no longer be re-indented

## [0.30.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.30.2) (2017-11-19)

- Fixed incorrect indenting of case statements for cases with `where` clauses containing `<` operator
- Fixed bug where parens were incorrectly removed around closures in loop or branch conditions
- Added compatibility workaround for `self` being incorrectly removed in tests that use the Nimble framework

## [0.30.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.30.1) (2017-11-10)

- Fixed error when parsing a subscript with default value inside a `switch` statement
- Nil default values are no longer removed inside `Codable` structs/classes, as this can break the implementation

## [0.30.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.30.0) (2017-10-27)

- Space is now inserted between the operator name and opening paren in an operator function declaration
- Added `--operatorfunc` option to control whether operator should be followed by a space in a function declaration
- Added `--elseposition` option to control whether `else`, `catch` & `while` should appear on same line as preceding `}`
- Added `--indentcase` option to control whether `case` statements should be indented inside a `switch`
- Comments immediately before a `default:` clause are now indented level with the `default` keyword
- Fixed bug where backticks would be incorrectly removed when using ``Any`` as an identifier
- Error messages are now displayed correctly in the Xcode editor extension
- Added test coverage statistics using Slather and Coveralls

## [0.29.9](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.9) (2017-10-22)

- Fixed critical bug where `hoistPatternLet` rule could corrupt tuples in a switch case clause
- Comments immediately before a case statement are now indented level with the case

## [0.29.8](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.8) (2017-10-11)

- Fixed bug where space was incorrectly removed around postfix/suffix range operators

## [0.29.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.7) (2017-10-08)

- Added support for Swift 4 keyPath syntax

## [0.29.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.6) (2017-09-21)

- Fixed bug in `hoistPatternLet` rule when formatting `case let` patterns with outer parens
- The `redundantParens` rule now correctly removes the outer parens in the aforementioned case
- Fixed performance regression introduced in 0.29.5

## [0.29.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.5) (2017-09-04)

- Fixed bounds crash when parsing an empty string literal at the end of a file
- SwiftFormat now compiles without modification in Xcode 9 using Swift 3.2 or 4.0

## [0.29.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.4) (2017-08-21)

- Fixed a bug where `self` could be incorrectly inserted if local variable is declared inside an `#if` block

## [0.29.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.3) (2017-07-31)

- Added support for Swift 4's multi-line string literal syntax
- Fixed a bug with handling inline comments inside an array literal

## [0.29.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.2) (2017-07-03)

- Fixed critical bug where space was incorrectly inserted around unary range operators
- Fixed bug where `self` could be incorrectly inserted before `type(of:)` if using `--self insert` option
- Fixed space being incorrectly inserted after postfix operator inside a subscript or collection literal
- Wrapped `case is Type` statements are now indented correctly

## [0.29.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.1) (2017-06-29)

- Fixed bug where `redundantInit` rule removed a required init in some cases

## [0.29.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.29.0) (2017-06-20)

- Changed specifier order from `private(set) public` to `public private(set)`
- Added `redundantInit` rule to remove explict `init` references where they aren't needed
- Fixed indentation of class declarations with protocols wrapped onto multiple lines

## [0.28.6](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.6) (2017-05-31)

- Fixed bug where consecutive `if` statements containing `<` and `>` were misidentified as a generic argument list
- Fixed space being removed between a closure capture list and subsequent arguments under some circumstances
- Fixed extra space added before prefix operators inside brackets or parens

## [0.28.5](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.5) (2017-05-14)

- The `redundantParens` rule no longer removes parens after a function call inside a `where` clause
- Fixed bug where nil default value was incorrectly removed from lazy var declarations

## [0.28.4](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.4) (2017-04-26)

- Fixed bug where `self` was incorrectly inserted inside an `if case let` condition
- Fixed incorrect insertion of `self` inside a pattern let clause

## [0.28.3](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.3) (2017-04-20)

- Fixed bug where `self` was incorrectly removed in a closure immediately after a var declaration
- Fixed incorrect insertion of `self` before a subscript `get` or `set` block
- Fixed incorrect insertion of `self` after an `import class` statement
- Fixed bug where `self` was not inserted after a return statement

## [0.28.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.2) (2017-03-30)

- Fixed error when parsing an `enum` declaration inside a `switch` statement
- Fixed incorrect removal of backticks when accessing an overloaded `Type` member

## [0.28.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.1) (2017-03-28)

- Fixed a bug where `redundantSelf` rule incorrectly removed `self` after a `repeat...while` loop
- Fixed some bugs where `--self insert` option wrongly added `self` in places it shouldn't have
- Improved the documentation of rules and options in the README file and command-line help

## [0.28.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.28.0) (2017-03-24)

- Added `--self insert` option to optionally insert `self` when accessing member variables/functions
- The `--self` and `--stripunusedargs` arguments can now be inferred automatically using `--inferoptions`
- SwiftFormat now detects and rejects source files that contain merge conflict markers
- Added `--conflictmarkers` option to optionally ignore conflict markers (e.g. if they clash with a custom operator)
- The `redundantSelf` rule now correctly strips `self` from computed var setters and getters
- The `redundantSelf` rule now handles static and class variables/functions correctly
- Fixed a potential bug where command-line tool might get stuck in an infinite loop
- Fixed a bug where a invalid source code could causes variables to be incorrectly removed
- Fixed some bugs in error reporting

## [0.27.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.27.1) (2017-03-21)

- Fixed trailing space that was incorrectly added to blank lines when `redundantSelf` rule is disabled
- Fixed a bug where `self` could be incorrectly removed when using nested function declarations
- Fixed a bug where `self` could be incorrectly removed inside class functions
- Improved formatting and inferoptions performance

## [0.27.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.27.0) (2017-03-17)

- Added `--exclude` command-line option for excluding specific files or folders from formatting
- Improved grouping and logging of formatting errors when running in `--verbose` mode
- Fixed a bug when using prefix operators with with shorthand class or enum members like `-.someValue`
- Fixed some more cases where `self` was incorrectly removed, or wasn't removed when it should have been
- Fixed some cases where backtick escaping was incorrectly removed around reserved words
- Fixed a bug where `--patternlet inline` could incorrectly move `let` inside a tuple assignment
- Fixed parsing of custom operators containing chevrons, e.g. `<?>`
- Fixed redundant `return` not being removed from closures in a var declaration
- Fixed a performance regression introduced in version 0.26.2
- Fixed bug where `Void()` literal was replaced by `()()` when using `--empty tuple`

## [0.26.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.26.2) (2017-03-15)

- Fixed critical bug where `return` was incorrectly removed after a `#selector` or `#keyPath` directive
- Fixed several more critical cases where `self` could be incorrectly removed
- Fixed case where identifier could be mistaken for a keyword after `self` was removed
- Fixed some cases where `self` should have been removed but wasn't
- Added tvOS support to the podspec

## [0.26.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.26.1) (2017-03-14)

- Fixed critical bug where `self` could be incorrectly removed inside lazy var declarations

## [0.26.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.26.0) (2017-03-13)

- Added `redundantSelf` rule for removing the `self` prefix from member references in cases where it isn't needed
- Added `--verbose` command-line option for tracking which rules were applied to each file
- Added `--patternlet` command-line option for toggling behavior of the `hoistPatternLet` rule
- Fixed bug where escaped arguments were treated as unused
- Fixed some `unusedArguments` cases
- The `redundantBackticks` rule now handles more cases

## [0.25.2](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.25.2) (2017-03-09)

- Fixed bug where `return` keyword could be incorrectly removed inside a conditional statement
- Fixed bug where backtick escaping would be incorrectly removed from `Self`

## [0.25.1](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.25.1) (2017-03-08)

- Fixed bug where unused arguments in a failable initializer could be incorrectly formatted
- Fixed bug where backtick escaping would be incorrectly removed from certain reserved identifiers

## [0.25.0](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.25.0) (2017-03-07)

- The `stripHeaders` rule is now `fileHeaders`, which can strip or replace header comments with a template (see README)
- Added `hoistPatternLet` rule that moves `let` and `var` to the beginning of `switch/case` patterns
- Added `redundantReturn` rule that strips the `return` keyword from single-line closures
- Added `redundantBackticks` rule that removes unnecessary backtick escaping of keywords

## [0.24.7](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.24.7) (2017-02-28)

- Fixed a bug where switch cases containing a `..<` operator were parsed incorrectly, resulting in wrong indentation
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
- Fixed issue where console text appeared as black instead of the user's chosen default color

## [0.23](https://github.com/nicklockwood/SwiftFormat/releases/tag/0.23) (2017-01-09)

- You can now specify a whitelist of specific rules to apply using the `--rules` option
- Input files are now processed concurrently, yielding a ~2x speed improvement
- SwiftFormat now continues if it encounters an error when processing multiple files
- Improved error messaging, and added color-coding to the command-line output
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
- Fixed bug with spacing after an `@convention()` attribute
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

- Added `allman` command line option to enable Allman-style indenting instead of default K&R style
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
- Added `void` rule for normalizing how `Void` return values are represented
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
- Fixed incorrect indenting of closures after an `if` statement, and other braced clauses

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

- Fixed bug where parsing would fail if a `switch/case` statement contained `default` or `case` identifiers (valid in Swift 3)

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
