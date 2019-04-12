[![Travis](https://img.shields.io/travis/nicklockwood/Expression.svg)](https://travis-ci.org/nicklockwood/Expression)
[![Coveralls](https://coveralls.io/repos/github/nicklockwood/Expression/badge.svg)](https://coveralls.io/github/nicklockwood/Expression)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-lightgray.svg)]()
[![Swift 3.4](https://img.shields.io/badge/swift-3.4-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Swift 4.2](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

- [Introduction](#introduction)
	- [What?](#what)
	- [Why?](#why)
	- [How?](#how)
- [Usage](#usage)
    - [Installation](#installation)
    - [Integration](#integration)
- [Symbols](#symbols)
	- [Variables](#variables)
	- [Operators](#operators)
	- [Functions](#functions)
	- [Arrays](#arrays)
- [Performance](#performance)
	- [Caching](#caching)
	- [Optimization](#optimization)
- [Standard Library](#standard-library)
	- [Math Symbols](#math-symbols)
    - [Boolean Symbols](#boolean-symbols)
- [AnyExpression](#anyexpression)
    - [Usage](#usage-1)
    - [Symbols](#symbols-1)
    - [Literals](#literals)
    - [Anonymous Functions](#anonymous-functions)
    - [Linux Support](#linux-support)
- [Example Projects](#example-projects)
    - [Benchmark](#benchmark)
	- [Calculator](#calculator)
	- [Colors](#colors)
    - [Layout](#layout)
    - [REPL](#repl)

# Introduction

## What?

Expression is a Swift framework for evaluating expressions at runtime on Apple and Linux platforms

The Expression library is split into two parts:

1. The `Expression` class, which is similar to Foundation's built-in `NSExpression` class, but with better support for custom operators, a more Swift-friendly API, and superior performance.

2. `AnyExpression`, an extension of Expression that handles arbitrary types and provides additional built-in support for common types such as `String`, `Dictionary`, `Array` and `Optional`.


## Why?

There are many situations where it is useful to be able to evaluate a simple expression at runtime. Some are demonstrated in the example apps included with the library:

* A scientific calculator
* A CSS-style color string parser
* A basic layout engine, similar to AutoLayout

But there are other possible applications, e.g.

* A spreadsheet app
* Configuration (e.g. using expressions in a config file to avoid data duplication)
* The basis for simple scripting language

(If you find any other use cases, let me know and I'll add them)

Normally these kind of calculations would involve embedding a heavyweight interpreted language such as JavaScript or Lua into your app. Expression avoids that overhead, and is also more secure as it reduces the risk of arbitrary code injection or crashes due to infinite loops, buffer overflows, etc.

Expression is fast, lightweight, well-tested, and written entirely in Swift. It is substantially faster than using JavaScriptCore for evaluating simple expressions (see the [Benchmark](#benchmark) app for a scientific comparison.

## How?

Expression works by parsing an expression string into a tree of symbols, which can then be evaluated at runtime. Each symbol maps to a Swift closure (function) which is executed during evaluation. There are built-in functions representing common math operations, or you can provide your own custom ones.

Although the `Expression` class only works with `Double` values, [AnyExpression](#anyexpression) uses a technique called [NaN boxing](https://wingolog.org/archives/2011/05/18/value-representation-in-javascript-implementations) to reference arbitrary data via the unused bit patterns in the IEEE floating point specification.


# Usage

## Installation

The `Expression` class is encapsulated in a single file, and everything public is prefixed or name-spaced, so you can simply drag the `Expression.swift` file into your project to use it. If you wish to use the [AnyExpression](#anyexpression) extension then include the `AnyExpression.swift` file as well.

If you prefer, there's a framework that you can import which includes both the `Expression` and `AnyExpression` classes. You can install this manually by drag and drop, or automatically using CocoaPods, Carthage, or Swift Package Manager.

To install Expression using CocoaPods, add the following to your Podfile:

```ruby
pod 'Expression', '~> 0.12'
```

To install using Carthage, add this to your Cartfile:

```
github "nicklockwood/Expression" ~> 0.12
```

To install using Swift Package Manager, add this to the `dependencies:` section in your Package.swift file:

```
.package(url: "https://github.com/nicklockwood/Expression.git", .upToNextMinor(from: "0.12.0")),
```


## Integration

You create an `Expression` instance by passing a string containing your expression, and (optionally) any or all of the following:

* A set of configuration options - used to enabled or disable certain features
* A dictionary of named constants - this is the simplest way to specify predefined constants
* A dictionary of named array constants - this is the simplest way to specify predefined arrays of related values
* A dictionary of symbols and `SymbolEvaluator` functions - this allows you to provide custom variables, functions or operators

You can then calculate the result by calling the `evaluate()` method.

**Note:** The `evaluate()` function for a given `Expression` instance is thread-safe, meaning that you can call it concurrently from multiple threads. `AnyExpression`'s evaluate method is also thread-safe *except on Linux* due to unavailability of the `objc_sync` APIs (see [Linux Support](#linux-support) section below).

By default, Expression already implements most standard math functions and operators, so you only need to provide a custom symbol dictionary if your app needs to support additional functions or variables. You can mix and match implementations, so if you have some custom constants or arrays and some custom functions or operators, you can provide separate constants and symbols dictionaries.

Here are some examples:

```swift
// Basic usage:
// Only using built-in math functions

let expression = Expression("5 + 6")
let result = try expression.evaluate() // 11

// Intermediate usage:
// Custom constants, variables and  and functions

var bar = 7 // variable
let expression = Expression("foo + bar + baz(5) + rnd()", constants: [
    "foo": 5,
], symbols: [
    .variable("bar"): { _ in bar },
    .function("baz", arity: 1): { args in args[0] + 1 },
    .function("rnd", arity: 0): { _ in arc4random() },
])
let result = try expression.evaluate()

// Advanced usage:
// Using the alternative constructor to dynamically hex color literals

let hexColor = "#FF0000FF" // rrggbbaa
let expression = Expression(hexColor, pureSymbols: { symbol in
    if case .variable(let name) = symbol, name.hasPrefix("#") { {
        let hex = String(name.characters.dropFirst())
        guard let value = Double("0x" + hex) else {
            return { _ in throw Expression.Error.message("Malformed color constant #\(hex)") }
        }
        return { _ in value }
    }
    return nil // pass to default evaluator
})
let color: UIColor = {
    let rgba = UInt32(try expression.evaluate())
    let red = CGFloat((rgba & 0xFF000000) >> 24) / 255
    let green = CGFloat((rgba & 0x00FF0000) >> 16) / 255
    let blue = CGFloat((rgba & 0x0000FF00) >> 8) / 255
    let alpha = CGFloat((rgba & 0x000000FF) >> 0) / 255
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
}()
```

Note that the `evaluate()` function may throw an error. An error will be thrown automatically during evaluation if the expression was malformed, or if it references an unknown symbol. Your custom symbol implementations may also throw application-specific errors, as in the colors example above.

For a simple, hard-coded expression like the first example there is no possibility of an error being thrown, but if you accept user-entered expressions, you must always ensure that you catch and handle errors. The error messages produced by Expression are detailed and human-readable (but not localized).

```swift
do {
    let result = try expression.evaluate()
    print("Result: \(result)")
} catch {
    print("Error: \(error)")
}
```

When using the `constants`, `arrays` and `symbols` dictionaries, error message generation is handled automatically by the Expression library. If you need to support dynamic symbol decoding (as in the hex color example earlier), you can use the `init(impureSymbols:pureSymbols)` initializer, which is a little bit more complex.

The `init(impureSymbols:pureSymbols)` initializer accepts a pair of lookup functions that take a `Symbol` and return a `SymbolEvaluator` function. This interface is very powerful because it allows you to dynamically resolve symbols (such as the hex color constants in the colors example) without needing to create a dictionary of all possible values in advance.

For each symbol, your lookup functions can return either a `SymbolEvaluator` function, or nil. If you do not recognize a symbol, you should return nil so that it can be handled by the default evaluator. If neither lookup function matches the symbol, and it is not one of the standard math or boolean functions, `evaluate()` will throw an error.

In some cases you may recognize a symbol, but be *certain* that it is incorrect, and this is an opportunity to provide a more specific error message than Expression would generate by default. The following example matches a function `bar` with an arity of 1 (meaning that it takes one argument). This will only match calls to `bar` that take a single argument, and will ignore calls with zero or multiple arguments.

```swift
switch symbol {
case .function("bar", arity: 1):
    return { args in args[0] + 1 }
default:
    return nil // pass to default evaluator
}
```

Since `bar` is a custom function, we know that it should only take one argument, so it's more helpful to throw an error if it is called with the wrong number of arguments, rather than returning nil to indicate that the function doesn't exist. That would look something like this:

```swift
switch symbol {
case .function("bar", let arity):
    guard arity == 1 else {
        return { _ in throw Expression.Error.message("function bar expects 1 argument") }
    }
    return { arg in args[0] + 1 }
default:
    return nil // pass to default evaluator
}
```

**Note:** Newer versions of Expression can correctly report trivial arity errors like this anyway, so this is a slightly contrived example, but this approach may be useful for other types of error, such as when arguments are out of range, or the wrong type.


# Symbols

Expressions are formed from a mixture of numeric literals and *symbols*, which are instances of the `Expression.Symbol` enum type. The built-in math and boolean libraries define a number of standard symbols, but you are free to define your own.

The `Expression.Symbol` enum supports the following symbol types:

## Variables

```swift
.variable(String)
```

This is an alphanumeric identifier representing a constant or variable in an expression. Identifiers can be any sequence of letters and numbers, beginning with a letter, underscore (_), dollar symbol ($), at sign (@) or hash/pound sign (#).

Like Swift, Expression allows unicode characters in identifiers, such as emoji and scientific symbols. Unlike Swift, Expression's identifiers may also contain periods (.) as separators, which is useful for name-spacing (as demonstrated in the Layout example app).

The parser also accepts quoted strings as identifiers. Single quotes (') , double quotes (") , or backticks (`) may be used. Since `Expression` only deals with numeric values, it's up to your application to map these string indentifiers to numbers (if you are using [AnyExpression](#anyexpression) then this is handled automatically).

Unlike regular identifiers, quoted identifiers can contain any unicode character, including spaces. Newlines, quotes and other special characters can be escaped using a backslash (\). Escape sequences are decoded for you, but the outer quotes are retained so you can distinguish strings from other identifiers.

Finally, unquoted identifiers are permitted to end with a single quote ('), as this is a common notation used in mathematics to indicate modified values. A quote at any other point in the identifier will be treated as the end of the name.

To verify that a given string is safe for use as an identifier, you can use the `Expression.isValidIdentifier()` method.

## Operators

```swift
.infix(String)
.prefix(String)
.postfix(String)
```

These symbols represent *operators*. Operators can be one or more characters long, and can contain almost any symbol that doesn't conflict with a valid identifier name, with some caveats:

* Comma (,) is a valid operator on its own, but cannot form part of a longer character sequence
* The bracket characters `[`, '(', '{', and their counterparts are reserved and cannot be used as operators
* An operator may begin with one or more dots (.) or hyphens (-), but a dot or hyphen cannot appear after any other character. The following are permitted:

    `...`, `..<`, `.`, `-`, `--`, `-=`, `-->`
    
    but the following are not:
    
    `+.`, `>.<`, `*-`, `-+-`, `<--`, `.-`, `-.`

To verify that a given character sequence is safe for use as an operator, you can use the `Expression.isValidOperator()` method.

You can overload existing infix operators with a post/prefix variant, or vice-versa. Disambiguation depends on the white-space surrounding the operator (which is the same approach used by Swift).

Any valid identifier may also be used as an infix operator, by placing it between two operands, or as a postfix operator, by placing it after an operand. For example, you could define `m` and `cm` as postfix operators when handling distance logic, or use `and` as a more readable alternative to the boolean `&&` operator.

Operator precedence follows standard BODMAS order, with multiplication/division given precedence over addition/subtraction. Prefix operators take precedence over postfix operators, which take precedence over infix ones. There is currently no way to specify precedence for custom operators - they all have equal priority to addition/subtraction.

Standard boolean operators are supported, and follow the normal precedence rules, with the caveat that short-circuiting (where the right-hand argument(s) may not be evaluated, depending on the left-hand-side) is not supported. The parser will also recognize the ternary `?:` operator, treating `a ? b : c` as a single infix operator with three arguments.

## Functions

```swift
.function(String, arity: Arity)
```

A function symbol is defined with a name and an `Arity`, which is the number of arguments that it expects. The `Arity` type is an enum that can be set to either `exactly(Int)` or `atLeast(Int)` for variadic functions. A given function name can be overloaded multiple times with different arities.

**Note:** `Arity` conforms to `ExpressibleByIntegerLiteral`, so for fixed-arity functions you can just write `.function("foo", arity: 2)` instead of `.function("foo", arity: .exactly(2))`

Functions are called by using their name followed by a comma-delimited sequence of arguments in parentheses. If the argument count does not match any of the specified arity variants, an `arityError` will be thrown.

Since function symbols must have a name, it is not directly possible to use anonymous functions in an expression (e.g. functions that are stored in a variable, or returned by another function).

There is syntax support for this however, if you implement the function call operator `.infix("()")`, which accepts one or more arguments, with the first being treated as the function to be called. This is of limited use in `Expression` (where values are all numeric) but [AnyExpression](#anyexpression) uses this approach to provide full support for [anonymous functions(#anonymous-functions).


## Arrays

```swift
.array(String)
```

Array symbols represent a sequence of values that can be accessed by index. Array symbols are referenced in an expression by using their name followed by an index argument in square brackets.

The simplest way to use arrays with `Expression` is to pass in a constant array value via the `arrays` initializer argument. For variable arrays, you can return an `.array()` symbol implementation via the `symbols` argument.
 
Expression also supports Swift-style array literal syntax like `[1, 2, 3]` and subscripting of arbitrary expressions like `(a + b)[c]`. Array literals map to the array literal constructor symbol `.function("[]", arity: .any)` and subscripting maps to the array subscripting operator `.infix("[]")`.

Because `Expression` cannot work with non-numeric types, neither the array literal constructor nor the array subscripting operator have default implementations in `Expression`, however both of these *are* implemented in [AnyExpression](#anyexpression)'s standard symbol library.


# Performance

## Caching

By default, Expression caches parsed expressions. The expression cache is unlimited in size. In most applications this is very unlikely to ever be a problem - expressions are tiny, and even the most complex expression you can imagine is probably well under 1KB, so it would take a lot of them to cause memory pressure - But if for some reason you do ever need to reclaim the memory used by cached expressions, you can do so by calling the `flushCache()` method:

```swift
Expression.flushCache())
```

The `flushCache()` method takes an optional string argument, so you can also remove a specific expression from the cache without clearing others:

```swift
Expression.flushCache(for: "foo + bar"))
```

If you'd prefer even more fine-grained control of caching, you can pre-parse the expression without caching it, then create the Expression instance from the pre-parsed expression, as follows:

```swift
let expressionString = "foo + bar"
let parsedExpression = Expression.parse(expressionString, usingCache: false)
let expression = Expression(parsedExpression, constants: ["foo": 4, "bar": 5])
```

By setting the `usingCache` argument to `false` in the code above, we avoid adding the expression to the global cache. You are also free to implement your own caching by storing the parsed expression and re-using it, which may be more efficient than the built-in cache in some cases (e.g. by avoiding thread management if your code is single-threaded).

A second variant of the `Expression.parse()` method accepts a `String.UnicodeScalarView.SubSequence` and optional list of terminating delimiter strings. This can be used to match an expression embedded inside a longer string, and leaves the `startIndex` of the character sequence in the right place to continue parsing once the delimiter is reached:

```swift
let expressionString = "lorem ipsum {foo + bar} dolor sit"
var characters = String.UnicodeScalarView.SubSequence(expression.unicodeScalars)
while characters.popFirst() != "{" {} // Read up to start of expression
let parsedExpression = Expression.parse(&characters, upTo: "}")
let expression = Expression(parsedExpression, constants: ["foo": 4, "bar": 5])
```

## Optimization

By default, expressions are optimized where possible to make evaluation more efficient. Common optimizations include replacing constants with their literal values, and replacing pure functions or operators with their result when all arguments are constant.

The optimizer reduces evaluation time at the cost of increased initialization time, and for an expression that will only be evaluated once or twice this tradeoff may not be worth it, in which case you can disable optimization using the `options` argument:

```swift
let expression = Expression("foo + bar", options: .noOptimize, ...)
```

On the other hand, if your expressions are being evaluated hundreds or thousands of times, you will want to take full advantage of the optimizer to improve your application's performance. To ensure you are getting the best out of Expression's optimizer, follow these guidelines:

* Always pass constant values via the `constants` or `arrays` arguments instead of as a variable in the `symbols` dictionary. Constant values can be inlined, whereas variables must be re-computed each time the function is evaluated in case they have changed.

* If your custom functions and operators are all *pure* - i.e. they have no side effects and always return the same output for a given set of argument values - then you should set the `pureSymbols` option for your expression. This option tells the optimizer that it's safe to inline any functions or operators in the `symbols` dictionary if all their arguments are constant. Note that the `pureSymbols` option does not affect variables or array symbols, which are never inlined.

* If your expressions may contain values which are constant, but where not all possible values can be computed in advance - e.g. encoded values such as in the hex colors example, or arbitrary key paths that must be looked up in a deep object graph - you can use the `init(pureSymbols:)` initializer to decode or look up just the specific values that are needed.


# Standard Library

## Math Symbols

By default, Expression supports a number of basic math functions, operators, and constants that are generally useful, independent of any particular application.

If you use a custom symbol dictionary, you can override any default symbol, or overload default functions with different numbers of arguments (arity). Any symbols from the standard library that you do not explicitly override will still be available.

To explicitly disable individual symbols from the standard library, you can override them and throw an exception:

```swift
let expression = Expression("pow(2,3)", symbols: [
    .function("pow", arity: 2): { _ in throw Expression.Error.undefinedSymbol(.function("pow", arity: 2)) }
])
try expression.evaluate() // this will throw an error because pow() has been undefined
```

If you are using the `init(impureSymbols:pureSymbols:)` initializer, you can fall back to the standard library functions and operators by returning `nil` for unrecognized symbols. If you do not want to provide access to the standard library functions in your expression, throw an error for unrecognized symbols instead of returning `nil`.

```swift
let expression = Expression("3 + 4", puresSymbols: { symbol in
    switch symbol {
    case .function("foo", arity: 1):
        return { args in args[0] + 1 }
    default:
        return { _ in throw Expression.Error.undefinedSymbol(symbol) }
    }
})
try expression.evaluate() // this will throw an error because no standard library operators are supported, including +
```

Here are the currently supported math symbols:

**constants**

```swift
pi
```

**infix operators**

```swift
+ - / * %
```

**prefix operators**

```swift
-
```

**functions**

```swift
// Unary functions

sqrt(x)
floor(x)
ceil(x)
round(x)
cos(x)
acos(x)
sin(x)
asin(x)
tan(x)
atan(x)
abs(x)

// Binary functions

pow(x,y)
atan2(x,y)
mod(x,y)

// Variadic functions

max(x,y,[...])
min(x,y,[...])
```

## Boolean Symbols

In addition to math, Expression also supports boolean logic, following the C convention that zero is false and any nonzero value is true. The standard boolean symbols are not enabled by default, but you can enable them using the `.boolSymbols` option:

```swift
let expression = Expression("foo ? bar : baz", options: .boolSymbols, ...)
```

As with the math symbols, all standard boolean operators can be individually overridden or disabled for a given expression using the `symbols` initializer argument.

Here are the currently supported boolean symbols:

**constants**

```swift
true
false
```

**infix operators**

```swift
==
!=
>
>=
<
<=
&&
||
```

**prefix operators**

```swift
!
```

**ternary operator**

```swift
?:
```


# AnyExpression

## Usage

`AnyExpression` is used in almost the exact same way as the `Expression` class, with the following exceptions:

* `AnyExpression`'s `SymbolEvaluator` functions accept and return `Any` instead of `Double`
* Boolean symbols and operators are enabled by default when you create an `AnyExpression`
* There is no separate `arrays` argument for the `AnyExpression` constructor. If you wish to pass an array or dictionary constant, you can add it to the `constants` dictionary like any other value type
* `AnyExpression` supports [anonymous functions[(#anonymous-functions), which can be any value of type `Expression.SymbolEvaluator` or `AnyExpression.SymbolEvaluator`
* You can also pass `Expression.SymbolEvaluator` or `AnyExpression.SymbolEvaluator` functions into `AnyExpression` using the constants dictionary, and these will behave just like ordinary function symbols

You can create and evaluate an `AnyExpression` instance as follows:

```swift
let expression = AnyExpression("'hello' + 'world'")
let result: String = try expression.evaluate() // 'helloworld'
```

Note the use of single quotes (') for string literals. `AnyExpression` supports single or double quotes for string literals. There is no difference between these, except that single quotes do not need to be escaped inside a Swift string literal.

Since `AnyExpression`'s `evaluate()` method has a generic return type, you will need to tell it the expected type. In the example above, we did this by specifying an explicit type for the `result` variable, but you could also do it by using the `as` operator (without ! or ?):

```swift
let result = try expression.evaluate() as String
```

The `evaluate` function has a certain amount of built-in leniency with respect to types, so if (for example) the expression returns a boolean, but you specify `Double` as the expected type, the type will be converted automatically, but if it returns a string and you ask for `Bool` then a type mismatch error will be thrown.

The currently supported automatic conversions are:

* T -> Optional<T>
* Numeric -> Numeric
* Array<Numeric> -> Array<Numeric>
* Numeric -> Bool
* Bool -> Numeric
* Any -> String

## Symbols

In addition to adding support for string literals, `AnyExpression` extends `Expression`'s standard library with some additional symbols for dealing with Optionals and null values:

* `nil` - the null literal
* `??` - the null coalescing operator

Optional unwrapping is automatic, so there is currently no need for the postfix `?` or `!` operators. `nil` (aka `Optional.none`) and `NSNull` are both treated the same way to avoid confusion when working with JSON or Objective-C API data.

Comparison operators like `==` and !=` are also extended to work with any `Hashable` type, and `+` can be used for string concatenation, as in the example above.

For `array` symbols, `AnyExpression` can use any `Hashable` type as the index. This means that `AnyExpression` can work with `Dictionary` values as well as `Array`s and `ArraySlice`s.

## Literals

As mentioned above, `AnyExpression` supports the use of quoted string literals, delimited with either single quotes (') or double quotes ("). Special characters inside the string can be escaped using a backlash (\).

`AnyExpression` supports array literals defined in square brackets, e.g. `[1, 2, 3]` or `['foo', 'bar', 'baz']`. Array literals can contain a mixture of value types and/or sub-expressions.

You can also create range literals using the `..<` and `...` syntaxes. Closed, half-open and partial ranges are supported. Ranges work with either `Int` or `String.Index` values, and can be used in conjunction with subscripting syntax for slicing arrays and strings.

## Anonymous Functions

In addition to ordinary named function symbols, `AnyExpression` also calling anonymous functions, which are values of type `Expression.SymbolEvaluator` or `AnyExpression.SymbolEvaluator` that can be stored in a constant or returned from a sub-expression.

You can pass anonymous functions into `AnyExpression` by using a constant value instead of a `.function()` symbol, but note that this approach does not allow you the option of overloading functions with the same name by arity.

Unlike function symbols, anonymous functions do not support overloading, but you can use a switch inside the function body to implement different behaviors depending on the number of arguments. You should also throw an `arityMismatch` error if an unsupported number of arguments is passed, as this cannot be detected automatically, e.g.

```swift
let bar = { (args: [Any] throws -> Any in
    switch args.count {
    case 1:
        // behavior 1
    case 2:
        // behavior 2
    default:
        throw Expression.Error.arityMismatch(.function("bar", arity: 2))
    }
}

// static function foo returns anonymous function bar, which is called in the expression
let expression = AnyExpression("foo()(2)", symbols: [
    .function("foo"): { _ in bar }
])
```

**Note:** anonymous functions are assumed to be impure, so they are never eligible for inlining, regardless of whether you use the `pureSymbols` option.

## Linux Support

AnyExpression works on Linux, with the following caveats:

- The `evaluate()` function is not thread-safe on Linux due to unavailability of the `objc_sync` APIs. Even multiple copies of the same expression cannot safely be evaluated concurrently. This is a bit counter-intuitive because `AnyExpression` is a struct, so it has copy semantics, but internally these copies all share a reference to the same underlying `Expression` instance.

- `AnyExpression` doesn't support `NSString` bridging due to a limitation of Linux Foundation. If you want to use `AnyExpression` with `NSString` values then you'll have to manually convert them to `String` before and after evaluation.


# Example Projects

## Benchmark

The Benchmark app runs a set of test expressions using `Expression`, `AnyExpression`, `NSExpression` and JavaScriptCore's `JSContext` respectively. It then times how long it takes to parse and evaluate the expressions, and displays the result in a table.

Times are shown in either microseconds (µs) or milliseconds. The fastest result in each category is displayed in green, and the slowest in red.

For accurate results, the Benchmark app should be run in release mode on a real device. You can pull down on the table to refresh the test results. Tests are run on the main thread, so don't be surprised if the display locks up briefly while refreshing.

In my own tests, Expression was consistently the fastest implementation, and JavaScriptCore was consistently the slowest, both for initial setup and for evaluation once the context has been initialized.

## Calculator

Not much to say about this. It's a calculator. You can type mathematical expressions into it, and it will evaluate them and produce a result (or an error, if what you typed was invalid).

## Colors

The Colors example demonstrates how to use `AnyExpression` to create a (mostly) CSS-compliant color parser. It takes a string containing a named color, hex color or `rgb()` function call, and returns a UIColor object.

## Layout

This is where things get interesting: The Layout example demonstrates a crude-but-usable layout system, which supports arbitrary expressions for the coordinates of the views.

It's conceptually similar to AutoLayout, but with some important differences:

* The expressions can be as simple or as complex as you like. In AutoLayout every constraint uses a fixed formula, where only the operands are interchangeable.
* Instead of applying an arbitrary number of constraints between properties of views, each view just has a size and position that can be calculated however you like.
* Layout is deterministic. There is no weighting system used for resolving conflicts, and circular references are forbidden. Weighted relationships can be achieved using explicit multipliers.

Default layout values for the example views have been set in the Storyboard, but you can edit them live in the app by tapping a view and typing in new values.

Here are some things to note:

* Every view has a `top`, `left`, `width` and `height` expression to define its coordinates on the screen.
* Views have an optional `key` (like a tag, but string-based) that can be used to reference their properties from another view. 
* Any expression-based property of any view can reference any other property (of the same view, or any other view), and can even reference multiple properties.
* Every view has a bottom and right property. These are computed, and cannot be set directly, but they can be used in expressions.
* Circular references (a property whose value depends on itself) are forbidden, and will be detected by the system.
* The `width` and `height` properties can use the `auto` variable, which does nothing useful for ordinary views, but can be used with text labels to calculate the optimal height for a given width, based on the amount of text.
* Numeric values are measured in screen points. Percentage values are relative to the superview's `width` or `height` property.
* Remember you can use functions like `min()` and `max()` to ensure that relative values don't go above or below a fixed threshold.

This is just a toy example, but if you like the concept check out the [Layout framework](https://github.com/schibsted/layout) on Github, which takes this idea to the next level.

## REPL

The Expression REPL (Read Evaluate Print Loop) is a Mac command-line tool for evaluating expressions. Unlike the Calculator example, the REPL is based on `AnyExpression`, so it allows the use of any type that can be represented as a literal in Expression syntax - not just numbers.

Each line you type into the REPL is evaluated independently. To share values between expressions, you can define variables using an identifier name followed by `=` and then an expression, e.g:

```
foo = (5 + 6) + 7
```

The named variable ("foo", in this case) is then available to use in subsequent expressions.
