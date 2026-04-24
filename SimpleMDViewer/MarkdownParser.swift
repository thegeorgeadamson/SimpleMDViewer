import Foundation

struct MarkdownParser {
    static func toHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var html: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(escapeHTML(lines[i]))
                    i += 1
                }
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(escapeHTML(lang))\""
                html.append("<pre><code\(langAttr)>\(code.joined(separator: "\n"))</code></pre>")
                if i < lines.count { i += 1 } // skip closing fence if present
                continue
            }

            // Horizontal rule
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if isHorizontalRule(trimmed) {
                html.append("<hr>")
                i += 1
                continue
            }

            // Headings
            if let match = line.prefixMatch(of: /^(#{1,6})\s+(.+)/) {
                let level = match.1.count
                let content = inlineFormat(String(match.2))
                html.append("<h\(level)>\(content)</h\(level)>")
                i += 1
                continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                var quoteLines: [String] = []
                while i < lines.count && lines[i].hasPrefix(">") {
                    let content = lines[i].hasPrefix("> ") ? String(lines[i].dropFirst(2)) :
                                  String(lines[i].dropFirst(1))
                    quoteLines.append(content)
                    i += 1
                }
                let inner = MarkdownParser.toHTML(quoteLines.joined(separator: "\n"))
                html.append("<blockquote>\(inner)</blockquote>")
                continue
            }

            // Unordered list
            if line.prefixMatch(of: /^(\s*)([-*+])\s+(.*)/) != nil {
                var listItems: [String] = []
                while i < lines.count {
                    if let m = lines[i].prefixMatch(of: /^(\s*)([-*+])\s+(.*)/) {
                        listItems.append("<li>\(inlineFormat(String(m.3)))</li>")
                        i += 1
                    } else if lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                html.append("<ul>\(listItems.joined())</ul>")
                continue
            }

            // Ordered list
            if line.prefixMatch(of: /^(\s*)\d+\.\s+(.*)/) != nil {
                var listItems: [String] = []
                while i < lines.count {
                    if let m = lines[i].prefixMatch(of: /^(\s*)\d+\.\s+(.*)/) {
                        listItems.append("<li>\(inlineFormat(String(m.2)))</li>")
                        i += 1
                    } else if lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                        i += 1
                        break
                    } else {
                        break
                    }
                }
                html.append("<ol>\(listItems.joined())</ol>")
                continue
            }

            // Table
            if i + 1 < lines.count && lines[i + 1].contains("---") && lines[i].contains("|") {
                let headerCells = parseTableRow(lines[i])
                i += 2
                var rows: [String] = []
                while i < lines.count && lines[i].contains("|") {
                    let cells = parseTableRow(lines[i])
                    let tds = cells.map { "<td>\(inlineFormat($0))</td>" }.joined()
                    rows.append("<tr>\(tds)</tr>")
                    i += 1
                }
                let ths = headerCells.map { "<th>\(inlineFormat($0))</th>" }.joined()
                html.append("<table><thead><tr>\(ths)</tr></thead><tbody>\(rows.joined())</tbody></table>")
                continue
            }

            // Empty line
            if trimmed.isEmpty {
                i += 1
                continue
            }

            // Paragraph
            var paraLines: [String] = []
            while i < lines.count {
                let pLine = lines[i]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)
                if pTrimmed.isEmpty
                    || pLine.hasPrefix("#") || pLine.hasPrefix(">")
                    || pLine.hasPrefix("```")
                    || isHorizontalRule(pTrimmed)
                    || pLine.prefixMatch(of: /^(\s*)([-*+])\s+(.*)/) != nil
                    || pLine.prefixMatch(of: /^(\s*)\d+\.\s+(.*)/) != nil {
                    break
                }
                paraLines.append(pLine)
                i += 1
            }
            html.append("<p>\(inlineFormat(paraLines.joined(separator: "\n")))</p>")
        }

        return html.joined(separator: "\n")
    }

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
        guard trimmed.count >= 3 else { return false }
        let chars = trimmed.filter { $0 != " " }
        guard chars.count >= 3 else { return false }
        return chars.allSatisfy({ $0 == "-" }) ||
               chars.allSatisfy({ $0 == "*" }) ||
               chars.allSatisfy({ $0 == "_" })
    }

    private static func parseTableRow(_ line: String) -> [String] {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        let inner = stripped.hasPrefix("|") ? String(stripped.dropFirst()) : stripped
        let end = inner.hasSuffix("|") ? String(inner.dropLast()) : inner
        return end.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    static func inlineFormat(_ text: String) -> String {
        var result = text

        // Extract and protect inline code spans first
        var codeSpans: [String] = []
        let codePattern = try! NSRegularExpression(pattern: "`([^`]+)`")
        result = replaceMatches(in: result, regex: codePattern) { match in
            let code = escapeHTML(match[1])
            let placeholder = "\u{FFFC}CODE\(codeSpans.count)\u{FFFC}"
            codeSpans.append("<code>\(code)</code>")
            return placeholder
        }

        // Escape HTML in remaining text
        result = escapeHTML(result)

        // Images (before links) — unescape &amp; back in URLs
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<img alt=\"$1\" src=\"$2\" style=\"max-width:100%\">",
            options: .regularExpression)

        // Links
        result = result.replacingOccurrences(
            of: "\\[([^\\]]*)\\]\\(([^)]+)\\)",
            with: "<a href=\"$2\">$1</a>",
            options: .regularExpression)

        // Fix escaped ampersands in URLs
        result = result.replacingOccurrences(
            of: "(href|src)=\"([^\"]*)&amp;([^\"]*)\"",
            with: "$1=\"$2&$3\"",
            options: .regularExpression)

        // Bold+italic
        result = result.replacingOccurrences(
            of: "\\*\\*\\*(.+?)\\*\\*\\*",
            with: "<strong><em>$1</em></strong>",
            options: .regularExpression)

        // Bold
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "<strong>$1</strong>",
            options: .regularExpression)

        // Italic
        result = result.replacingOccurrences(
            of: "\\*(.+?)\\*",
            with: "<em>$1</em>",
            options: .regularExpression)

        // Strikethrough
        result = result.replacingOccurrences(
            of: "~~(.+?)~~",
            with: "<del>$1</del>",
            options: .regularExpression)

        // Checkboxes
        result = result.replacingOccurrences(of: "\\[ \\]", with: "<input type=\"checkbox\" disabled>", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\[x\\]", with: "<input type=\"checkbox\" checked disabled>", options: [.regularExpression, .caseInsensitive])

        // Line breaks
        result = result.replacingOccurrences(of: "  \n", with: "<br>")

        // Restore code spans
        for (index, code) in codeSpans.enumerated() {
            result = result.replacingOccurrences(of: "\u{FFFC}CODE\(index)\u{FFFC}", with: code)
        }

        return result
    }

    private static func replaceMatches(in string: String, regex: NSRegularExpression, using transform: ([String]) -> String) -> String {
        let nsString = string as NSString
        let matches = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))
        var result = string
        for match in matches.reversed() {
            var groups: [String] = []
            for g in 0..<match.numberOfRanges {
                let range = match.range(at: g)
                groups.append(range.location != NSNotFound ? nsString.substring(with: range) : "")
            }
            let replacement = transform(groups)
            result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
        }
        return result
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
