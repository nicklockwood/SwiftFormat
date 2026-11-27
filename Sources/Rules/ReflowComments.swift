//
//  ReflowComments.swift
//  SwiftFormat
//
//  Created by Rui Nelson on 11/27/26.
//  Copyright © 2026 Nick Lockwood. All rights reserved.
//

import Foundation

public extension FormatRule {
    /// Join the lines of each comment paragraph, so that it can be wrapped again from scratch
    static let reflowComments = FormatRule(
        help: "Join the wrapped lines of each paragraph in a comment into a single line.",
        disabledByDefault: true,
        orderAfter: [.todos],
        options: ["reflow-comments"],
        sharedOptions: ["linebreaks", "max-width", "indent", "tab-width", "asset-literals"]
    ) { formatter in
        // The file header is left as written, and so is any run of `//` lines that the file starts with
        var lastReadIndex = (formatter.headerCommentTokenRange(includingDirectives: ["*"])?.upperBound ?? 0) - 1
        if let startIndex = formatter.index(of: .nonSpaceOrLinebreak, after: -1),
           var comment = formatter.reflowLineComment(at: startIndex), comment.slashes != 3
        {
            while let next = formatter.reflowLineComment(after: comment), next.slashes != 3 {
                comment = next
            }
            lastReadIndex = max(lastReadIndex, comment.range.upperBound)
        }

        formatter.forEachToken { i, token in
            guard i > lastReadIndex else { return }
            // Read for each comment, since an options directive in the file can change it part way through
            let kinds = formatter.options.reflowComments
            let comment: (range: ClosedRange<Int>, reflowedTokens: [Token]?)?
            switch token {
            case .startOfScope("//"):
                comment = formatter.reflowLineComments(at: i, kinds: kinds)
            case .startOfScope("/*") where kinds.contains("block"):
                comment = formatter.reflowBlockComment(at: i)
            default:
                return
            }
            guard case let (range, reflowedTokens)? = comment else { return }
            // Lines read as part of this comment must not be read again as the start of another one
            lastReadIndex = range.upperBound
            guard let reflowedTokens else { return }
            formatter.replaceTokens(in: range, with: reflowedTokens)
            lastReadIndex = i + reflowedTokens.count - 1
        }
    } examples: {
        """
        `--reflow-comments` chooses which comments are reflowed: `line` (`//`), `block` (`/* */` and `/** */`)
        and `doc` (`///`). Paragraphs, lists, tables, headings, fenced code blocks and comment directives such as
        `MARK:` or `TODO:` keep their line breaks.

        ```diff
        - /// Returns the number of
        - /// items in the list.
        - ///
        - /// - Parameter filter: Only
        - ///   items matching this
        - ///   filter are counted.
        + /// Returns the number of items in the list.
        + ///
        + /// - Parameter filter: Only items matching this filter are counted.
          func count(matching filter: Filter) -> Int
        ```

        Combine with `wrapSingleLineComments` and `--max-width` to rewrap `//` and `///` comments to the new width.
        """
    }
}

