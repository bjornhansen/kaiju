import SwiftUI

/// Search view with JQL input and results
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    let onIssueSelected: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // JQL input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Enter JQL query or search text...", text: $viewModel.jqlQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await viewModel.search() }
                    }

                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Search") {
                    Task { await viewModel.search() }
                }
                .disabled(viewModel.jqlQuery.isEmpty)
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))

            Divider()

            // Results
            if viewModel.results.isEmpty && !viewModel.isSearching {
                VStack {
                    Spacer()
                    if viewModel.errorMessage != nil {
                        ContentUnavailableView(
                            "Search Error",
                            systemImage: "exclamationmark.triangle",
                            description: Text(viewModel.errorMessage ?? "")
                        )
                    } else {
                        ContentUnavailableView(
                            "Search Jira",
                            systemImage: "magnifyingglass",
                            description: Text("Enter a JQL query or search text above")
                        )
                    }
                    Spacer()
                }
            } else {
                List {
                    if viewModel.totalResults > 0 {
                        Text("\(viewModel.totalResults) results")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.results, id: \.key) { issue in
                        SearchResultRow(issue: issue)
                            .contentShape(Rectangle())
                            .onTapGesture { onIssueSelected(issue.key) }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct SearchResultRow: View {
    let issue: IssueRecord

    var body: some View {
        HStack(spacing: 10) {
            IssueTypeIcon(typeName: issue.issueTypeName)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(issue.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)

                    if let statusName = issue.statusName {
                        StatusBadge(name: statusName, category: issue.statusCategory)
                    }
                }

                Text(issue.summary)
                    .lineLimit(1)
            }

            Spacer()

            if let priorityName = issue.priorityName {
                PriorityBadge(priorityName: priorityName)
            }

            AvatarView(
                url: issue.assigneeAvatarUrl,
                displayName: issue.assigneeDisplayName,
                size: 20
            )
        }
        .padding(.vertical, 4)
    }
}
