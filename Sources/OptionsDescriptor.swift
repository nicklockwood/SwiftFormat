//
//  OptionsDescriptor.swift
//  SwiftFormat
//
//  Created by Vincent Bernier on 10-02-18.
//  Copyright © 2018 Nick Lockwood.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/SwiftFormat
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

extension FormatOptions {
    struct Descriptor {
        enum ArgumentType: EnumAssociable {
            case binary(true: [String], false: [String]) // index 0 should be the official value, while others are tolerable values
            case list([String])
            case freeText(validationStrategy: (String) -> Bool)
        }

        let argumentName: String // command-line argument; must not change
        let propertyName: String // internal property; ok to change this
        let name: String
        let type: ArgumentType
        let toOptions: (String, inout FormatOptions) throws -> Void
        let fromOptions: (FormatOptions) -> String

        var defaultArgument: String {
            return fromOptions(FormatOptions.default)
        }
    }
}

extension FormatOptions.Descriptor {
    static let formats: [FormatOptions.Descriptor] = [
        .indentation,
        .lineBreak,
        .allowInlineSemicolons,
        .spaceAroundRangeOperators,
        .spaceAroundOperatorDeclarations,
        .useVoid,
        .indentCase,
        .trailingCommas,
        .indentComments,
        .truncateBlankLines,
        .allmanBraces,
        .fileHeader,
        .ifdefIndent,
        .wrapArguments,
        .wrapCollections,
        .hexLiteralCase,
        .exponentCase,
        .decimalGrouping,
        .binaryGrouping,
        .octalGrouping,
        .hexGrouping,
        .letPatternPlacement,
        .stripUnusedArguments,
        .elsePosition,
        .removeSelf,
        .experimentalRules,
    ]

    static let files: [FormatOptions.Descriptor] = [
        .fragment,
        .ignoreConflictMarkers,
    ]

    static let all = formats + files + deprecated

