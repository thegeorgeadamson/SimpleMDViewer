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
                    row("**bold**", "bold") { $0.bold() }
                    row("*italic*", "italic") { $0.italic() }
                    row("***bold italic***", "bold italic") { $0.bold().italic() }
                    row("~~strikethrough~~", "strikethrough") { $0.strikethrough() }
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

    private func row(_ syntax: String, _ description: String, style: (Text) -> Text = { $0 }) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Text(syntax)
                .font(.system(.body, design: .monospaced))
                .frame(width: 220, alignment: .leading)

            style(Text(description))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
