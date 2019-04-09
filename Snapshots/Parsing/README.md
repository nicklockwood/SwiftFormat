[![Travis](https://img.shields.io/travis/nicklockwood/Parsing.svg)](https://travis-ci.org/nicklockwood/Parsing)
[![Coveralls](https://coveralls.io/repos/github/nicklockwood/Parsing/badge.svg)](https://coveralls.io/github/nicklockwood/Parsing)
[![Swift 4.1](https://img.shields.io/badge/swift-4.2-red.svg?style=flat)](https://developer.apple.com/swift)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://opensource.org/licenses/MIT)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg)](http://twitter.com/nicklockwood)

Table of Contents
-----------------

- [Introduction](#introduction)
- [Language](#language)
- [Project](#project)
- [Branches](#branches)


Introduction
---------------

This repository is a companion to my 2019 talk entitled *Parsing Formal Languages with Swift* (a copy of which is [included in the repository](https://github.com/nicklockwood/Parsing/blob/master/Parsing.pdf)).

The included [Xcode project](#project) contains Swift implementations of a lexer, parser, formatter, interpreter and transpiler for a very simple language.

Neither the language nor the parser are particularly useful in their own right, but the techniques demonstrated in the code can be applied to  more complex languages and applications.


Language
----------

The toy language implemented in this project has the following syntax:

* Numbers

    Both integers and floating point numbers are supported, up to the precision of a Swift `Double`. Negative numbers are not supported, nor exponentials, hexadecimal, etc.

    ```swift
    5
    0.5
    57000
    .1
    ```

* String literals     

    String literals must be enclosed in doubles quotes (`"`). String literals can contain any character including a carriage return or linefeed. Double quotes must be escaped with a backslash (`\`) as must the backslash character itself.
    
    ```swift
    "Hello World"
    "This string has a
    linebreak in it"
    "This string has \"escaped quotes\""
    "The string has an escaped \\ (backslash)"
    ```
    
* Variables

    Variables names must begin with a letter, optionally followed by one or more letters or numbers. Other symbols such as `_` or emoji are not supported.
    
    Any valid name can be used as a variable apart from the keywords `let` and `print` which are reserved.
    
    ```swift
    a
    foo
    Bar56
    ```

* Expressions

    An expression can contain one or more numbers, string literals or variables. Variables must be declared before they are used in an expression.
    
    Expressions also support the infix `+` operator, which performs an addition if both operands are numeric, or a concatenation if either operand is a string. Expressions may contain multiple `+` operations.
    
    Parentheses are not supported, nor are any other operators (unless you are using the operator-precedence branch, which supports the `*` operator for multiplication of numbers).

    ```swift
    foo
    5
    hello + "world"
    1 + 2 + 3
    "Jonny" + 5
    ```

* Declarations

    A declaration creates a variable and assigns a value to it. The value can be any valid expression, and can reference variables declared previously.
    
    Variables have no intrinsic type beyond their currently stored value. You may redeclare the same variable multiple times with different values and types.

    ```swift
    let bar = "cat"
    let foo = 5 + bar
    ```
    
* Print

    The print statement outputs a value to the console. As with declarations, the value can be any valid expression.
    
    ```swift
    print "Hello World"
    print 5 + 6
    ```
    
* Whitespace

    The language is whitespace-agnostic. Any number of linebreaks or spaces can appears between any pair of tokens. Multiple statements can be placed on the same line, and space is only required between tokens in cases where its omission would result in ambiguity (e.g. between a keyword and a variable).

* Comments

    There is no support for comments.


Project
-----------

The Parsing.xcodeproj project requires Xcode 10.1 or higher. It builds a Swift framework with the following features:

* Lexer

    This is a lexer for the simple language described in the talk. The lexer is invoked via the `tokenize()` function, which takes a `String` as input and returns an array of `Token`s. All code for the lexer is included in [Lexer.swift](https://github.com/nicklockwood/Parsing/blob/master/Sources/Lexer.swift) and it has no other dependencies besides Foundation.
    
    ```swift
    // usage
    import Parsing
    let input = "let foo = 5 \n print foo"
    let tokens = try! tokenize(input)
    print(tokens)
    ```

* Parser

    This is a parser for the language. The parser is invoked via the `parse()` function, which takes a `String` as input and returns an array of `Statement`s. All code for the parser is included in [Parser.swift](https://github.com/nicklockwood/Parsing/blob/master/Sources/Parser.swift), which depends only on Lexer.swift and has no other dependencies besides Foundation.
    
    ```swift
    // usage
    import Parsing
    let input = "let foo = 5 \n print foo"
    let statements = try! parse(input)
    print(statements)
    ```
    
* Formatter

    This is a formatter or "pretty-printer" for the language, as mentioned in the talk. The formatter is invoked via the `format()` function, which takes an array of `Statement`s as input and returns a `String` containing the formatted source code. All code for the formatter is included in [Formatter.swift](https://github.com/nicklockwood/Parsing/blob/master/Sources/Formatter.swift), which depends on Parser.swift, Lexer.swift and Foundation.
    
    ```swift
    // usage
    import Parsing
    let input = "let foo = 5 \n print foo"
    let statements = parse(input)
    let output = try! format(statements)
    print(output)
    ```
    
* Interpreter
    
    This is an interpreter for the language, as mentioned in the talk. The interpreter is invoked via the `evaluate()` function, which takes an array of `Statement`s as input and returns a `String` containing the output of the program. All code for the interpreter is included in [Interpreter.swift](https://github.com/nicklockwood/Parsing/blob/master/Sources/Interpreter.swift), which depends on Parser.swift, Lexer.swift and Foundation.
    
    ```swift
    // usage
    import Parsing
    let input = "let foo = 5 \n print foo"
    let statements = parse(input)
    let output = try! evaluate(statements)
    print(output)
    ```

* Transpiler
    
    This is a Swift transpiler for the language, as mentioned in the talk. The transpiler is invoked via the `transpile()` function, which takes an array of `Statement`s as input and returns a `String` containing the equivalent Swift source code to run the program. All code for the transpiler is included in [Transpiler.swift](https://github.com/nicklockwood/Parsing/blob/master/Sources/Transpiler.swift), which depends on Parser.swift, Lexer.swift and Foundation.
    
    ```swift
    // usage
    import Parsing
    let input = "let foo = 5 \n print foo"
    let statements = parse(input)
    let output = try! transpile(statements)
    try! output.write(toFile: "program.swift", atomically: true, encoding: .utf8)
    ```

Branches
-----------

There are several branches included in the git repository:

* [master](https://github.com/nicklockwood/Parsing/tree/master)

    This contains the basic version of the parsing project, as described in the talk.
    
* [regex-based-lexer](https://github.com/nicklockwood/Parsing/tree/regex-based-lexer)

    This branch includes an alternative lexer implementation that uses `NSRegularExpression`.
    
* [operator-precedence](https://github.com/nicklockwood/Parsing/tree/operator-precedence)

    This branch adds support for the multiplication operator, as detailed in the enhancements section of the talk.

* [better-errors](https://github.com/nicklockwood/Parsing/tree/better-errors)

    This branch improves the error handling mechanism, as suggested in the enhancements section of the talk:
    
    - Tokens and AST nodes now include source range information.
    
    - Multiple lexing errors can now be detected and handled at a later stage of the parser.
    
    - Error types are now more specific and include sufficient information to derive the exact source location of the error, even at the interpreter stage.
    
    - As a bonus, the lexer also includes a method for converting a source string index to a line/column offset.
