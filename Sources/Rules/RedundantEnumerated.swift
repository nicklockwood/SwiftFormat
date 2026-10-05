//
//  RedundantEnumerated.swift
//  SwiftFormat
//
//  Created by Nick Lockwood on 05/10/2026.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Remove enumerated() from loops that do not use the index
    static let redundantEnumerated = FormatRule(
        help: "Remove `.enumerated()` from for loops where the index is unused.",
        orderAfter: [.unusedArguments, .preferForLoop]
    ) { formatter in
        formatter.forEach(.keyword("for")) { i, _ in
            formatter.removeRedundantEnumerated(at: i)
        }
    } examples: {
        """
        ```diff
        - for (_, element) in elements.enumerated() {
        + for element in elements {
              print(element)
          }
        ```
        """
    }
}

extension Formatter {
    func removeRedundantEnumerated(at forIndex: Int) {
        guard let patternStart = index(of: .nonSpaceOrCommentOrLinebreak, after: forIndex),
              tokens[patternStart] == .startOfScope("("),
              let patternEnd = endOfScope(at: patternStart),
              let inIndex = index(of: .nonSpaceOrCommentOrLinebreak, after: patternEnd),
              tokens[inIndex] == .keyword("in")
        else { return }

        let bindings = parseTupleArguments(startOfScope: patternStart)
        guard bindings.count == 2,
              bindings.allSatisfy({ $0.label == nil && $0.valueRange.count == 1 && tokens[$0.valueRange.lowerBound].isIdentifier })
        else { return }

        guard let sequenceStart = index(of: .nonSpaceOrCommentOrLinebreak, after: inIndex),
              let sequence = parseExpressionRange(startingAt: sequenceStart),
              let enumerated = redundantEnumeratedCall(endingAt: sequence.upperBound),
              startOfMemberCallReceiver(endingAt: enumerated.lowerBound) == sequenceStart,
              let afterSequence = index(of: .nonSpaceOrCommentOrLinebreak, after: sequence.upperBound),
              [.keyword("where"), .startOfScope("{")].contains(tokens[afterSequence]),
              let bodyStart = startOfForLoopBody(after: sequence.upperBound),
              let bodyEnd = endOfScope(at: bodyStart)
        else { return }

        let indexBinding = bindings[0].valueRange.lowerBound
        let name = tokens[indexBinding].unescaped()
        if name != "_" {
            var names = [name]
            var indices = [indexBinding]
            removeUsed(from: &names, with: &indices, in: bodyStart + 1 ..< bodyEnd)
            if tokens[afterSequence] == .keyword("where") {
                removeUsed(from: &names, with: &indices, in: afterSequence + 1 ..< bodyStart)
            }
            guard !names.isEmpty else { return }
        }

        let element = bindings[1].valueRange.lowerBound
        // Leave the loop unchanged if removing the call or binding would discard comments.
        guard !tokens[enumerated].contains(where: \.isComment),
              !tokens[patternStart ..< element].contains(where: \.isComment),
              !tokens[element + 1 ... patternEnd].contains(where: \.isComment)
        else { return }

        removeTokens(in: enumerated)
        removeTokens(in: element + 1 ... patternEnd)
        removeTokens(in: patternStart ..< element)
    }

    /// Finds an enumerated() call through trailing reversed() calls, which preserve elements.
    func redundantEnumeratedCall(endingAt endIndex: Int) -> ClosedRange<Int>? {
        guard tokens[endIndex] == .endOfScope(")"),
              let callStart = startOfScope(at: endIndex),
              index(of: .nonSpaceOrCommentOrLinebreak, after: callStart) == endIndex,
              let method = index(of: .nonSpaceOrCommentOrLinebreak, before: callStart),
              let dot = index(of: .nonSpaceOrCommentOrLinebreak, before: method),
              tokens[dot] == .operator(".", .infix)
        else { return nil }

        switch tokens[method] {
        case .identifier("enumerated"):
            return dot ... endIndex
        case .identifier("reversed"):
            guard let receiverEnd = index(of: .nonSpaceOrCommentOrLinebreak, before: dot) else {
                return nil
            }
            return redundantEnumeratedCall(endingAt: receiverEnd)
        default:
            return nil
        }
    }
}
