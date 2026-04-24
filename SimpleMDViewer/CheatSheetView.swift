import SwiftUI

struct CheatSheetView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Markdown Cheat Sheet")
                    .font(.title2.weight(.bold))

                section("Headings") {
                    row("# Heading 1", "Heading 1")
                    row("## Heading 2", "Heading 2")
                    row("### Heading 3", "Heading 3")
                }

                section("Emphasis") {
                    row("**bold**", "bold", style: .bold)
                    row("*italic*", "italic", style: .italic)
                    row("***bold italic***", "bold italic", style: .boldItalic)
                    row("~~strikethrough~~", "strikethrough", style: .strikethrough)
                }

                section("Lists") {
                    row("- item", "Unordered list")
                    row("1. item", "Ordered list")
                    row("- [ ] task", "Unchecked task")
                    row("- [x] task", "Checked task")
                }

                section("Links & Images") {
                    row("[text](url)", "Link")
                    row("![alt](url)", "Image")
                }

                section("Code") {
                    row("`inline code`", "Inline code")
                    row("```\ncode block\n```", "Fenced code block")
                }

                section("Other") {
                    row("> quote", "Blockquote")
                    row("---", "Horizontal rule")
                    row("| A | B |\n|---|---|\n| 1 | 2 |", "Table")
                }
            }
            .padding(40)
            .frame(maxWidth: 600, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private enum TextStyle {
        case normal, bold, italic, boldItalic, strikethrough
    }

    private func row(_ syntax: String, _ description: String, style: TextStyle = .normal) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Text(syntax)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 220, alignment: .leading)

            styledText(description, style: style)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func styledText(_ text: String, style: TextStyle) -> some View {
        switch style {
        case .normal:
            Text(text)
        case .bold:
            Text(text).bold()
        case .italic:
            Text(text).italic()
        case .boldItalic:
            Text(text).bold().italic()
        case .strikethrough:
            Text(text).strikethrough()
        }
    }
}
