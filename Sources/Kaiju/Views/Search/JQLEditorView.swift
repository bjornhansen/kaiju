import SwiftUI

/// JQL query editor with syntax help
struct JQLEditorView: View {
    @Binding var query: String
    let onSubmit: () -> Void

    @State private var showHelp = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("JQL Query")
                    .font(.headline)
                Spacer()
                Button(action: { showHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                }
                .help("JQL Help")
                .popover(isPresented: $showHelp) {
                    jqlHelp
                }
            }

            TextEditor(text: $query)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 60, maxHeight: 120)
                .padding(4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)

            HStack {
                Spacer()
                Button("Run Query", action: onSubmit)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding()
    }

    private var jqlHelp: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JQL Quick Reference")
                .font(.headline)

            Group {
                helpRow("project = KEY", "Issues in project")
                helpRow("assignee = currentUser()", "Assigned to me")
                helpRow("status = \"In Progress\"", "By status")
                helpRow("priority = High", "By priority")
                helpRow("text ~ \"keyword\"", "Full text search")
                helpRow("updated >= -7d", "Updated in last 7 days")
                helpRow("ORDER BY updated DESC", "Sort results")
            }
        }
        .padding()
        .frame(width: 380)
    }

    private func helpRow(_ jql: String, _ description: String) -> some View {
        HStack {
            Text(jql)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tint)
            Spacer()
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
