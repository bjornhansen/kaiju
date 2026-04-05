import SwiftUI

/// Renders ADF content as SwiftUI views
/// v1.0 supports: paragraph, heading (1-6), bulletList, orderedList, listItem,
/// codeBlock, blockquote, text with marks (strong, em, code, link, underline, strike)
struct ADFRendererView: View {
    let document: ADFDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(document.content.enumerated()), id: \.offset) { _, node in
                ADFBlockNodeView(node: node)
            }
        }
    }
}

struct ADFBlockNodeView: View {
    let node: ADFNode

    var body: some View {
        switch node.type {
        case "paragraph":
            ADFParagraphView(node: node)

        case "heading":
            ADFHeadingView(node: node, level: node.attrs?.level ?? 1)

        case "bulletList":
            ADFListView(node: node, ordered: false)

        case "orderedList":
            ADFListView(node: node, ordered: true)

        case "codeBlock":
            ADFCodeBlockView(node: node)

        case "blockquote":
            ADFBlockquoteView(node: node)

        default:
            // Fallback: render children if any
            if let children = node.content {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        ADFBlockNodeView(node: child)
                    }
                }
            }
        }
    }
}

struct ADFParagraphView: View {
    let node: ADFNode

    var body: some View {
        if let content = node.content {
            ADFInlineContentView(nodes: content)
        }
    }
}

struct ADFHeadingView: View {
    let node: ADFNode
    let level: Int

    var body: some View {
        if let content = node.content {
            ADFInlineContentView(nodes: content)
                .font(fontForLevel(level))
                .fontWeight(.bold)
        }
    }

    private func fontForLevel(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        case 5: return .subheadline
        default: return .body
        }
    }
}

struct ADFListView: View {
    let node: ADFNode
    let ordered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let items = node.content {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 6) {
                        if ordered {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                        } else {
                            Text("•")
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if let children = item.content {
                                ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                                    ADFBlockNodeView(node: child)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.leading, 8)
    }
}

struct ADFCodeBlockView: View {
    let node: ADFNode

    var body: some View {
        let text = node.content?.compactMap(\.text).joined() ?? ""
        ScrollView(.horizontal, showsIndicators: false) {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ADFBlockquoteView: View {
    let node: ADFNode

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.accentColor.opacity(0.5))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                if let children = node.content {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        ADFBlockNodeView(node: child)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

/// Renders inline content (text nodes with marks) as a composed Text view
struct ADFInlineContentView: View {
    let nodes: [ADFNode]

    var body: some View {
        nodes.reduce(Text("")) { result, node in
            result + renderInlineNode(node)
        }
        .textSelection(.enabled)
    }

    private func renderInlineNode(_ node: ADFNode) -> Text {
        switch node.type {
        case "text":
            return applyMarks(Text(node.text ?? ""), marks: node.marks ?? [])

        case "hardBreak":
            return Text("\n")

        default:
            return Text(node.text ?? "")
        }
    }

    private func applyMarks(_ text: Text, marks: [ADFMark]) -> Text {
        var result = text
        for mark in marks {
            switch mark.type {
            case "strong":
                result = result.bold()
            case "em":
                result = result.italic()
            case "code":
                result = result.font(.system(.body, design: .monospaced))
                    .foregroundColor(.orange)
            case "underline":
                result = result.underline()
            case "strike":
                result = result.strikethrough()
            case "link":
                if let href = mark.attrs?.href {
                    result = result.foregroundColor(.accentColor)
                    // Note: Full link handling requires wrapping in a Button/Link
                    _ = href  // Suppress unused warning; link rendered as colored text in v1
                }
            default:
                break
            }
        }
        return result
    }
}
