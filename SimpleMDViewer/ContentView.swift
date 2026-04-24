import SwiftUI

enum ViewMode: String, CaseIterable {
    case editor = "Editor"
    case preview = "Preview"
    case split = "Split"

    var icon: String {
        switch self {
        case .editor: return "square.and.pencil"
        case .preview: return "eye"
        case .split:   return "rectangle.split.2x1"
        }
    }
}

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var viewMode: ViewMode = .preview
    @State private var showingCheatSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if showingCheatSheet {
                CheatSheetView()
            } else {
                modeContent
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .toolbar { toolbar }
    }

    @ViewBuilder
    private var modeContent: some View {
        switch viewMode {
        case .editor:
            EditorView(text: $document.text)
        case .preview:
            MarkdownPreview(markdown: document.text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .split:
            HSplitView {
                EditorView(text: $document.text)
                    .frame(minWidth: 300)
                MarkdownPreview(markdown: document.text)
                    .frame(minWidth: 300, maxHeight: .infinity)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Picker("View", selection: pickerSelection) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(Optional(mode))
                }
            }
            .pickerStyle(.segmented)
            .help("Switch view mode")
        }

        ToolbarItem(placement: .automatic) {
            Button { showingCheatSheet.toggle() } label: {
                Image(systemName: "questionmark.circle")
            }
            .help("Markdown Cheat Sheet")
        }

        ToolbarItem(placement: .automatic) {
            Text(stats)
                .font(.caption)
                .foregroundColor(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 10)
        }
    }

    // The picker shows no selection while the cheat sheet is up — picking a
    // mode dismisses the cheat sheet and selects that mode.
    private var pickerSelection: Binding<ViewMode?> {
        Binding(
            get: { showingCheatSheet ? nil : viewMode },
            set: { selected in
                if let selected { viewMode = selected }
                showingCheatSheet = false
            }
        )
    }

    private var stats: String {
        let lines = document.text.components(separatedBy: "\n").count
        let words = document.text.split { $0.isWhitespace || $0.isNewline }.count
        return "\(lines) lines  \(words) words"
    }
}
