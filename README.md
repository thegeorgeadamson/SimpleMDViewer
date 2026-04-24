# SimpleMDViewer

A clean, native macOS markdown editor and viewer. Built with SwiftUI — no Electron, no dependencies, no fuss.

Open any `.md` file and read it the way it was meant to look. Edit it side-by-side with a live preview. Toggle between editor, preview, and split views with one click.

## Features

- **Three view modes** — editor only, preview only, or split view
- **Live preview** that updates as you type
- **Native macOS look** with automatic light and dark mode
- **Built-in cheat sheet** for when you forget the syntax for tables (again)
- **Word and line count** in the toolbar
- **File associations** — set it as the default app for `.md`, `.markdown`, `.mdown`, and `.mkd`
- **Sandboxed** and self-contained — no network access, no telemetry

Supports the markdown you actually use: headings, bold/italic/strikethrough, lists, task lists, tables, blockquotes, fenced code blocks, links, images, and inline code.

## Install

### Build from source

Requires Xcode 15 or later and macOS 14+.

```sh
git clone https://github.com/thegeorgeadamson/SimpleMDViewer.git
cd SimpleMDViewer
open SimpleMDViewer.xcodeproj
```

Then press **⌘R** to build and run, or **Product → Archive** to build a distributable `.app`.

## Why?

Most markdown apps on macOS are either bloated Electron wrappers or feature-stuffed editors with a monthly subscription. This is neither. It's a small, native app that opens markdown files and shows them nicely. That's the whole pitch.

## Contributing

Issues and PRs welcome. Keep things simple.

## License

[MIT](LICENSE)
