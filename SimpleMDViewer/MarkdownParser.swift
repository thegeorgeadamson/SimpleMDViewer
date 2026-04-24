import Foundation

/// A small Markdown → HTML converter. Covers the syntax most notes
/// actually use: headings, lists (incl. tasks), tables, blockquotes,
/// fenced code, emphasis, links, images, and horizontal rules.
enum MarkdownParser {

    static func toHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var out: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                out.append(parseFence(lines, &i))
            } else if isHorizontalRule(trimmed) {
                out.append("<hr>")
                i += 1
            } else if let heading = parseHeading(line) {
                out.append(heading)
                i += 1
            } else if line.hasPrefix(">") {
                out.append(parseBlockquote(lines, &i))
            } else if line.prefixMatch(of: bulletRegex) != nil {
                out.append(parseUnorderedList(lines, &i))
            } else if line.prefixMatch(of: orderedRegex) != nil {
                out.append(parseOrderedList(lines, &i))
            } else if isTableHeader(at: i, in: lines) {
                out.append(parseTable(lines, &i))
            } else if trimmed.isEmpty {
                i += 1
            } else {
                out.append(parseParagraph(lines, &i))
            }
        }

        return out.joined(separator: "\n")
    }

    // MARK: - Block parsers

    private static func parseFence(_ lines: [String], _ i: inout Int) -> String {
        let lang = String(lines[i].dropFirst(3)).trimmingCharacters(in: .whitespaces)
        i += 1

        var body: [String] = []
        while i < lines.count, !lines[i].hasPrefix("```") {
            body.append(escapeHTML(lines[i]))
            i += 1
        }
        if i < lines.count { i += 1 }  // skip closing fence

        let attr = lang.isEmpty ? "" : " class=\"language-\(escapeHTML(lang))\""
        return "<pre><code\(attr)>\(body.joined(separator: "\n"))</code></pre>"
    }

    private static func parseHeading(_ line: String) -> String? {
        guard let m = line.prefixMatch(of: headingRegex) else { return nil }
        let level = m.1.count
        return "<h\(level)>\(inlineFormat(String(m.2)))</h\(level)>"
    }

    private static func parseBlockquote(_ lines: [String], _ i: inout Int) -> String {
        var inner: [String] = []
        while i < lines.count, lines[i].hasPrefix(">") {
            let stripped = lines[i].hasPrefix("> ")
                ? String(lines[i].dropFirst(2))
                : String(lines[i].dropFirst(1))
            inner.append(stripped)
            i += 1
        }
        return "<blockquote>\(toHTML(inner.joined(separator: "\n")))</blockquote>"
    }

    private static func parseUnorderedList(_ lines: [String], _ i: inout Int) -> String {
        var items: [String] = []
        while i < lines.count {
            if let m = lines[i].prefixMatch(of: bulletRegex) {
                items.append("<li>\(inlineFormat(String(m.3)))</li>")
                i += 1
            } else if lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        return "<ul>\(items.joined())</ul>"
    }

    private static func parseOrderedList(_ lines: [String], _ i: inout Int) -> String {
        var items: [String] = []
        while i < lines.count {
            if let m = lines[i].prefixMatch(of: orderedRegex) {
                items.append("<li>\(inlineFormat(String(m.2)))</li>")
                i += 1
            } else if lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                break
            } else {
                break
            }
        }
        return "<ol>\(items.joined())</ol>"
    }

    private static func parseTable(_ lines: [String], _ i: inout Int) -> String {
        let header = parseTableRow(lines[i])
        i += 2  // header row + separator

        var rows: [String] = []
        while i < lines.count, lines[i].contains("|") {
            let cells = parseTableRow(lines[i]).map { "<td>\(inlineFormat($0))</td>" }
            rows.append("<tr>\(cells.joined())</tr>")
            i += 1
        }

        let head = header.map { "<th>\(inlineFormat($0))</th>" }.joined()
        return "<table><thead><tr>\(head)</tr></thead><tbody>\(rows.joined())</tbody></table>"
    }

    private static func parseParagraph(_ lines: [String], _ i: inout Int) -> String {
        var collected: [String] = []
        while i < lines.count, !startsNewBlock(lines[i]) {
            collected.append(lines[i])
            i += 1
        }
        return "<p>\(inlineFormat(collected.joined(separator: "\n")))</p>"
    }

    // MARK: - Block detection

    private static let headingRegex = #/^(#{1,6})\s+(.+)/#
    private static let bulletRegex  = #/^(\s*)([-*+])\s+(.*)/#
    private static let orderedRegex = #/^(\s*)\d+\.\s+(.*)/#

    private static func startsNewBlock(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        if line.hasPrefix("#") || line.hasPrefix(">") || line.hasPrefix("```") { return true }
        if isHorizontalRule(trimmed) { return true }
        return line.prefixMatch(of: bulletRegex) != nil
            || line.prefixMatch(of: orderedRegex) != nil
    }

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
        let chars = trimmed.filter { $0 != " " }
        guard chars.count >= 3 else { return false }
        return chars.allSatisfy({ $0 == "-" })
            || chars.allSatisfy({ $0 == "*" })
            || chars.allSatisfy({ $0 == "_" })
    }

    private static func isTableHeader(at i: Int, in lines: [String]) -> Bool {
        i + 1 < lines.count
            && lines[i].contains("|")
            && lines[i + 1].contains("---")
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var s = line.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("|") { s.removeFirst() }
        if s.hasSuffix("|") { s.removeLast() }
        return s.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Inline formatting

    static func inlineFormat(_ text: String) -> String {
        // Pull code spans out before HTML-escaping or any other inline rule
        // mangles what's inside the backticks.
        var stash: [String] = []
        var result = stashCodeSpans(text, into: &stash)

        result = escapeHTML(result)

        // Images must run before links — both share the `[ ]( )` shape and
        // a naked link rule would happily swallow the leading "!".
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<img alt=\"$1\" src=\"$2\" style=\"max-width:100%\">",
            options: .regularExpression)
        result = result.replacingOccurrences(
            of: "\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression)

        // escapeHTML turned `&` into `&amp;` inside the URLs we just inserted.
        // Restore them so query strings still work.
        result = result.replacingOccurrences(
            of: "(href|src)=\"([^\"]*)&amp;([^\"]*)\"",
            with: "$1=\"$2&$3\"",
            options: .regularExpression)

        // Order matters: *** before ** before *.
        result = result.replacingOccurrences(of: "\\*\\*\\*(.+?)\\*\\*\\*", with: "<strong><em>$1</em></strong>", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*",       with: "<strong>$1</strong>",          options: .regularExpression)
        result = result.replacingOccurrences(of: "\\*(.+?)\\*",             with: "<em>$1</em>",                  options: .regularExpression)
        result = result.replacingOccurrences(of: "~~(.+?)~~",               with: "<del>$1</del>",                options: .regularExpression)

        result = result.replacingOccurrences(of: "\\[ \\]", with: "<input type=\"checkbox\" disabled>", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\[x\\]", with: "<input type=\"checkbox\" checked disabled>", options: [.regularExpression, .caseInsensitive])

        // Two trailing spaces on a line is the Markdown hard line break.
        result = result.replacingOccurrences(of: "  \n", with: "<br>")

        for (idx, code) in stash.enumerated() {
            result = result.replacingOccurrences(of: placeholder(idx), with: code)
        }
        return result
    }

    // MARK: - Inline helpers

    private static let codeSpanPattern = try! NSRegularExpression(pattern: "`([^`]+)`")

    private static func stashCodeSpans(_ text: String, into stash: inout [String]) -> String {
        let range = NSRange(location: 0, length: (text as NSString).length)
        var out = ""
        var cursor = text.startIndex

        codeSpanPattern.enumerateMatches(in: text, range: range) { match, _, _ in
            guard
                let match,
                let full = Range(match.range, in: text),
                let inner = Range(match.range(at: 1), in: text)
            else { return }

            out += text[cursor..<full.lowerBound]
            stash.append("<code>\(escapeHTML(String(text[inner])))</code>")
            out += placeholder(stash.count - 1)
            cursor = full.upperBound
        }
        out += text[cursor...]
        return out
    }

    private static func placeholder(_ index: Int) -> String {
        "\u{FFFC}CODE\(index)\u{FFFC}"
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
