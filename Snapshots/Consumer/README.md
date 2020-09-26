[![Travis](https://img.shields.io/travis/nicklockwood/Consumer.svg)](https://travis-ci.org/nicklockwood/Consumer)
[![Coveralls](https://coveralls.io/repos/github/nicklockwood/Consumer/badge.svg)](https://coveralls.io/github/nicklockwood/Consumer)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20|%20Linux-lightgray.svg)]()
[![Swift 5.0](https://img.shields.io/badge/swift-5.0-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

- [Introduction](#introduction)
    - [What?](#what)
    - [Why?](#why)
    - [How?](#how)
- [Usage](#usage)
    - [Installation](#installation)
    - [Parsing](#parsing)
    - [Character Sets](#character-sets)
    - [Transforming](#transforming)
    - [Common Transforms](#common-transforms)
    - [Typed Labels](#typed-labels)
    - [Forward References](#forward-references)
    - [Syntax Sugar](#syntax-sugar)
    - [White Space](#white-space)
    - [Error Handling](#error-handling)
- [Performance](#performance)
    - [Backtracking](#backtracking)
    - [Character Sequences](#character-sequences)
    - [Flatten and Discard](#flatten-and-discard)
- [Example Projects](#example-projects)
    - [JSON](#json)
    - [REPL](#repl)


# Introduction

## What?

Consumer is a library for Mac and iOS for parsing structured text such as a configuration file, or a programming language source file.

The primary interface is the `Consumer` type, which is used to programmatically build up a parsing grammar.

Using that grammar, you can then parse String input into an AST (Abstract Syntax Tree), which can then be transformed into application-specific data

## Why?

There are many situations where it is useful to be able to parse structured data. Most popular file formats have some kind of parser, typically either written by hand or by using code generation. 

Writing a parser is a time-consuming and error-prone process. Many tools exist in the C world for generating parsers, but relatively few such tools exist for Swift.

Swift's strong typing and sophisticated enum types make it well-suited for creating parsers, and Consumer takes advantage of these features.

## How?

Consumer uses an approach called *recursive descent* to parse input. Each `Consumer` instance consists of a tree of sub-consumers, with the leaves of the tree matching individual strings or characters in the input.

You build up a consumer by starting with simple rules that match individual words or values (known as "tokens") in your language or file format. You then compose these into more complex rules that match sequences of tokens, and so on until you have a single consumer that describes an entire document in the language you are trying to parse.


# Usage

## Installation

The `Consumer` type and its dependencies are encapsulated in a single file, and everything public is prefixed or name-spaced, so you can just drag `Consumer.swift` into your project to use it.

If you prefer, there's a framework for Mac and iOS that you can import which includes the `Consumer` type. You can install this manually, or by using CocoaPods, Carthage, or Swift Package Manager.

To install Consumer using CocoaPods, add the following to your Podfile:

```ruby
pod 'Consumer', '~> 0.3'
```

To install using Carthage, add this to your Cartfile:

```
github "nicklockwood/Consumer" ~> 0.3
```

To install using Swift Package Manage, add this to the `dependencies:` section in your Package.swift file:

```
.package(url: "https://github.com/nicklockwood/Consumer.git", .upToNextMinor(from: "0.3.0")),
```

## Parsing

The `Consumer` type is an enum, so you can create a consumer by assigning one of its possible values to a variable. For example, here is a consumer that matches the string "foo":

```swift
let foo: Consumer<String> = .string("foo")
```

To parse a string with this consumer, call the `match()` function:

```swift
do {
    let match = try foo.match("foo")
    print(match) // Prints the AST
} catch {
    print(error)
}
```

In this simple example above, the match will always succeed. If tested against arbitrary input, the match will potentially fail, in which case an Error will be thrown. The Error will be of type `Consumer.Error`, which includes information about the error type and the location in the input string where it occurred.

The example above is not very useful - there are much simpler ways to detect string equality! Let's try a slightly more advanced example. The following consumer matches an unsigned integer:

```swift
let integer: Consumer<String> = .oneOrMore(.character(in: "0" ... "9"))
```

The top-level consumer in this case is of type `oneOrMore`, meaning that it matches one or more instances of the nested `.character(in: "0" ... "9")` consumer. In other words, it will match any sequence of characters in the range "0" - "9".

There's a slight problem with this implementation though: An arbitrary sequence of digits might include leading zeros, e.g. "01234", which could be mistaken for an octal number in some programming languages, or even just be treated as a syntax error. How can we modify the `integer` consumer to reject leading zeros?

We need to treat the first character differently from the subsequent ones, which means we need two different parsing rules to be applied in *sequence*. For that, we use a `sequence` consumer:

```swift
let integer: Consumer<String> = .sequence([
    .character(in: "1" ... "9"),
    .zeroOrMore(.character(in: "0" ... "9")),
])
```

So instead of `oneOrMore` digits in the range 0 - 9, we're now looking for a single digit in the range 1 - 9, followed by `zeroOrMore` digits in the range 0 - 9. That means that a zero preceding a nonzero digit will not be matched.

```swift
do {
    _ = try integer.match("0123")
} else {
    print(error) // Unexpected token "0123" at 0
}
```

We've introduced another bug though - Although leading zeros are correctly rejected, "0" on its own will now also be rejected since it doesn't start with 1 - 9. We need to accept *either* zero on its own, *or* the sequence we just defined. For that, we can use `any`:

```swift
let integer: Consumer<String> = .any([
    .character("0"),
    .sequence([
        .character(in: "1" ... "9"),
        .zeroOrMore(.character(in: "0" ... "9")),
    ]),
])
```

That will do what we want, but it's quite a bit more complex. To make it more readable, we could break it up into separate variables:

```swift
let zero: Consumer<String> = .character("0")
let oneToNine: Consumer<String> = .character(in: "1" ... "9")
let zeroToNine: Consumer<String> = .character(in: "0" ... "9")

let nonzeroInteger: Consumer<String> = .sequence([
    oneToNine, .zeroOrMore(zeroToNine),
])

let integer: Consumer<String> = .any([
    zero, nonzeroInteger,
])
```

We can then further extend this with extra rules, e.g.

```swift
let sign = .any(["+", "-"])

let signedInteger: Consumer<String> = .sequence([
    .optional(sign), integer,
])
```

## Character Sets

The basic consumer type is `charset(Charset)` which matches a single character in a specified set. The `Charset` type is opaque, and cannot be constructed directly - instead, you should use the `character(...)` family of convenience constructors, which accept either a range of `UnicodeScalar`s or a Foundation `CharacterSet`.

For example, to define a consumer that matches the digits 0 - 9, you can use a range:

```swift
let range: Consumer<String> = .character(in: "0" ... "9")
```

You could also use the predefined `decimalDigits` `CharacterSet` provided by Foundation, though you should note that this includes numerals from other languages such as Arabic, and so may not be what you want when parsing a data format like JSON, or a programming language which only expects ASCII digits.

```swift
let range: Consumer<String> = .character(in: .decimalDigits)
```

These two functions are actually equivalent to the following, but thanks to the magic of type inference and function overloading, you can use the more concise syntax above:

```swift
let range: Consumer<String> = Consumer<String>.character(in: CharacterSet(charactersIn: "0" ... "9"))
let range: Consumer<String> = Consumer<String>.character(in: CharacterSet.decimalDigits)
```

You can create an inverse character set by using the `anyCharacter(except: ...)` constructor. This is useful if you want to match any character *except* a particular set. In the following example, we use this feature to parse a quoted string literal by matching a double quote followed by a sequence of any characters *except* a double quote, followed by a final closing double quote:

```swift
let string: Consumer<String> = .sequence([
    .character("\""),
    .zeroOrMore(.anyCharacter(except: "\"")),
    .character("\""),
])
```

The `.anyCharacter(except: "\"")` constructor is functionally equivalent to:

```swift
 .character(in: CharacterSet(charactersIn: "\"").inverted)
 ```
 
But the former produces a more helpful error message if matching fails since it retains the concept of being "every character except X", whereas the latter will be displayed as a range containing all unicode characters except the ones specified. 


## Transforming

In the previous section we wrote a consumer that can match an integer number. But what do we get when we apply that to some input? Here is the matching code:

```swift
let match = try integer.match("1234")
print(match)
```

And here is the output:

```
(
    '1'
    '2'
    '3'
    '4'
)
```

That's ... odd. You were probably hoping for a String containing "1234", or at least something a bit simpler to work with.

If we dig in a bit deeper and look at the structure of the `Match` value returned, we'll find it's something like this (omitting namespaces and other metadata for clarity):

```swift
Match.node(nil, [
    Match.token("1", 0 ..< 1),
    Match.token("2", 1 ..< 2),
    Match.token("3", 2 ..< 3),
    Match.token("4", 3 ..< 4),
])
```

Because each digit in the number was matched individually, the result has been returned as an array of tokens, rather than a single token representing the entire number. This level of detail is potentially useful for some applications, but we don't need it right now - we just want to get the value. To do that, we need to *transform* the output.

The `Match` type has a method called `transform()` for doing exactly that. The `transform()` method takes a closure argument of type `Transform`, which has the signature `(_ name: Label, _ values: [Any]) throws -> Any?`. The closure is applied recursively to all matched values in order to convert them to whatever form your application needs.

Unlike parsing, which is done from the top down, transforming is done from the bottom up. That means that the child nodes of each `Match` will be transformed before their parents, so that all the values passed to the transform closure should have already been converted to the expected types.

So the transform function takes an array of values and collapses them into a single value (or nil) - pretty straightforward - but you're probably wondering about the `Label` argument. If you look at the definition of the `Consumer` type, you'll notice that it also takes a generic argument of type `Label`. In the examples so far we've been passing `String` as the label type, but we've not actually used it yet.

The `Label` type is used in conjunction with the `label` consumer. This allows you to assign a name to a given consumer rule, which can be used to refer to it later. Since you can store consumers in variables and refer to them that way, it's not immediately obvious why this is useful, but it has two purposes:

The first purpose is to allow [forward references](#forward-references), which are explained below.

The second purpose is for use when transforming, to identify the type of node to be transformed. Labels assigned to consumer rules are preserved in the `Match` node after parsing, making it possible to identify which rule was matched to create a particular type of value. Matched values that are not labelled cannot be individually transformed, they will instead be passed as the values for the first labelled parent node.

So, to transform the integer result, we must first give it a label, by using the `label` consumer type:

```swift
let integer: Consumer<String> = .label("integer", .any([
    .character("0"),
    .sequence([
        .character(in: "1" ... "9"),
        .zeroOrMore(.character(in: "0" ... "9")),
    ]),
]))
```

We can then transform the match using the following code:

```swift
let result = try integer.match("1234").transform { label, values in
    switch label {
    case "integer":
        return (values as! [String]).joined()
    default:
        preconditionFailure("unhandled rule: \(name)")
    }
}
print(result ?? "")
```

We know that the `integer` consumer will always return an array of string tokens, so we can safely use `as!` in this case to cast `values` to `[String]`. This is not especially elegant, but its the nature of dealing with dynamic data in Swift. Safety purists might prefer to use `as?` and throw an `Error` if the value is not a `[String]`, but that situation could only arise in the event of a programming error - no input data matched by the `integer` consumer we've defined above will ever return anything else.

With the addition of this function, the array of character tokens is transformed into a single string value. The printed result is now simply '1234'. That's much better, but it's still a `String`, and we may well want it to be an actual `Int` if we're going to use the value. Since the `transform` function returns `Any?`, we can return any type we want, so let's modify it to return an `Int` instead:

```swift
switch label {
case "integer":
    let string = (values as! [String]).joined()
    guard let int = Int(string) else {
        throw MyError(message: "Invalid integer literal '\(string)'")
    }
    return int
default:
    preconditionFailure("unhandled rule: \(name)")
}
```

The `Int(_ string: String)` initializer returns an `Optional` in case the argument cannot be converted to an `Int`. Since we've already pre-determined that the string only contains digits, you might think we could safely force unwrap this, but it is still possible for the initializer to fail - the matched integer might have too many digits to fit into 64 bits, for example.

We could just return the result of `Int(string)` directly, since the return type for the transform function is `Any?`, but this would be a mistake because that would silently omit the number from the output if the conversion failed, and we actually want to treat it as an error instead.

We've used an imaginary error type called `MyError` here, but you can use whatever type you like. Consumer will wrap the error you throw in a `Consumer.Error` before returning it, which will annotate it with the source input offset and other useful metadata preserved from the parsing process.

## Common Transforms

Certain types of transform are very common. In addition to the Array -> String conversion we've just done, other examples include discarding a value (equivalent to returning `nil` from the transform function), or substituting a given string for a different one (e.g. replace "\n" with a newline character, or vice-versa).

For these common operations, rather than applying a label to the consumer and having to write a transform function, you can use one of the built-in consumer transforms: 

* `flatten` - flattens a node tree into a single string token
* `discard` - removes a matched string token or node tree from the results
* `replace` - replaces a matched node tree or string token with a different string token

Note that these transforms are applied during the parsing phase, before the `Match` is returned or the regular `transform()` function can be applied.

Using the `flatten` consumer, we can simplify our integer transform a bit:

```swift
let integer: Consumer<String> = .label("integer", .flatten(.any([
    .character("0"),
    .sequence([
        .character(in: "1" ... "9"),
        .zeroOrMore(.character(in: "0" ... "9")),
    ]),
])))

let result = try integer.match("1234").transform { label, values in
    switch label {
    case "integer":
        let string = values[0] as! String // matched value is now always a string
        guard let int = Int(string) else {
            throw MyError(message: "Invalid integer literal '\(string)'")
        }
        return int
    default:
        preconditionFailure("unhandled rule: \(name)")
    }
}
```

## Typed Labels

Besides the need for force-unwrapping, another inelegance in our transform function is the need for the `default:` clause in the `switch` statement. Swift is trying to be helpful here by insisting that we handle all possible label values, but we *know* that "integer" is the only possible label in this code, so the `default:` is redundant.

Fortunately, Swift's type system can help here. Remember that the label value is not actually a `String` but a generic type `Label`. This allows use to use any type we want for the label (provided it conforms to `Hashable`), and a really good approach is to create an `enum` for the `Label` type:

```swift
enum MyLabel: String {
    case integer
}
```

If we now change our code to use this `MyLabel` enum instead of `String`, we avoid error-prone copying and pasting of string literals and we eliminate the need for the `default:` clause in the transform function, since Swift can now determine statically that `integer` is the only possible value. The other nice benefit is that if we add other label types in future, the compiler will warn us if we forget to implement transforms for them.

The complete, updated code for the integer consumer is shown below:

```swift
enum MyLabel: String {
    case integer
}

let integer: Consumer<MyLabel> = .label(.integer, .flatten(.any([
    .character("0"),
    .sequence([
        .character(in: "1" ... "9"),
        .zeroOrMore(.character(in: "0" ... "9")),
    ]),
])))

enum MyError: Error {
    let message: String
}

let result = try integer.match("1234").transform { label, values in
    switch label {
    case .integer:
        let string = values[0] as! String
        guard let int = Int(string) else {
            throw MyError(message: "Invalid integer literal '\(string)'")
        }
        return int
    }
}
print(result ?? "")
```

## Forward References

More complex parsing grammars (e.g. for a programming language or a structured data file) may require circular references between rules. For example, here is an abridged version of the grammar for parsing JSON:

```swift
let null: Consumer<String> = .string("null")
let bool: Consumer<String> = ...
let number: Consumer<String> = ...
let string: Consumer<String> = ...
let object: Consumer<String> = ...

let array: Consumer<String> = .sequence([
    .string("["),
    .optional(.interleaved(json, ","))
    .string("]"),
])

let json: Consumer<String> = .any([null, bool, number, string, object, array])
```

The `array` consumer contains a comma-delimited sequence of `json` values, and the `json` consumer can match any other type, including `array` itself.

You see the problem? The `array` consumer references the `json` consumer before it has been declared. This is known as a *forward reference*. You might think we can solve this by predeclaring the `json` variable before we assign its value, but this won't work - `Consumer` is a value type, so every reference to it is actually a copy - it needs to be defined up front.

In order to implement this, we need to make use of the `label` and `reference` features. First, we must give the `json` consumer a label so that it can be referenced before it is declared:

```swift
let json: Consumer<String> = .label("json", .any([null, bool, number, string, object, array]))
```

Then we replace `json` inside the `array` consumer with `.reference("json")`:

```swift
let array: Consumer<String> = .sequence([
    .string("["),
    .optional(.interleaved(.reference("json"), ","))
    .string("]"),
])
```

**Note:** You must be careful when using references like this, not just to ensure that the named consumer actually exists, but that it is included in a non-reference form somewhere in your root consumer (the one which you actually try to match against the input).

In this case, `json` *is* the root consumer, so we know it exists. But what if we had defined the reference the other way around?

```swift
let json: Consumer<String> = .any([null, bool, number, string, object, .reference("array")])

let array: Consumer<String> = .label("array", .sequence([
    .string("["),
    .optional(.interleaved(json, ","))
    .string("]"),
]))
```

So now we've switched things up so that `json` is defined first, and has a forward reference to `array`. It seems like this should work, but it won't. The problem is that when we go to match `json` against an input string, there's no copy of the actual `array` consumer anywhere in the `json` consumer. It's referenced by name only.

You can avoid this problem if you ensure that references only point from child nodes to their parents, and that parent consumers reference their children directly, rather than by name.

## Syntax Sugar

Consumer deliberately doesn't go overboard with custom operators because it can make code that is inscrutable to other Swift developers, however there are a few syntax extensions that can help to make your parser code a bit more readable:

The `Consumer` type conforms to `ExpressibleByStringLiteral` as shorthand for the `.string()` case, which means that instead of writing:

```swift
let foo: Consumer<String> = .string("foo")
let foobar: Consumer<String> = .sequence([.string("foo"), .string("bar")])
```

You can actually just write:

```swift
let foo: Consumer<String> = "foo"
let foobar: Consumer<String> = .sequence(["foo", "bar"])
```

Additionally, `Consumer` conforms to `ExpressibleByArrayLiteral` as a shorthand for `.sequence()`, so instead of:

```swift
let foobar: Consumer<String> = .sequence(["foo", "bar"])
```

You can just write:

```swift
let foobar: Consumer<String> = ["foo", "bar"]
```

The OR operator `|` is also overloaded for `Consumer` as an alternative to using `.any()`, so instead of:

```swift
let fooOrbar: Consumer<String> = .any(["foo", "bar"])
```

You can write:

```swift
let fooOrbar: Consumer<String> = "foo" | "bar"
```

Be careful when using the `|` operator for very complex expressions however, as it can cause Swift's compile time to go up exponentially due to the complexity of type inference. It's best to only use `|` for a small number of cases. If it's more than 4 or 5, or if it's deeply nested inside a complex expression, you should probably use `any()` instead.

## White Space

Consumer makes no assumptions about the nature of the text that you are parsing, so it does not have any built-in distinction between meaningful content and white space (spaces or linebreaks between tokens).

In practice, many programming languages and structured data files have a policy of ignoring (or mostly ignoring) white space between tokens, so what's the best way to do that?

First, define the grammar for your language, excluding any consideration of white space. For example, here is a simple consumer that matches a comma-delimited list of integers:

```swift
let integer: Consumer<MyLabel> = .flatten("0" | [.character(in: "1" ... "9"), .zeroOrMore(.character(in: "0" ... "9"))])
let list: Consumer<MyLabel> = .interleaved(integer, .discard(","))
```

Currently, this will match a number sequence like "12,0,5,78", but if we include spaces between the numbers it will fail. So next we need to define a consumer for matching white space:

```swift
let space: Consumer<MyLabel> = .discard(.zeroOrMore(.character(in: " \t\r\n")))
```

This consumer will match (and discard) any sequence of space, tab, carriage return or linefeed characters. Using the `space` rule, we could manually modify our `list` pattern to ignore spaces as follows:

```swift
let list: Consumer<MyLabel> = [space, .interleaved(integer, .discard([space, ",", space])), space]
```

This should work, but manually inserting spaces between every rule in the grammar like this is pretty tedious. It also makes the grammar harder to follow, and it's easy to miss a space accidentally.

To simplify dealing with white space, Consumer has a convenience constructor called `ignore()` that allows you to automatically ignore a given pattern when matching. We can use `ignore()` to combine our original `list` rule with the `space` rule as follows:

```swift
let list: Consumer<MyLabel> = .ignore(space, in: .interleaved(integer, .discard(",")))
```

This results in a consumer that is functionally equivalent to the manually spaced list that we created above, but with much less code.

The `ignore()` constructor is powerful, but because it is applied recursively to the entire consumer hierarchy, you need to be careful not to ignore white space in places that you don't want to allow it. For example, we wouldn't want to allow white space *inside* an individual token, such as the integer literal in our example.

Individual tokens in a grammar are typically returned as a single string value by using the [flatten transform](#standard-transforms). The `ignore()` constructor won't modify consumers inside `flatten`, so the `integer` token from our example is actually not affected.

For more complex grammars, you may not be able to use `ignore()`, or may only be able to use it on certain sub-trees of the overall consumer, instead of the entire thing. For example, in the [JSON example](#json) included with the Consumer library, string literals can contain escaped unicode character literals that must be transformed using the transform function. That means that JSON string literals can't be flattened, which also means that the JSON grammar can't use `ignore()` for handling white space, otherwise the grammar would ignore white space inside strings, which would mess up the parsing.

**Note:** `ignore()` can be used to ignore any kind of input, not just white space. Also, while the input is ignored from the point of view of the grammar, it doesn't have to be discarded in the output. If you were writing a code linter or formatter you might want to preserve the white space from the original source. To do that, you would remove the `discard()` clause from inside your white space rule:

```swift
let space: Consumer<MyLabel> = .zeroOrMore(.character(in: " \t\r\n"))
```

In some languages, such as Swift or JavaScript, spaces are mostly ignored but linebreaks have semantic significance. For such cases you might ignore only spaces but not linebreaks, or you might ignore both but only *discard* the spaces, so you can process the linebreaks manually in your transform function:

```swift
let space: Consumer<MyLabel> = .zeroOrMore(.discard(.character(in: " \t")) | .character(in: "\r\n"))
```

It's also common in programming languages to allow *comments*, which typically have no semantic meaning and can appear anywhere that white space is permitted. You can ignore comments in the same way you'd ignore spaces:

```swift
let space: Consumer<MyLabel> = .character(in: " \t\r\n")
let comment: Consumer<MyLabel> = ["/*", .zeroOrMore([.not("*/"), .anyCharacter()]), "*/"]
let spaceOrComment: Consumer<MyLabel> = .discard(.zeroOrMore(space | comment))

let program: Consumer<MyLabel> = .ignore(spaceOrComment, in: ...)
```


## Error Handling

There are two types of error that can occur in Consumer: parsing errors and transform errors.

Parsing errors are generated automatically by the Consumer framework when it encounters input that doesn't match the specified grammar. When this happens, Consumer will generate a `Consumer.Error` value that contains the kind of error that occurred, and the location of the error in the original source input.

Source locations are specified as a `Consumer.Location` value, which contains the character range of the error, and can lazily compute the line number and column at which that range occurs.

Transform errors are generated after the initial parsing pass by throwing an error inside the `Consumer.Transform` function. Any error thrown will be wrapped in a `Consumer.Error` so that it can be annotated with the source location.

Consumer's errors conform to `CustomStringConvertible`, and can be directly displayed to the user (although the message is not localized), but how useful this message is depends partly on how you write your consumer implementation.

When Consumer encounters an unexpected token, the error message will include a description of what was actually expected. Built-in consumer types like `string` and `charset` are automatically assigned meaningful descriptions. Labelled consumers will be displayed using the Label description:

```swift
let integer: Consumer<String> = .label("integer", "0" | [
    .character(in: "1" ... "9"),
    .zeroOrMore(.character(in: "0" ... "9")),
])

_ = try integer.match("foo") // will throw 'Unexpected token 'foo' at 1:1 (expected integer)'
```

If you are using `String` as your `Label` type then the description will be the literal string value. If you are using an enum (as recommended) then by default the `rawValue` of the label enum will be displayed.

The naming of your enum cases may not be optimal for user display. To fix this, you can change the label string, as follows:

```swift
enum JSONLabel: String {
    case string = "a string"
    case array = "an array"
    case json = "a json value"
}
```

This will improve the error message, but it's not localizable and may not be desirable to tie JSONLabel values to user-readable strings in case we want to serialize them, or make breaking changes in future. A better option is to make your `Label` type conform to `CustomStringConvertible`, then implement a custom `description`:

```swift
enum JSONLabel: String, CustomStringConvertible {
    case string
    case array
    case json
    
    var description: String {
        switch self {
        case .string: return "a string"
        case .array: return "an array"
        case .json: return "a json value"
        }
    }
}
```

Now the user-friendly label descriptions are independent of the actual values. This approach also make localization easier, as you could use the rawValue to index a strings file instead of a hard-coded switch statement:

```swift
var description: String {
    return NSLocalizedString(self.rawValue, comment: "")
}
```

Similarly, when throwing custom errors during the transform phase, it's a good idea to implement `CustomStringConvertible` for your custom error type:

```swift
enum JSONError: Error, CustomStringConvertible {
    case invalidNumber(String)
    case invalidCodePoint(String)
    
    var description: String {
        switch self {
        case let .invalidNumber(string):
            return "invalid numeric literal '\(string)'"
        case let .invalidCodePoint(string):
            return "invalid unicode code point '\(string)'"
        }
    }
}
```


# Performance

The performance of a Consumer parser can be greatly affected by the way that your rules are structured. This section includes some tips for getting the best possible parsing speed.

**Note:** As with any performance tuning, it's important that you *measure* the performance of your parser before and after making changes, otherwise you may waste time optimizing something that's already fast enough, or even inadvertently make it slower.

## Backtracking

The best way to get good parsing performance from your Consumer grammar is to try to avoid *backtracking*.

Backtracking is when the parser has to throw away partially matched results and parse them again. It occurs when multiple consumers in a given `any` group begin with the same token or sequence of tokens.

For example, here is an example of an inefficient pattern:

```swift
let foobarOrFoobaz: Consumer<String> = .any([
    .sequence(["foo", "bar"]),
    .sequence(["foo", "baz"]),
])
```

When the parser encounters the input "foobaz", it will first match "foo", then try to match "bar". When that fails it will backtrack right back to the beginning and try the second sequence of "foo" followed by "baz". This will make parsing slower than it needs to be.

We could instead rewrite this as:

```swift
let foobarOrFoobaz: Consumer<String> = .sequence([
    "foo", .any(["bar", "baz"])
])
```

This consumer matches exactly the same input as the previous one, but after successfully matching "foo", if it fails to match "bar" it will try "baz" immediately, instead of going back and matching "foo" again. We have eliminated the backtracking.

## Character Sequences

The following consumer example matches a quoted string literal containing escaped quotes. It matches a zero or more instances of either an escaped quote `\"` or any other character besides `"` or `\`.

```swift
let string: Consumer<String> = .flatten(.sequence([
    .discard("\""),
    .zeroOrMore(.any([
        .replace("\\\"", "\""), // Escaped "
        .anyCharacter(except: "\"", "\\"),
    ])),
    .discard("\""),
]))
```

The above implementation works as expected, but it is not as efficient as it could be. For each character encountered, it must first check for an escaped quote, and then check if it's any other character. That's quite an expensive check to perform, and it can't (currently) be optimized by the Consumer framework.

Consumer has optimized code paths for matching `.zeroOrMore(.character(...))` or `.oneOrMore(.character(...))` rules, and we can rewrite the string consumer to take advantage of this optimization as follows:

```swift
let string: Consumer<String> = .flatten(.sequence([
    .discard("\""),
    .zeroOrMore(.any([
        .replace("\\\"", "\""), // Escaped "
        .oneOrMore(.anyCharacter(except: "\"", "\\")),
    ])),
    .discard("\""),
]))
```

Since most characters in a typical string are not \ or ", this will run much faster because it can efficiently consume a long run of non-escape characters between each escape sequence.

## Flatten and Discard

We mentioned the `flatten` and `discard` transforms in the [Common Transforms](#common-transforms) section above, as a convenient way to omit redundant information from the parsing results prior to applying a custom transform.

But using "flatten" and "discard" can also improve performance, by simplifying the parsing process, and avoiding the need to gather and propagate unnecessary information like source offsets.

If you intend to eventually flatten a given node of your matched results, it's  much better to do this within the consumer itself by using the `flatten` rule than by using `Array.joined()` in your transform function. The only time when you won't be able to do this is if some of the child consumers need custom transforms to be applied, because by flattening the node tree you remove the labels that are needed to reference the node in your transform.

Similarly, for unneeded match results (e.g. commas, brackets and other punctuation that isn't required after parsing) you should always use `discard` to remove the node or token from the match results before applying a transform.

**Note:** Transform rules are applied hierarchically, so if a parent consumer already has `flatten` applied, there is no further performance benefit to be gained from applying it individually to the children of that consumer.


# Example Projects

Consumer includes a number of example projects to demonstrate the framework:

## JSON

The JSON example project implements a [JSON](https://json.org) parser, along with a transform function to convert it into Swift data.

## REPL

The REPL (Read Evaluate Print Loop) example is a Mac command-line tool for evaluating expressions. The REPL can handle numbers, booleans and string values, but currently only supports basic math operations.

Each line you type into the REPL is evaluated independently and the result is printed in the console. To share values between expressions, you can define variables using an identifier name followed by `=` and then an expression, e.g:

```
foo = (5 + 6) + 7
```

The named variable ("foo", in this case) is then available to use in subsequent expressions.

This example demonstrates a number of advanced techniques such as mutually recursive consumer rules, operator precedence, and negative lookahead using `not()`