    static let indentation = FormatOptions.Descriptor(argumentName: "indent",
                                                      propertyName: "indent",
                                                      name: "Indent",
                                                      type: .freeText(validationStrategy: { input in
                                                          let validText = Set<String>(arrayLiteral: "tab", "tabs", "tabbed")
                                                          var result = validText.contains(input.lowercased())
                                                          result = result || Int(input.trimmingCharacters(in: .whitespaces)) != nil
                                                          return result
                                                      }),
                                                      toOptions: { input, options in
                                                          switch input.lowercased() {
                                                          case "tab", "tabs", "tabbed":
                                                              options.indent = "\t"
                                                          default:
                                                              if let spaces = Int(input) {
                                                                  options.indent = String(repeating: " ", count: spaces)
                                                                  break
                                                              }
                                                              throw FormatError.options("")
                                                          }
                                                      },
                                                      fromOptions: { options in
                                                          if options.indent == "\t" {
                                                              return "tabs"
                                                          }
                                                          return String(options.indent.count)
    })
    static let lineBreak = FormatOptions.Descriptor(argumentName: "linebreaks",
                                                    propertyName: "linebreak",
                                                    name: "Linebreaks Character",
                                                    type: .list(["cr", "lf", "crlf"]),
                                                    toOptions: { input, options in
                                                        switch input.lowercased() {
                                                        case "cr":
                                                            options.linebreak = "\r"
                                                        case "lf":
                                                            options.linebreak = "\n"
                                                        case "crlf":
                                                            options.linebreak = "\r\n"
                                                        default:
                                                            throw FormatError.options("")
                                                        }
                                                    },
                                                    fromOptions: { options in
                                                        let result: String
                                                        switch options.linebreak {
                                                        case "\r":
                                                            result = "cr"
                                                        case "\n":
                                                            result = "lf"
                                                        case "\r\n":
                                                            result = "crlf"
                                                        default:
                                                            result = "lf"
                                                        }
                                                        return result
    })
    static let allowInlineSemicolons = FormatOptions.Descriptor(argumentName: "semicolons",
                                                                propertyName: "allowInlineSemicolons",
                                                                name: "Semicolons",
                                                                type: .binary(true: ["inline"], false: ["never", "false"]),
                                                                toOptions: { input, options in
                                                                    switch input.lowercased() {
                                                                    case "inline":
                                                                        options.allowInlineSemicolons = true
                                                                    case "never", "false":
                                                                        options.allowInlineSemicolons = false
                                                                    default:
                                                                        throw FormatError.options("")
                                                                    }
                                                                },
                                                                fromOptions: { options in
                                                                    options.allowInlineSemicolons ? "inline" : "never"
    })
    static let spaceAroundRangeOperators = FormatOptions.Descriptor(argumentName: "ranges",
                                                                    propertyName: "spaceAroundRangeOperators",
                                                                    name: "Ranges",
                                                                    type: .binary(true: ["space", "spaced", "spaces"], false: ["nospace"]),
                                                                    toOptions: { input, options in
                                                                        switch input.lowercased() {
                                                                        case "space", "spaced", "spaces":
                                                                            options.spaceAroundRangeOperators = true
                                                                        case "nospace":
                                                                            options.spaceAroundRangeOperators = false
                                                                        default:
                                                                            throw FormatError.options("")
                                                                        }
                                                                    },
                                                                    fromOptions: { options in
                                                                        options.spaceAroundRangeOperators ? "spaced" : "nospace"
    })
    static let spaceAroundOperatorDeclarations = FormatOptions.Descriptor(argumentName: "operatorfunc",
                                                                          propertyName: "spaceAroundOperatorDeclarations",
                                                                          name: "Operator Func",
                                                                          type: .binary(true: ["space", "spaced", "spaces"], false: ["nospace"]),
                                                                          toOptions: { input, options in
                                                                              switch input.lowercased() {
                                                                              case "space", "spaced", "spaces":
                                                                                  options.spaceAroundOperatorDeclarations = true
                                                                              case "nospace":
                                                                                  options.spaceAroundOperatorDeclarations = false
                                                                              default:
                                                                                  throw FormatError.options("")
                                                                              }
                                                                          },
                                                                          fromOptions: { options in
                                                                              options.spaceAroundOperatorDeclarations ? "spaced" : "nospace"
    })
    static let useVoid = FormatOptions.Descriptor(argumentName: "empty",
                                                  propertyName: "useVoid",
                                                  name: "Empty",
                                                  type: .binary(true: ["void"], false: ["tuple", "tuples"]),
                                                  toOptions: { input, options in
                                                      switch input.lowercased() {
                                                      case "void":
                                                          options.useVoid = true
                                                      case "tuple", "tuples":
                                                          options.useVoid = false
                                                      default:
                                                          throw FormatError.options("")
                                                      }
                                                  },
                                                  fromOptions: { options in
                                                      options.useVoid ? "void" : "tuples"
    })
    static let indentCase = FormatOptions.Descriptor(argumentName: "indentcase",
                                                     propertyName: "indentCase",
                                                     name: "Indent Case",
                                                     type: .binary(true: ["true"], false: ["false"]),
                                                     toOptions: { input, options in
                                                         switch input.lowercased() {
                                                         case "true":
                                                             options.indentCase = true
                                                         case "false":
                                                             options.indentCase = false
                                                         default:
                                                             throw FormatError.options("")
                                                         }
                                                     },
                                                     fromOptions: { options in
                                                         options.indentCase ? "true" : "false"
    })
    static let trailingCommas = FormatOptions.Descriptor(argumentName: "commas",
                                                         propertyName: "trailingCommas",
                                                         name: "Commas",
                                                         type: .binary(true: ["always", "true"], false: ["inline", "false"]),
                                                         toOptions: { input, options in
                                                             switch input.lowercased() {
                                                             case "always", "true":
                                                                 options.trailingCommas = true
                                                             case "inline", "false":
                                                                 options.trailingCommas = false
                                                             default:
                                                                 throw FormatError.options("")
                                                             }
                                                         },
                                                         fromOptions: { options in
                                                             options.trailingCommas ? "always" : "inline"
    })
    static let indentComments = FormatOptions.Descriptor(argumentName: "comments",
                                                         propertyName: "indentComments",
                                                         name: "Comments",
                                                         type: .binary(true: ["indent", "indented"], false: ["ignore"]),
                                                         toOptions: { input, options in
                                                             switch input.lowercased() {
                                                             case "indent", "indented":
                                                                 options.indentComments = true
                                                             case "ignore":
                                                                 options.indentComments = false
                                                             default:
                                                                 throw FormatError.options("")
                                                             }
                                                         },
                                                         fromOptions: { options in
                                                             options.indentComments ? "indent" : "ignore"
    })
    static let truncateBlankLines = FormatOptions.Descriptor(argumentName: "trimwhitespace",
                                                             propertyName: "truncateBlankLines",
                                                             name: "Trim White Space",
                                                             type: .binary(true: ["always"], false: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]),
                                                             toOptions: { input, options in
                                                                 switch input.lowercased() {
                                                                 case "always":
                                                                     options.truncateBlankLines = true
                                                                 case "nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty":
                                                                     options.truncateBlankLines = false
                                                                 default:
                                                                     throw FormatError.options("")
                                                                 }
                                                             },
                                                             fromOptions: { options in
                                                                 options.truncateBlankLines ? "always" : "nonblank-lines"
    })
    static let allmanBraces = FormatOptions.Descriptor(argumentName: "allman",
                                                       propertyName: "allmanBraces",
                                                       name: "Allman Braces",
                                                       type: .binary(true: ["true", "enabled"], false: ["false", "disabled"]),
                                                       toOptions: { input, options in
                                                           switch input.lowercased() {
                                                           case "true", "enabled":
                                                               options.allmanBraces = true
                                                           case "false", "disabled":
                                                               options.allmanBraces = false
                                                           default:
                                                               throw FormatError.options("")
                                                           }
                                                       },
                                                       fromOptions: { options in
                                                           options.allmanBraces ? "true" : "false"
    })
    static let fileHeader = FormatOptions.Descriptor(argumentName: "header",
                                                     propertyName: "fileHeader",
                                                     name: "Header",
                                                     type: .freeText(validationStrategy: { _ in true }),
                                                     toOptions: { input, options in
                                                         switch input.lowercased() {
                                                         case "strip":
                                                             options.fileHeader = ""
                                                         case "ignore":
                                                             options.fileHeader = nil
                                                         default:
                                                             // Normalize the header
                                                             let header = input.trimmingCharacters(in: .whitespacesAndNewlines)
                                                             let isMultiline = header.hasPrefix("/*")
                                                             var lines = header.components(separatedBy: "\\n")
                                                             lines = lines.map {
                                                                 var line = $0
                                                                 if !isMultiline, !line.hasPrefix("//") {
                                                                     line = "//" + line
                                                                 }
                                                                 if let range = line.range(of: "{year}") {
                                                                     let formatter = DateFormatter()
                                                                     formatter.dateFormat = "yyyy"
                                                                     line.replaceSubrange(range, with: formatter.string(from: Date()))
                                                                 }
                                                                 return line
                                                             }
                                                             while lines.last?.isEmpty == true {
                                                                 lines.removeLast()
                                                             }
                                                             options.fileHeader = lines.joined(separator: "\n")
                                                         }
                                                     },
                                                     fromOptions: { options in
                                                         options.fileHeader.map { $0.isEmpty ? "strip" : $0 } ?? "ignore"
    })
    static let ifdefIndent = FormatOptions.Descriptor(argumentName: "ifdef",
                                                      propertyName: "ifdefIndent",
                                                      name: "Ifdef Indent",
                                                      type: .list(["indent", "noindent", "outdent"]),
                                                      toOptions: { input, options in
                                                          if let mode = IndentMode(rawValue: input.lowercased()) {
                                                              options.ifdefIndent = mode
                                                          } else {
                                                              throw FormatError.options("")
                                                          }
                                                      },
                                                      fromOptions: { options in
                                                          options.ifdefIndent.rawValue
    })
    static let wrapArguments = FormatOptions.Descriptor(argumentName: "wraparguments",
                                                        propertyName: "wrapArguments",
                                                        name: "Wrap Arguments",
                                                        type: .list(["beforefirst", "afterfirst", "disabled"]),
                                                        toOptions: { input, options in
                                                            if let mode = WrapMode(rawValue: input.lowercased()) {
                                                                options.wrapArguments = mode
                                                            } else {
                                                                throw FormatError.options("")
                                                            }
                                                        },
                                                        fromOptions: { options in
                                                            options.wrapArguments.rawValue
    })
    static let wrapCollections = FormatOptions.Descriptor(argumentName: "wrapcollections",
                                                          propertyName: "wrapCollections",
                                                          name: "Wrap Collections",
                                                          type: .list(["beforefirst", "afterfirst", "disabled"]),
                                                          toOptions: { input, options in
                                                              if let mode = WrapMode(rawValue: input.lowercased()) {
                                                                  options.wrapCollections = mode
                                                              } else {
                                                                  throw FormatError.options("")
                                                              }
                                                          },
                                                          fromOptions: { options in
                                                              options.wrapCollections.rawValue
    })
    static let hexLiteralCase = FormatOptions.Descriptor(argumentName: "hexliteralcase",
                                                         propertyName: "uppercaseHex",
                                                         name: "Hex Literal Case",
                                                         type: .binary(true: ["uppercase", "upper"], false: ["lowercase", "lower"]),
                                                         toOptions: { input, options in
                                                             switch input.lowercased() {
                                                             case "uppercase", "upper":
                                                                 options.uppercaseHex = true
                                                             case "lowercase", "lower":
                                                                 options.uppercaseHex = false
                                                             default:
                                                                 throw FormatError.options("")
                                                             }
                                                         },
                                                         fromOptions: { options in
                                                             options.uppercaseHex ? "uppercase" : "lowercase"
    })
    static let exponentCase = FormatOptions.Descriptor(argumentName: "exponentcase",
                                                       propertyName: "uppercaseExponent",
                                                       name: "Exponent Case",
                                                       type: .binary(true: ["uppercase", "upper"], false: ["lowercase", "lower"]),
                                                       toOptions: { input, options in
                                                           switch input.lowercased() {
                                                           case "uppercase", "upper":
                                                               options.uppercaseExponent = true
                                                           case "lowercase", "lower":
                                                               options.uppercaseExponent = false
                                                           default:
                                                               throw FormatError.options("")
                                                           }
                                                       },
                                                       fromOptions: { options in
                                                           options.uppercaseExponent ? "uppercase" : "lowercase"
    })
    static let decimalGrouping = FormatOptions.Descriptor(argumentName: "decimalgrouping",
                                                          propertyName: "decimalGrouping",
                                                          name: "Decimal Grouping",
                                                          type: .freeText(validationStrategy: { Grouping(rawValue: $0) != nil }),
                                                          toOptions: { input, options in
                                                              guard let grouping = Grouping(rawValue: input.lowercased()) else {
                                                                  throw FormatError.options("")
                                                              }
                                                              options.decimalGrouping = grouping
                                                          },
                                                          fromOptions: { options in
                                                              options.decimalGrouping.rawValue
    })
    static let binaryGrouping = FormatOptions.Descriptor(argumentName: "binarygrouping",
                                                         propertyName: "binaryGrouping",
                                                         name: "Binary Grouping",
                                                         type: .freeText(validationStrategy: { Grouping(rawValue: $0) != nil }),
                                                         toOptions: { input, options in
                                                             guard let grouping = Grouping(rawValue: input.lowercased()) else {
                                                                 throw FormatError.options("")
                                                             }
                                                             options.binaryGrouping = grouping
                                                         },
                                                         fromOptions: { options in
                                                             options.binaryGrouping.rawValue
    })
    static let octalGrouping = FormatOptions.Descriptor(argumentName: "octalgrouping",
                                                        propertyName: "octalGrouping",
                                                        name: "Octal Grouping",
                                                        type: .freeText(validationStrategy: { Grouping(rawValue: $0) != nil }),
                                                        toOptions: { input, options in
                                                            guard let grouping = Grouping(rawValue: input.lowercased()) else {
                                                                throw FormatError.options("")
                                                            }
                                                            options.octalGrouping = grouping
                                                        },
                                                        fromOptions: { options in
                                                            options.octalGrouping.rawValue
    })
    static let hexGrouping = FormatOptions.Descriptor(argumentName: "hexgrouping",
                                                      propertyName: "hexGrouping",
                                                      name: "Hex Grouping",
                                                      type: .freeText(validationStrategy: { Grouping(rawValue: $0) != nil }),
                                                      toOptions: { input, options in
                                                          guard let grouping = Grouping(rawValue: input.lowercased()) else {
                                                              throw FormatError.options("")
                                                          }
                                                          options.hexGrouping = grouping
                                                      },
                                                      fromOptions: { options in
                                                          options.hexGrouping.rawValue
    })
    static let letPatternPlacement = FormatOptions.Descriptor(argumentName: "patternlet",
                                                              propertyName: "hoistPatternLet",
                                                              name: "Pattern Let",
                                                              type: .binary(true: ["hoist"], false: ["inline"]),
                                                              toOptions: { input, options in
                                                                  switch input.lowercased() {
                                                                  case "hoist":
                                                                      options.hoistPatternLet = true
                                                                  case "inline":
                                                                      options.hoistPatternLet = false
                                                                  default:
                                                                      throw FormatError.options("")
                                                                  }
                                                              },
                                                              fromOptions: { options in
                                                                  options.hoistPatternLet ? "hoist" : "inline"
    })
    static let stripUnusedArguments = FormatOptions.Descriptor(argumentName: "stripunusedargs",
                                                               propertyName: "stripUnusedArguments",
                                                               name: "Strip Unused Arguments",
                                                               type: .list(["unnamed-only", "closure-only", "always"]),
                                                               toOptions: { input, options in
                                                                   guard let type = ArgumentStrippingMode(rawValue: input.lowercased()) else {
                                                                       throw FormatError.options("")
                                                                   }
                                                                   options.stripUnusedArguments = type
                                                               },
                                                               fromOptions: { options in
                                                                   options.stripUnusedArguments.rawValue
    })
    static let elsePosition = FormatOptions.Descriptor(argumentName: "elseposition",
                                                       propertyName: "elseOnNextLine",
                                                       name: "Else Position",
                                                       type: .binary(true: ["next-line", "nextline"], false: ["same-line", "sameline"]),
                                                       toOptions: { input, options in
                                                           switch input.lowercased() {
                                                           case "nextline", "next-line":
                                                               options.elseOnNextLine = true
                                                           case "sameline", "same-line":
                                                               options.elseOnNextLine = false
                                                           default:
                                                               throw FormatError.options("")
                                                           }
                                                       },
                                                       fromOptions: { options in
                                                           options.elseOnNextLine ? "next-line" : "same-line"
    })
    static let removeSelf = FormatOptions.Descriptor(argumentName: "self",
                                                     propertyName: "removeSelf",
                                                     name: "Self",
                                                     type: .binary(true: ["remove"], false: ["insert"]),
                                                     toOptions: { input, options in
                                                         switch input.lowercased() {
                                                         case "remove":
                                                             options.removeSelf = true
                                                         case "insert":
                                                             options.removeSelf = false
                                                         default:
                                                             throw FormatError.options("")
                                                         }
                                                     },
                                                     fromOptions: { options in
                                                         options.removeSelf ? "remove" : "insert"
    })
    static let experimentalRules = FormatOptions.Descriptor(argumentName: "experimental",
                                                            propertyName: "experimentalRules",
                                                            name: "Experimental Rules",
                                                            type: .binary(true: ["enabled", "true"], false: ["disabled", "false"]),
                                                            toOptions: { input, options in
                                                                switch input.lowercased() {
                                                                case "enabled", "true":
                                                                    options.experimentalRules = true
                                                                case "disabled", "false":
                                                                    options.experimentalRules = false
                                                                default:
                                                                    throw FormatError.options("")
                                                                }
                                                            },
                                                            fromOptions: { options in
                                                                options.experimentalRules ? "enabled" : "disabled"
    })
    static let fragment = FormatOptions.Descriptor(argumentName: "fragment",
                                                   propertyName: "fragment",
                                                   name: "Fragment",
                                                   type: .binary(true: ["true", "enabled"], false: ["false", "disabled"]),
                                                   toOptions: { input, options in
                                                       switch input.lowercased() {
                                                       case "true", "enabled":
                                                           options.fragment = true
                                                       case "false", "disabled":
                                                           options.fragment = false
                                                       default:
                                                           throw FormatError.options("")
                                                       }
                                                   },
                                                   fromOptions: { options in
                                                       options.fragment ? "true" : "false"
    })
    static let ignoreConflictMarkers = FormatOptions.Descriptor(argumentName: "conflictmarkers",
                                                                propertyName: "ignoreConflictMarkers",
                                                                name: "Conflict Markers",
                                                                type: .binary(true: ["ignore", "true", "enabled"], false: ["reject", "false", "disabled"]),
                                                                toOptions: { input, options in
                                                                    switch input.lowercased() {
                                                                    case "ignore", "true", "enabled":
                                                                        options.ignoreConflictMarkers = true
                                                                    case "reject", "false", "disabled":
                                                                        options.ignoreConflictMarkers = false
                                                                    default:
                                                                        throw FormatError.options("")
                                                                    }
                                                                },
                                                                fromOptions: { options in
                                                                    options.ignoreConflictMarkers ? "ignore" : "reject"
    })
}