extension Formatter {
    /// Reads the run of `//` or `///` comment lines starting at `index`, returning the tokens it spans
    /// and, when they change, the reflowed tokens to replace them with.
    func reflowLineComments(at index: Int, kinds: Set<String>) -> (range: ClosedRange<Int>, reflowedTokens: [Token]?)? {
        guard let first = reflowLineComment(at: index) else { return nil }
        // Blank lines at either end of a run set it apart from the lines around it, and directives such as `MARK:`
        // stand alone, so both are kept as written
        guard !first.text.isBlankCommentLine, ReflowCommentDirective(first.text) != .standsAlone else {
            return (first.range, nil)
        }
        // A run stops at the end of the formatted range, and at directives, such as those that change which rules
        // are enabled
        func continues(onto next: ReflowLineComment) -> Bool {
            isEnabled(at: next.range.upperBound) && ReflowCommentDirective(next.text) != .standsAlone
        }

        var comments = [first]
        let marker: String
        var keepsLines = false
        switch first.slashes {
        case 3 where first.isStandalone && kinds.contains("doc"):
            marker = "///"
            while let next = reflowLineComment(after: comments[comments.count - 1]), next.slashes == 3,
                  continues(onto: next)
            {
                comments.append(next)
            }
        case 2 where kinds.contains("line"):
            marker = "//"
            // `wrapSingleLineComments` never wraps a comment that starts like a directive, such as `TODO:`,
            // so the paragraph such a comment starts is read but kept as written
            keepsLines = first.body.isCommentDirective
            // A comment after code only continues on `//` lines lined up under it. `wrapSingleLineComments`
            // starts the lines it wraps text beginning with `/` onto with a `/` of their own, so such a line
            // is not joined to the one before: each pass would add another `/`.
            while let next = reflowLineComment(after: comments[comments.count - 1]), next.slashes == 2,
                  first.isStandalone || next.column == first.column,
                  ReflowCommentDirective(next.text) == nil, !next.text.isCommentDirective, !next.body.hasPrefix("/"),
                  !(keepsLines && next.text.isBlankCommentLine), continues(onto: next)
            {
                comments.append(next)
            }
        default:
            return nil
        }
        // The first line is not blank, so this keeps at least one line
        while comments[comments.count - 1].text.isBlankCommentLine {
            comments.removeLast()
        }

        let range = first.range.lowerBound ... comments[comments.count - 1].range.upperBound
        let texts = comments.map(\.text)
        let reflowed = texts.reflowedParagraphs(joiningListsToPreviousParagraph: false)
        guard !keepsLines, reflowed.map(\.text) != texts else { return (range, nil) }

        // The continuation lines of a comment after code line up with the second line, not with the code
        let indentedComment = first.isStandalone ? first : comments.dropFirst().first ?? first
        let indent = currentIndentForLine(at: indentedComment.range.lowerBound)
        let lines = reflowed.enumerated().map { offset, line in
            (text: (offset == 0 ? "" : indent) + marker + (line.text.isEmpty ? "" : " " + line.text),
             linebreak: line.source > 0 ? tokens[comments[line.source - 1].range.upperBound + 1] : linebreakToken(for: index))
        }
        return (range, reflowedCommentTokens(lines, at: index))
    }

