[![Travis](https://img.shields.io/travis/nicklockwood/Sprinter.svg)](https://travis-ci.org/nicklockwood/Sprinter)
[![Coveralls](https://coveralls.io/repos/github/nicklockwood/Sprinter/badge.svg)](https://coveralls.io/github/nicklockwood/Sprinter)
[![Swift 3.2](https://img.shields.io/badge/swift-3.2-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Swift 4.0](https://img.shields.io/badge/swift-4.0-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

# Sprinter

- [Introduction](#introduction)
	- [What?](#what)
	- [Why?](#why)
	- [How?](#how)
- [Usage](#usage)
    - [Installation](#installation)
    - [Integration](#integration)
    - [Localization](#localization)
    - [Thread Safety](#thread-safety)
    - [Advanced Usage](#advanced-usage)


# Introduction

## What?

Sprinter is a library for Mac and iOS for formatting strings at runtime using the printf / NSLog format token conventions.

The aim is to provide a type-safe, Swift-friendly interface for string formatting that is fully compatible with the printf specification, as well as Apple's proprietary extensions for working with Objective-C data types.

The name "Sprinter" is derived from "String-Printer", just like the `sprintf` function in the C standard library.


## Why?

Although Swift already offers string formatting support in the form of the `String(format:arguments:)` initializer, Swift's support is a fairly crude wrapper around the Objective-C API, and lacks support for some of the standard printf formatting features and data types. For example, there is no way to use the following format string in Swift:

    "Hello %s, how are you?"
    
Because the `%s` token expects a C string (a pointer to a zero-terminated array of `CChar`), which the Swift `String(format:arguments:)` method won't accept. Instead, you must use the platform-specific `%@` token instead, which limits reusability of strings between platforms.

Swift also provides no way to validate or inspect format strings. If the format contains a typo, or the format arguments don't match the ones in your code, the string will be displayed incorrectly at runtime, or worse, may crash or cause silent memory corruption.

Sprinter solves these issues by exposing the argument types for each format string, so you can write runtime validation logic and handle errors gracefully.

The Sprinter library could also be used as the basis for unit tests that validate your strings at build time, or even as part of a code generation pipeline to provide strongly-typed string properties and methods.


## How?

Sprinter implements a robust string format parser based on the original [IEEE printf spec](http://pubs.opengroup.org/onlinepubs/009695399/functions/printf.html) along with [Apple's additions](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for Objective-C. It makes use of Swift's string formatter internally, but performs pre-validation and type conversion of arguments to ensure that invalid types are never passed to the underlying implementation.

Sprinter includes a comprehensive test suite to ensure spec compliance, and output compatibility with Apple's formatter.


# Usage

## Installation

The entire Sprinter API is encapsulated in a single file, and everything public is prefixed or namespaced, so you can simply drag the `Sprinter.swift` file into your project to use it. If you prefer, there's a framework for Mac and iOS that you can import, or you can use CocoaPods, Carthage, or Swift Package Manager on Linux.

To install Sprinter using CocoaPods, add the following to your Podfile:

	pod 'Sprinter', '~> 0.2.0'

Sprinter works with Swift 3.2 and 4.x and supports iOS 9 or macOS 10.0 and above


## Integration

To format a string using Sprinter, you first create a `FormatString` instance, as follows:

```swift
let formatString = try FormatString("I have %i apples and %i bananas")
```

Note the `try` keyword - the `FormatString` initializer performs validation of the string, and will throw an error if the format is invalid. Once you have constructed the formatString object, you can use the `print()` method to output the formatted string. The `print()` method is variadic, which is convenient for passing arguments. There is also a second form that accepts a single array of arguments.

You would use the `print()` method as follows:

```swift
let string = try formatString.print(5, 6)
print(string) // I have 5 apples and 6 bananas
```

You'll notice that the `print()` function also requires `try`. This method will throw an error if the arguments you pass do not match the placeholders in the original format string. Errors thrown by either the `FormatString` initializer or the `print()` method will all be of type `FormatString.Error`, for example:

```swift
let formatString = try FormatString("I have %y apples") // throws FormatString.error.unexpectedToken("y")

let string = try FormatString("I have %i apples").print("foo") // throws FormatString.error.argumentMismatch(1, String.self, Int.self)
```

You can determine the required argument types before calling the `print()` method by using the `types` property of the `FormatString`, which returns an array of Swift Type values:

```swift
let types = formatString.types
print(types) // Int, Int
```

This is typically not useful at runtime (incorrect arguments would be a programming error that should be fixed before release), but it could be used in an automated test to verify that a given localized string key has the same argument types in each language.


## Localization

The `FormatString` constructor also takes an optional `locale` argument, which can be used to localize the output:

```swift
let french = try FormatString("I have %i apples", locale: Locale(identifier: "fr-FR"))
```

This will affect how locale-specific formatting and punctuation is displayed, for example:

```swift
let english = try FormatString("%'g", locale: Locale(identifier: "en-US"))
try print(english.print(1234.56)) // 1,234.56

let french = try FormatString("%'g", locale: Locale(identifier: "fr-FR"))
try print(french.print(1234.56)) // 1 234,56

let german = try FormatString("%'g", locale: Locale(identifier: "de-DE"))
try print(german.print(1234.56)) // 1.234,56
```

## Thread Safety

It is safe to create `FormatString` instances on a background thread.

Once created, a given `FormatString` instance is stateless, so the same instance can safely be used to print strings on multiple threads concurrently.


## Advanced Usage

It may seem cumbersome to have to create a `StringFormat` object before printing, but it serves two purposes:

1. It allows validation and type inspection of the string before the point of use. This means you can be confident that there will be no surprise errors when it is called.

2. The expensive string parsing and `NumberFormatter` initialization steps can be performed once and then stored, not repeated each time the string is displayed.

For these reasons, it's recommended that you store and re-use your `FormatString` objects. You can either do this up-front for all strings, or lazily the first time each string is displayed - whichever makes more sense for your app.

A good approach would be to create a wrapper function that encapsulates your app-specific string requirements. For example, you might want to ignore string format errors in production (since it's too late to fix by that point), and just display a blank string instead. Here is an example wrapper that you might use in your app:


```swift
private var cache = [String: FormatString]()
private let queue = DispatchQueue(label: "com.Sprinter")

func localizedString(_ key: String, _ args: Any...) -> String {
    do {
        var formatString: FormatString?
        queue.sync { formatString = cache[key] }
        if formatString == nil {
            formatString = try FormatString(NSLocalizedString(key, comment: ""), locale: Locale.current)
            queue.async { cache[key] = formatString }
        }
        return try formatString?.print(arguments: args) ?? ""
    } catch {
        // Crash in development, but not in production
        assertionFailure("\(error)")
        return ""
    }
}
```

This function provides:

* A convenient API for displaying keys from your `Localizable.strings` file
* Encapsulated error handling, which will crash in development but fail gracefully in production
* Thread-safe caching of `FormatString` instances for better performance

This is just an example approach, but it should work for most use cases.
