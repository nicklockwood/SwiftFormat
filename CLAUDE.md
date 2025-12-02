# SwiftFormat

SwiftFormat is a code formatting tool for Swift. It applies a set of rules to Swift source files, transforming them to follow consistent style conventions.

## Project Structure

- `Sources/Rules/` - Individual formatting rules (one file per rule)
- `Tests/Rules/` - Test cases for rules
- `Sources/Formatter.swift` - Core formatter class with token manipulation APIs
- `Sources/ParsingHelpers.swift` - Parsing helpers for Swift grammar (types, declarations, expressions, etc.)
- `Sources/FormattingHelpers.swift` - Higher-level formatting utilities
- `Sources/Options.swift` - Options for configuring the behavior of individual rules
- `Sources/OptionDescriptor.swift` - Command line flag configuration for rule options

## Building and Testing

```sh
# Build the project
swift build

# Run all tests
swift test

# Test a specific rule
./Scripts/test_rule.sh <ruleName>
```

## Adding New Rules

### Before You Start

**Read the helper files thoroughly.** Before writing any rule, familiarize yourself with the existing helpers:

- `Sources/Formatter.swift` - Token manipulation APIs
- `Sources/ParsingHelpers.swift` - Parsing helpers for types, declarations, expressions, properties, functions, etc.
- `Sources/FormattingHelpers.swift` - Higher-level formatting utilities
- `Sources/Declarations.swift` - Helpers related to individual declarations

You MUST review the APIs available in these files using:

```bash
$ rg "^    (func|var) " Sources/Formatter.swift Sources/FormattingHelpers.swift Sources/ParsingHelpers.swift Sources/Declaration.swift
```

Many rules can be implemented using existing helpers. Before writing custom token parsing code, verify no existing helper does what you need.

### Rule File Structure

Create a new file in `Sources/Rules/` named after your rule (e.g., `MyRule.swift`). Rules are defined as static properties on `FormatRule`:

```swift
//
//  MyRule.swift
//  SwiftFormat
//

import Foundation

public extension FormatRule {
    /// Brief description of what the rule does
    static let myRule = FormatRule(
        help: "Description shown in --help output."
    ) { formatter in
        // Rule implementation goes here. For example:
        formatter.forEach(.keyword("let")) { i, _ in
            // Process each occurrence
        }
    } examples: {
        """
        ```diff
        - before
        + after
        ```
        """
    }
}
```

Rule tests are implemented in `Tests/Rules/MyRuleTests.swift`.

### Best Practices

- **Minimal changes only.** Only modify tokens when an actual change is needed. Any modification triggers a lint error in `--lint` mode.
- **Preserve comments.** Prefer preserving code as-is if updating would require removing comments.
- **Keep it simple.** Write as little code as possible. If a change dramatically increases complexity, consider asking if it should be de-scoped.
- **Define local helpers** in extensions on `Formatter` at the bottom of the rule file. Mark them `internal` for discoverability. Move helpers used by multiple rules to `ParsingHelpers.swift`. Parsing code should almost always be factored out into a rule-specific helper (or later a shared helper if necessary) rather than being implemented directly in the rule implementation closure.

**Always use Formatter APIs.** Never manipulate token arrays directly:

```swift
// ✓ Good - use Formatter APIs
formatter.insert(.space(" "), at: index)
formatter.removeToken(at: index)
formatter.replaceToken(at: index, with: .keyword("let"))

// ✗ Bad - array manipulation
var tokens = Array(formatter.tokens[start...end])
tokens.append(.space(" "))
formatter.replaceTokens(in: start...end, with: tokens)
```

**Never use raw index loops.** Always traverse tokens using helpers:

```swift
// ✓ Good - use traversal helpers
formatter.index(of: .nonSpaceOrCommentOrLinebreak, after: i)
formatter.index(of: .keyword("func"), before: i)
formatter.endOfLine(at: i)

// ✗ Bad - raw index manipulation
while i < formatter.tokens.count { i += 1 }
for i in 0..<formatter.tokens.count { ... }
```

### Writing Tests

Use the `testFormatting` helper defined in `XCTestCase` extensions:

```swift
func testMyRule() {
    let input = """
        // input code
        """
    let output = """
        // expected output
        """
    testFormatting(for: input, output, rule: .myRule)
}
```

- Create several test scenarios covering different cases, but don't exhaustively test every configuration.
- Use `testFormatting(for: input, [output], rules: [.myRule, .otherRule])` to test multiple rules together.
- Use `exclude: [.someRule]` if another rule conflicts with your test case. However, only exclude a rule from a test case if the test case would fail otherwise.
- ALways use multi-line string literals (""") for input and output code.

### Debugging

To debug a rule, run the existing tests or create new test cases. **NEVER** try to directly run SwiftFormat on a file via the command line.

Use print debugging as necessary to gather more context. Run individual test cases using:

```sh
swift test --filter <TestClassName>.<testMethodName>
```

### After Writing the Rule

1. **Run the rule tests:** `./Scripts/test_rule.sh <ruleName>`
2. **Run the full test suite:** `swift test`
3. **[VERY IMPORTANT] Review your code** - ensure it follows all best practices above
4. **[VERY IMPORTANT] Simplify further** - look for functionality that could be removed to reduce complexity

**Note:** Do not modify `Rules.md` directly. It's auto-generated when running the test suite. `MetadataTests` may fail after adding a new rule; re-run after metadata regenerates.

## See Also

@CONTRIBUTING.md