    /// Reads the `/* … */` comment starting at `index`, returning the tokens it spans
    /// and, when they change, the reflowed tokens to replace them with.
    func reflowBlockComment(at index: Int) -> (range: ClosedRange<Int>, reflowedTokens: [Token]?)? {
        guard let endIndex = endOfScope(at: index) else { return nil }
        let range = index ... endIndex
        let linebreaks = tokens[range].filter(\.isLinebreak)
        let lines = tokens[range].split(omittingEmptySubsequences: false, whereSeparator: \.isLinebreak)
            .map { sourceCode(for: Array($0)) }

        // Comments on a single line, comments holding other comments, banners such as `/*****` … `*****/`,
        // comments that change which rules are enabled, and comments running past the formatted range
        // are left as written.
        guard lines.count > 1, let opener = lines.first, let closer = lines.last,
              self.index(of: .startOfScope("/*"), in: index + 1 ..< endIndex) == nil,
              !opener.hasPrefix("/***"), !closer.hasSuffix("**/"),
              !lines.contains(where: { $0.contains("swiftformat:") }), isEnabled(at: endIndex)
        else {
            return (range, nil)
        }

        let marker = opener.hasPrefix("/**") ? "/**" : "/*"
        let openerText = opener.dropFirst(marker.count).trimmingCharacters(in: .whitespacesAndNewlines)
        let textBeforeCloser = String(closer.dropLast(2))
        let closesAfterText = !textBeforeCloser.isBlankCommentLine
        var body = Array(lines[1 ..< lines.count - 1])
        if closesAfterText {
            body.append(textBeforeCloser)
        }

        // A ` * ` margin down the left side, as in `/**` documentation comments, is framing rather than text
        let nonBlankBody = body.filter { !$0.isBlankCommentLine }
        let hasStarMargin = !nonBlankBody.isEmpty && nonBlankBody.allSatisfy { line in
            let trimmed = line.drop(while: \.isSpaceOrTab)
            return trimmed.first == "*" && trimmed.dropFirst().first?.isSpaceOrTab != false
        }
        let indent = nonBlankBody.first.map { String($0.prefix(while: \.isSpaceOrTab)) } ?? ""

        let texts = body.map { line -> String in
            var text = Substring(line)
            if hasStarMargin {
                text = text.drop(while: \.isSpaceOrTab)
                if text.first == "*" {
                    text = text.dropFirst()
                }
                if text.first == " " {
                    text = text.dropFirst()
                }
            } else {
                text = text.dropFirst(min(indent.count, text.prefix(while: \.isSpaceOrTab).count))
            }
            return String(text).trimmingTrailingWhitespace()
        }

        // Line `n` of the comment, from the second on, follows `linebreaks[n - 1]`
        func linebreak(before line: Int) -> Token {
            line > 0 ? linebreaks[line - 1] : linebreakToken(for: index)
        }
        func withMargin(_ text: String) -> String {
            if hasStarMargin {
                return text.isEmpty ? indent + "*" : indent + "* " + text
            }
            return text.isEmpty ? "" : indent + text
        }

        // The texts are numbered like `lines`: the opener's text, then the body
        var reflowed = ([openerText] + texts).reflowedParagraphs(joiningListsToPreviousParagraph: true)[...]
        var output = [(text: String, linebreak: Token)]()
        if let first = reflowed.first, first.source == 0 {
            output.append((marker + " " + first.text, linebreak(before: 0)))
            reflowed = reflowed.dropFirst()
        } else {
            output.append((marker, linebreak(before: 0)))
        }
        output += reflowed.map { (withMargin($0.text), linebreak(before: $0.source)) }
        if closesAfterText {
            output[output.count - 1].text += " */"
        } else {
            output.append((closer, linebreak(before: lines.count - 1)))
        }
        return (range, output.map(\.text) == lines ? nil : reflowedCommentTokens(output, at: index))
    }

    /// Tokenizes the reflowed lines of the comment starting at `index`, each line after the first following
    /// the given linebreak token, so that lines that are unchanged keep their original line numbers.
    func reflowedCommentTokens(_ lines: [(text: String, linebreak: Token)], at index: Int) -> [Token]? {
        // A comment after code is not joined past the maximum width, where wrapping would move it or the code
        if startOfLine(at: index, excludingIndent: true) != index, options.maxWidth > 0,
           lineLength(upTo: index) + lines[0].text.count > options.maxWidth
        {
            return nil
        }
        var linebreaks = lines.dropFirst().map(\.linebreak).makeIterator()
        return tokenize(lines.map(\.text).joined(separator: "\n")).map {
            $0.isLinebreak ? linebreaks.next() ?? $0 : $0
        }
    }

    /// Reads the `//` comment starting at `index`
    func reflowLineComment(at index: Int) -> ReflowLineComment? {
        guard tokens[index] == .startOfScope("//") else { return nil }
        let lineStart = startOfLine(at: index)
        let lineEnd = endOfLine(at: index)
        var text = sourceCode(for: Array(tokens[index + 1 ..< lineEnd]))
        let extraSlashes = text.prefix(while: { $0 == "/" }).count
        text.removeFirst(extraSlashes)
        if text.first == " " {
            text.removeFirst()
        }
        return ReflowLineComment(
            range: index ... lineEnd - 1,
            slashes: 2 + extraSlashes,
            text: text.trimmingTrailingWhitespace(),
            isStandalone: startOfLine(at: index, excludingIndent: true) == index,
            column: tokens[lineStart ..< index].reduce(0) { $0 + $1.string.count }
        )
    }

