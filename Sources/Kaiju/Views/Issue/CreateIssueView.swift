import SwiftUI

/// Modal for creating a new issue
struct CreateIssueView: View {
    @Bindable var viewModel: CreateIssueViewModel
    let defaultProjectKey: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Issue")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Form
            Form {
                TextField("Project Key", text: $viewModel.selectedProjectKey)
                    .textFieldStyle(.roundedBorder)

                Picker("Issue Type", selection: $viewModel.issueTypeName) {
                    if viewModel.availableIssueTypes.isEmpty {
                        Text("Task").tag("Task")
                        Text("Bug").tag("Bug")
                        Text("Story").tag("Story")
                    } else {
                        ForEach(viewModel.availableIssueTypes, id: \.id) { type in
                            Text(type.name ?? "Unknown").tag(type.name ?? "Task")
                        }
                    }
                }

                TextField("Summary *", text: $viewModel.summary)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $viewModel.descriptionText)
                        .frame(minHeight: 80, maxHeight: 200)
                        .padding(4)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                }

                if !viewModel.availablePriorities.isEmpty {
                    Picker("Priority", selection: $viewModel.priorityId) {
                        Text("None").tag(nil as String?)
                        ForEach(viewModel.availablePriorities, id: \.id) { priority in
                            Text(priority.name ?? "Unknown").tag(priority.id as String?)
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal)

            Divider()

            // Actions
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])

                Button("Create") {
                    Task {
                        let success = await viewModel.createIssue()
                        if success { dismiss() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.summary.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isCreating)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .task {
            viewModel.selectedProjectKey = defaultProjectKey
            await viewModel.loadFormData()
        }
    }
}
