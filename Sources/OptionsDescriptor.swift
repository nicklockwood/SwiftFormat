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
        enum ArgumentType: EnumAssociatable {
            case binary(true: [String], false: [String]) // index 0 should be the official value, while others are tolerable values
            case list([String])
            case freeText(validationStrategy: (String) -> Bool)
        }

        let id: String //  argumentName & propertyName can change overtime, `id` should be timeless
        let argumentName: String
        let propertyName: String
        let name: String
        let type: ArgumentType
        let defaultArgument: String
        let toOptions: (String, inout FormatOptions) throws -> Void
        let fromOptions: (FormatOptions) -> String
    }
}

extension FormatOptions.Descriptor {
    static let indentation = FormatOptions.Descriptor(id: "indentation",
                                                      argumentName: "indent",
                                                      propertyName: "indent",
                                                      name: "indent",
                                                      type: .freeText(validationStrategy: { input in
                                                          let validText = Set<String>(arrayLiteral: "tab", "tabs", "tabbed")
                                                          var result = validText.contains(input.lowercased())
                                                          result = result || Int(input.trimmingCharacters(in: .whitespaces)) != nil
                                                          return result
                                                      }),
                                                      defaultArgument: "4",
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
    static let lineBreak = FormatOptions.Descriptor(id: "linebreak-character",
                                                    argumentName: "linebreaks",
                                                    propertyName: "linebreak",
                                                    name: "linebreak",
                                                    type: .list(["cr", "lf", "crlf"]),
                                                    defaultArgument: "lf",
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
    static let allowInlineSemicolons = FormatOptions.Descriptor(id: "allow-inline-semicolons",
                                                                argumentName: "semicolons",
                                                                propertyName: "allowInlineSemicolons",
                                                                name: "allowInlineSemicolons",
                                                                type: .binary(true: ["inline"], false: ["never", "false"]),
                                                                defaultArgument: "inline",
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
    static let spaceAroundRangeOperators = FormatOptions.Descriptor(id: "space-around-range-operators",
                                                                    argumentName: "ranges",
                                                                    propertyName: "spaceAroundRangeOperators",
                                                                    name: "spaceAroundRangeOperators",
                                                                    type: .binary(true: ["space", "spaced", "spaces"], false: ["nospace"]),
                                                                    defaultArgument: "space",
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
    static let spaceAroundOperatorDeclarations = FormatOptions.Descriptor(id: "space-around-operator-declarations",
                                                                          argumentName: "operatorfunc",
                                                                          propertyName: "spaceAroundOperatorDeclarations",
                                                                          name: "spaceAroundOperatorDeclarations",
                                                                          type: .binary(true: ["space", "spaced", "spaces"], false: ["nospace"]),
                                                                          defaultArgument: "space",
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
    static let useVoid = FormatOptions.Descriptor(id: "void-representation",
                                                  argumentName: "empty",
                                                  propertyName: "useVoid",
                                                  name: "empty",
                                                  type: .binary(true: ["void"], false: ["tuple", "tuples"]),
                                                  defaultArgument: "void",
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
    static let indentCase = FormatOptions.Descriptor(id: "indent-case",
                                                     argumentName: "indentcase",
                                                     propertyName: "indentCase",
                                                     name: "indentCase",
                                                     type: .binary(true: ["true"], false: ["false"]),
                                                     defaultArgument: "false",
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
    static let trailingCommas = FormatOptions.Descriptor(id: "trailing-commas",
                                                         argumentName: "commas",
                                                         propertyName: "trailingCommas",
                                                         name: "trailingCommas",
                                                         type: .binary(true: ["always", "true"], false: ["inline", "false"]),
                                                         defaultArgument: "always",
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
    static let indentComments = FormatOptions.Descriptor(id: "indent-comments",
                                                         argumentName: "comments",
                                                         propertyName: "indentComments",
                                                         name: "indentComments",
                                                         type: .binary(true: ["indent", "indented"], false: ["ignore"]),
                                                         defaultArgument: "indent",
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
    static let truncateBlankLines = FormatOptions.Descriptor(id: "truncate-blank-lines",
                                                             argumentName: "trimwhitespace",
                                                             propertyName: "truncateBlankLines",
                                                             name: "truncateBlankLines",
                                                             type: .binary(true: ["always"], false: ["nonblank-lines", "nonblank", "non-blank-lines", "non-blank", "nonempty-lines", "nonempty", "non-empty-lines", "non-empty"]),
                                                             defaultArgument: "always",
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
    static let insertBlankLines = FormatOptions.Descriptor(id: "insert-blank-lines",
                                                           argumentName: "insertlines",
                                                           propertyName: "insertBlankLines",
                                                           name: "insertBlankLines",
                                                           type: .binary(true: ["enabled", "true"], false: ["disabled", "false"]),
                                                           defaultArgument: "enabled",
                                                           toOptions: { input, options in
                                                               switch input.lowercased() {
                                                               case "enabled", "true":
                                                                   //  FIXME: Need a way to Define DEPRECATION and DEPRECATION's Messages
//                                                                print("`--insertlines` option is deprecated. Use `--enable blankLinesBetweenScopes` or `--enable blankLinesAroundMark` instead", as: .warning)
                                                                   options.insertBlankLines = true
                                                               case "disabled", "false":
//                                                                print("`--insertlines` option is deprecated. Use `--disable blankLinesBetweenScopes` or `--disbable blankLinesAroundMark` instead", as: .warning)
                                                                   options.insertBlankLines = false
                                                               default:
                                                                   throw FormatError.options("")
                                                               }
                                                           },
                                                           fromOptions: { options in
                                                               options.insertBlankLines ? "enabled" : "disabled"
    })
    static let removeBlankLines = FormatOptions.Descriptor(id: "remove-blank-lines",
                                                           argumentName: "removelines",
                                                           propertyName: "removeBlankLines",
                                                           name: "removeBlankLines",
                                                           type: .binary(true: ["enabled", "true"], false: ["disabled", "false"]),
                                                           defaultArgument: "enabled",
                                                           toOptions: { input, options in
                                                               switch input.lowercased() {
                                                               case "enabled", "true":
                                                                   //  FIXME: Need a way to Define DEPRECATION and DEPRECATION's Messages
//                                                                print("`--removelines` option is deprecated. Use `--enable blankLinesAtStartOfScope` or `--enable blankLinesAtEndOfScope` instead", as: .warning)
                                                                   options.removeBlankLines = true
                                                               case "disabled", "false":
//                                                                print("`--removelines` option is deprecated. Use `--disable blankLinesAtStartOfScope` or `--disable blankLinesAtEndOfScope` instead", as: .warning)
                                                                   options.removeBlankLines = false
                                                               default:
                                                                   throw FormatError.options("")
                                                               }
                                                           },
                                                           fromOptions: { options in
                                                               options.removeBlankLines ? "enabled" : "disabled"
    })
    static let allmanBraces = FormatOptions.Descriptor(id: "allman-braces",
                                                       argumentName: "allman",
                                                       propertyName: "allmanBraces",
                                                       name: "allmanBraces",
                                                       type: .binary(true: ["true", "enabled"], false: ["false", "disabled"]),
                                                       defaultArgument: "false",
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
    static let fileHeader = FormatOptions.Descriptor(id: "file-header",
                                                     argumentName: "header",
                                                     propertyName: "fileHeader",
                                                     name: "fileHeader",
                                                     type: .freeText(validationStrategy: { _ in true }),
                                                     defaultArgument: "ignore",
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
    static let ifdefIndent = FormatOptions.Descriptor(id: "if-def-indent-mode",
                                                      argumentName: "ifdef",
                                                      propertyName: "ifdefIndent",
                                                      name: "ifdefIndent",
                                                      type: .list(["indent", "noindent", "outdent"]),
                                                      defaultArgument: "indent",
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
    static let wrapArguments = FormatOptions.Descriptor(id: "wrap-arguments",
                                                        argumentName: "wraparguments",
                                                        propertyName: "wrapArguments",
                                                        name: "wrapArguments",
                                                        type: .list(["beforefirst", "afterfirst", "disabled"]),
                                                        defaultArgument: "disabled",
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
    static let wrapElements = FormatOptions.Descriptor(id: "wrap-elements",
                                                       argumentName: "wrapelements",
                                                       propertyName: "wrapElements",
                                                       name: "wrapElements",
                                                       type: .list(["beforefirst", "afterfirst", "disabled"]),
                                                       defaultArgument: "beforefirst",
                                                       toOptions: { input, options in
                                                           if let mode = WrapMode(rawValue: input.lowercased()) {
                                                               options.wrapElements = mode
                                                           } else {
                                                               throw FormatError.options("")
                                                           }
                                                       },
                                                       fromOptions: { options in
                                                           options.wrapElements.rawValue
    })
    static let hexLiteralCase = FormatOptions.Descriptor(id: "hex-literal-case",
                                                         argumentName: "hexliteralcase",
                                                         propertyName: "uppercaseHex",
                                                         name: "hexLiteralCase",
                                                         type: .binary(true: ["uppercase", "upper"], false: ["lowercase", "lower"]),
                                                         defaultArgument: "uppercase",
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
    static let decimalGrouping = FormatOptions.Descriptor(id: "decimal-grouping",
                                                          argumentName: "decimalgrouping",
                                                          propertyName: "decimalGrouping",
                                                          name: "decimalGrouping",
                                                          type: .freeText(validationStrategy: { Grouping(rawValue: $0) != nil }),
                                                          defaultArgument: "3,6",
                                                          toOptions: { input, options in
                                                              guard let grouping = Grouping(rawValue: input.lowercased()) else {
                                                                  throw FormatError.options("")
                                                              }
                                                              options.decimalGrouping = grouping
                                                          },
                                                          fromOptions: { $0.decimalGrouping.rawValue })
}
