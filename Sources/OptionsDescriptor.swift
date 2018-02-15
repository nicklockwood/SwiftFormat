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