    /// Reads the `//` comment that has a line of its own right after `comment`
    func reflowLineComment(after comment: ReflowLineComment) -> ReflowLineComment? {
        let linebreakIndex = comment.range.upperBound + 1
        guard token(at: linebreakIndex)?.isLinebreak == true,
              let nextIndex = index(of: .nonSpace, after: linebreakIndex)
        else {
            return nil
        }
        return reflowLineComment(at: nextIndex)
    }
}

/// A `//`-style comment, split into its marker and the text to reflow
struct ReflowLineComment {
    /// The comment's tokens, from the `//` to the end of the line
    var range: ClosedRange<Int>
    /// The number of slashes in the marker: 2 for `//`, 3 for `///`, more for `////` separator lines
    var slashes: Int
    /// The comment text, without the space after the marker and without trailing whitespace
    var text: String
    /// Whether only indentation precedes the comment
    var isStandalone: Bool
    /// The offset of the marker from the start of its line, in characters
    var column: Int

    /// The comment text without its indentation, as `wrapSingleLineComments` reads it
    var body: String {
        String(text.drop(while: \.isWhitespace))
    }
}

/// How a `//` comment that tools read by its position is kept apart from the comment lines around it
private enum ReflowCommentDirective {
    /// A line of its own: Xcode shows the whole `MARK:` line, and linters and formatters parse the rest of theirs
    case standsAlone
    /// Starts a new comment, which may still run on over the next lines: `TODO:` and `FIXME:`
    case startsComment

    init?(_ text: String) {
        let text = text.drop(while: \.isSpaceOrTab)
        let lineDirectives = [
            "MARK:", "swiftlint:", "swift-format-ignore", "sourcery:", "periphery:", "swift-tools-version:",
        ]
        // SwiftFormat reads its own directives anywhere in a comment, not only at the start
        if text.contains("swiftformat:") || lineDirectives.contains(where: { text.hasPrefix($0) }) {
            self = .standsAlone
            return
        }
        for keyword in ["TODO", "FIXME"] where text.hasPrefix(keyword) {
            let next = text.dropFirst(keyword.count).first
            if next.map({ !$0.isLetter && !$0.isNumber }) ?? true {
                self = .startsComment
                return
            }
        }
        return nil
    }
}

/// A Markdown fenced code block delimiter: three or more backticks, or three or more tildes.
/// Content between a matching pair of fences is code, not prose, so it is kept as written.
private struct ReflowCodeFence {
    private let character: Character
    private let length: Int

    /// Reads an opening fence from a trimmed line
    init?(opening line: String) {
        guard let first = line.first, first == "`" || first == "~" else { return nil }
        let length = line.prefix(while: { $0 == first }).count
        // CommonMark: the info string of a backtick fence may not contain a backtick
        guard length >= 3, first == "~" || !line.dropFirst(length).contains("`") else { return nil }
        character = first
        self.length = length
    }

    /// Whether a trimmed line closes this fence: the same character, at least as many, and nothing after them
    func isClosed(by line: String) -> Bool {
        let length = line.prefix(while: { $0 == character }).count
        return length >= self.length && line.dropFirst(length).allSatisfy(\.isWhitespace)
    }
}

