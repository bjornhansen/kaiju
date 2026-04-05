import SwiftUI

/// Right-side split panel showing full issue details
struct IssueDetailView: View {
    @Bindable var viewModel: IssueDetailViewModel
    @State private var newComment = ""
    @State private var isEditingSummary = false
    @State private var editedSummary = ""

    var body: some View {
        Group {
            if let issue = viewModel.issue {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header: key, type, status
                        issueHeader(issue)

                        Divider()

                        // Summary (editable)
                        summarySection(issue)

                        // Description
                        if let description = viewModel.description {
                            descriptionSection(description)
                        }

                        Divider()

                        // Fields
                        fieldsSection(issue)

                        Divider()

                        // Attachments
                        if !viewModel.attachments.isEmpty {
                            attachmentsSection
                            Divider()
                        }

                        // Comments
                        commentsSection
                    }
                    .padding(20)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading issue...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Issue Selected",
                    systemImage: "doc.text",
                    description: Text("Select an issue from the board to view details.")
                )
            }
        }
        .frame(minWidth: 360, idealWidth: 440)
    }

    // MARK: - Header

    private func issueHeader(_ issue: IssueRecord) -> some View {
        HStack(spacing: 8) {
            IssueTypeIcon(typeName: issue.issueTypeName)

            Text(issue.key)
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            if let statusName = issue.statusName {
                StatusBadge(name: statusName, category: issue.statusCategory)
            }
        }
    }

    // MARK: - Summary

    private func summarySection(_ issue: IssueRecord) -> some View {
        Group {
            if isEditingSummary {
                HStack {
                    TextField("Summary", text: $editedSummary)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .onSubmit {
                            Task {
                                await viewModel.updateSummary(editedSummary)
                                isEditingSummary = false
                            }
                        }
                    Button("Save") {
                        Task {
                            await viewModel.updateSummary(editedSummary)
                            isEditingSummary = false
                        }
                    }
                    Button("Cancel") {
                        isEditingSummary = false
                    }
                }
            } else {
                Text(issue.summary)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textSelection(.enabled)
                    .onTapGesture(count: 2) {
                        editedSummary = issue.summary
                        isEditingSummary = true
                    }
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(_ description: ADFDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundStyle(.secondary)

            ADFRendererView(document: description)
        }
    }

    // MARK: - Fields

    private func fieldsSection(_ issue: IssueRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            IssueFieldRow(label: "Status", icon: "circle.fill") {
                if !viewModel.availableTransitions.isEmpty {
                    Menu(issue.statusName ?? "Unknown") {
                        ForEach(viewModel.availableTransitions, id: \.id) { transition in
                            Button(transition.name) {
                                Task {
                                    await viewModel.transitionIssue(
                                        transitionId: transition.id,
                                        toStatusName: transition.to.name,
                                        toStatusId: transition.to.id
                                    )
                                }
                            }
                        }
                    }
                } else {
                    StatusBadge(name: issue.statusName ?? "Unknown", category: issue.statusCategory)
                }
            }

            IssueFieldRow(label: "Assignee", icon: "person.fill") {
                HStack(spacing: 6) {
                    AvatarView(
                        url: issue.assigneeAvatarUrl,
                        displayName: issue.assigneeDisplayName,
                        size: 20
                    )
                    Text(issue.assigneeDisplayName ?? "Unassigned")
                        .foregroundStyle(issue.assigneeDisplayName != nil ? .primary : .secondary)
                }
            }

            IssueFieldRow(label: "Reporter", icon: "person.fill") {
                Text(issue.reporterDisplayName ?? "Unknown")
            }

            if let priorityName = issue.priorityName {
                IssueFieldRow(label: "Priority", icon: "flag.fill") {
                    HStack(spacing: 4) {
                        PriorityBadge(priorityName: priorityName)
                        Text(priorityName)
                    }
                }
            }

            if let labelsJSON = issue.labels,
               let labels = try? JSONDecoder().decode([String].self, from: Data(labelsJSON.utf8)),
               !labels.isEmpty {
                IssueFieldRow(label: "Labels", icon: "tag.fill") {
                    FlowLayout(spacing: 4) {
                        ForEach(labels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            if let storyPoints = issue.storyPoints {
                IssueFieldRow(label: "Story Points", icon: "number") {
                    Text("\(Int(storyPoints))")
                }
            }

            if let created = issue.createdAt {
                IssueFieldRow(label: "Created", icon: "calendar") {
                    Text(DateFormatters.parseJiraDate(created).map(DateFormatters.displayString) ?? created)
                        .foregroundStyle(.secondary)
                }
            }

            if let updated = issue.updatedAt {
                IssueFieldRow(label: "Updated", icon: "clock") {
                    Text(DateFormatters.parseJiraDate(updated).map(DateFormatters.relativeString) ?? updated)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments (\(viewModel.attachments.count))")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.attachments, id: \.id) { attachment in
                HStack {
                    Image(systemName: iconForMimeType(attachment.mimeType))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(attachment.filename)
                            .lineLimit(1)
                        if let size = attachment.size {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    if let urlString = attachment.contentUrl, let url = URL(string: urlString) {
                        Link(destination: url) {
                            Image(systemName: "arrow.down.circle")
                        }
                    }
                }
                .padding(6)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments (\(viewModel.comments.count))")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Add comment
            HStack(alignment: .top, spacing: 8) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                    .lineLimit(1...5)

                Button("Send") {
                    let text = newComment
                    newComment = ""
                    Task { await viewModel.addComment(text: text) }
                }
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Comment list
            ForEach(viewModel.comments, id: \.id) { comment in
                CommentRowView(comment: comment)
            }
        }
    }

    private func iconForMimeType(_ mimeType: String?) -> String {
        guard let mime = mimeType?.lowercased() else { return "doc" }
        if mime.hasPrefix("image/") { return "photo" }
        if mime.contains("pdf") { return "doc.richtext" }
        if mime.contains("zip") || mime.contains("archive") { return "archivebox" }
        return "doc"
    }
}

/// A simple horizontal flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}
