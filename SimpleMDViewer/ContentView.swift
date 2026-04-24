import SwiftUI

enum ViewMode: String, CaseIterable {
    case editor = "Editor"
    case preview = "Preview"
    case split = "Split"

    var icon: String {
        switch self {
        case .editor: return "square.and.pencil"
        case .preview: return "eye"
        case .split: return "rectangle.split.2x1"
        }
    }
}

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var viewMode: ViewMode = .preview
    @State private var showCheatSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if showCheatSheet {
                CheatSheetView()
            } else {
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
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Picker("View", selection: Binding(
                    get: { showCheatSheet ? nil : viewMode },
                    set: { newMode in
                        if let newMode {
                            viewMode = newMode
                        }
                        showCheatSheet = false
                    }
                )) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(Optional(mode))
                    }
                }
                .pickerStyle(.segmented)
                .help("Switch view mode")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    showCheatSheet.toggle()
                } label: {
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
        .frame(minWidth: 600, minHeight: 400)
    }

    private var stats: String {
        let words = document.text.split { $0.isWhitespace || $0.isNewline }.count
        let lines = document.text.components(separatedBy: "\n").count
        return "\(lines) lines  \(words) words"
    }
}