extension [String] {
    /// Joins the lines of each paragraph with single spaces, keeping one blank line between paragraphs.
    ///
    /// List items (`-`, `*`, `+`, `1.`), table rows and quotes (`>`) start a line of their own. Headings, rules
    /// and lines starting with a backtick stand alone, and fenced code blocks are kept as written.
    /// Each line returned comes with the index of the line it starts with.
    func reflowedParagraphs(joiningListsToPreviousParagraph: Bool) -> [(text: String, source: Int)] {
        typealias Line = (text: String, source: Int)
        var paragraphs = [(lines: [Line], blankLine: Int?)]()
        var paragraph = [Line]()
        // The first blank line before the current paragraph
        var blankLine: Int?
        var previousLineWasTableRow = false
        var previousLineStandsAlone = false
        var openFence: ReflowCodeFence?

        for (index, line) in enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Inside a fence even a blank line is content, so this precedes the paragraph split below
            let isCode: Bool
            if let fence = openFence {
                isCode = true
                if fence.isClosed(by: trimmed) {
                    openFence = nil
                }
            } else {
                openFence = ReflowCodeFence(opening: trimmed)
                isCode = openFence != nil
            }
            if isCode {
                paragraph.append((line.trimmingTrailingWhitespace(), index))
                previousLineWasTableRow = false
                previousLineStandsAlone = true
                continue
            }

            if trimmed.isEmpty {
                if !paragraph.isEmpty {
                    paragraphs.append((paragraph, blankLine))
                    paragraph = []
                    blankLine = index
                } else if blankLine == nil {
                    blankLine = index
                }
                previousLineWasTableRow = false
                previousLineStandsAlone = false
                continue
            }

            let isTableRow = trimmed.first == "|"
            let standsAlone = trimmed.first == "`" || trimmed.isMarkdownHeading || trimmed.isMarkdownRule
            if paragraph.isEmpty || isTableRow || previousLineWasTableRow || standsAlone || previousLineStandsAlone ||
                trimmed.isMarkdownListItem || trimmed.first == ">"
            {
                paragraph.append((line.trimmingTrailingWhitespace(), index))
            } else {
                paragraph[paragraph.count - 1].text += " " + trimmed
            }
            previousLineWasTableRow = isTableRow
            previousLineStandsAlone = standsAlone
        }
        if !paragraph.isEmpty {
            paragraphs.append((paragraph, blankLine))
        }

        var result = [Line]()
        for (lines, blankLine) in paragraphs {
            let isList = lines[0].text.trimmingCharacters(in: .whitespaces).isMarkdownBulletItem
            if !result.isEmpty, !(joiningListsToPreviousParagraph && isList) {
                result.append(("", blankLine ?? lines[0].source))
            }
            result += lines
        }
        return result
    }
}

extension Character {
    var isSpaceOrTab: Bool {
        self == " " || self == "\t"
    }
}

extension StringProtocol {
    var isBlankCommentLine: Bool {
        allSatisfy(\.isWhitespace)
    }

    func trimmingTrailingWhitespace() -> String {
        var result = String(self)
        while result.last?.isWhitespace == true {
            result.removeLast()
        }
        return result
    }

    /// Whether a trimmed line opens a list item: `-`, `*`, `+` or a number followed by `.`
    var isMarkdownListItem: Bool {
        isMarkdownBulletItem || range(of: #"^\d+\."#, options: .regularExpression) != nil
    }

    /// Whether a trimmed line opens a bullet list item: any line starting with `-`, or `*` / `+` and a space
    var isMarkdownBulletItem: Bool {
        guard let first else { return false }
        return first == "-" || ((first == "*" || first == "+") && dropFirst().first?.isSpaceOrTab == true)
    }

    /// Whether a trimmed line is an ATX heading: one to six `#` followed by a space or by nothing
    var isMarkdownHeading: Bool {
        let level = prefix(while: { $0 == "#" }).count
        return (1 ... 6).contains(level) && dropFirst(level).first?.isSpaceOrTab != false
    }

    /// Whether a trimmed line is a rule such as `---`, `***` or `=====`: three or more of one punctuation character
    var isMarkdownRule: Bool {
        let characters = filter { !$0.isSpaceOrTab }
        guard characters.count >= 3, let first = characters.first, "-*_=#+~".contains(first) else { return false }
        return characters.allSatisfy { $0 == first }
    }
}