// MARK: - DEPRECATED

extension FormatOptions.Descriptor {
    static let deprecatedWithProperty = [
        insertBlankLines,
        removeBlankLines,
    ]

    static let deprecatedWithoutProperty = [
        hexLiterals,
        wrapElements,
    ]
    static let deprecated = deprecatedWithProperty + deprecatedWithoutProperty

    static let deprecatedMessage = [
        insertBlankLines.argumentName: "`--insertlines` option is deprecated. Use `--enable blankLinesBetweenScopes` or `--enable blankLinesAroundMark` or `--disable blankLinesBetweenScopes` or `--disable blankLinesAroundMark` instead.",
        removeBlankLines.argumentName: "`--removelines` option is deprecated. Use `--enable blankLinesAtStartOfScope` or `--enable blankLinesAtEndOfScope` or `--disable blankLinesAtStartOfScope` or `--disable blankLinesAtEndOfScope` instead",
        hexLiterals.argumentName: "`--hexliterals` option is deprecated. Use `--hexliteralcase` instead",
        wrapElements.argumentName: "`--wrapelements` option is deprecated. Use `--wrapcollections` instead",
    ]

    static let insertBlankLines = FormatOptions.Descriptor(argumentName: "insertlines",
                                                           propertyName: "insertBlankLines",
                                                           name: "Insert Lines",
                                                           type: .binary(true: ["enabled", "true"], false: ["disabled", "false"]),
                                                           toOptions: { input, options in
                                                               switch input.lowercased() {
                                                               case "enabled", "true":
                                                                   options.insertBlankLines = true
                                                               case "disabled", "false":
                                                                   options.insertBlankLines = false
                                                               default:
                                                                   throw FormatError.options("")
                                                               }
                                                           },
                                                           fromOptions: { options in
                                                               options.insertBlankLines ? "enabled" : "disabled"
    })
    static let removeBlankLines = FormatOptions.Descriptor(argumentName: "removelines",
                                                           propertyName: "removeBlankLines",
                                                           name: "Remove Lines",
                                                           type: .binary(true: ["enabled", "true"], false: ["disabled", "false"]),
                                                           toOptions: { input, options in
                                                               switch input.lowercased() {
                                                               case "enabled", "true":
                                                                   options.removeBlankLines = true
                                                               case "disabled", "false":
                                                                   options.removeBlankLines = false
                                                               default:
                                                                   throw FormatError.options("")
                                                               }
                                                           },
                                                           fromOptions: { options in
                                                               options.removeBlankLines ? "enabled" : "disabled"
    })
    static let hexLiterals = FormatOptions.Descriptor(argumentName: "hexliterals",
                                                      propertyName: "hexLiteralCase",
                                                      name: "hexliterals",
                                                      type: .binary(true: ["uppercase", "upper"], false: ["lowercase", "lower"]),
                                                      toOptions: { input, options in
                                                          switch input.lowercased() {
                                                          case "uppercase", "upper":
                                                              options.uppercaseHex = true
                                                          case "lowercase", "lower":
                                                              options.uppercaseHex = false
                                                          default:
                                                              throw FormatError.options("")
                                                          }
                                                      },
                                                      fromOptions: { options in
                                                          options.uppercaseHex ? "uppercase" : "lowercase"
    })
    static let wrapElements = FormatOptions.Descriptor(argumentName: "wrapelements",
                                                       propertyName: "wrapCollections",
                                                       name: "Wrap Elements",
                                                       type: .list(["beforefirst", "afterfirst", "disabled"]),
                                                       toOptions: { input, options in
                                                           if let mode = WrapMode(rawValue: input.lowercased()) {
                                                               options.wrapCollections = mode
                                                           } else {
                                                               throw FormatError.options("")
                                                           }
                                                       },
                                                       fromOptions: { options in
                                                           options.wrapCollections.rawValue
    })
}
