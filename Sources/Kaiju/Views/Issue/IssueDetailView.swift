import SwiftUI

/// Inspector panel showing full issue details. Vibrancy styling: header
/// with key + close button, large title, properties block with hairline
/// dividers, then body sections (description, attachments, comments).
struct IssueDetailView: View {
    @Bindable var viewModel: IssueDetailViewModel
    var onClose: () -> Void = {}

    @State private var newComment = ""
    @State private var isEditingSummary = false
    @State private var editedSummary = ""

    var body: some View {
        Group {
            if let issue = viewModel.issue {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(issue)
                        summarySection(issue)
                        propertiesBlock(issue)

                        if let description = viewModel.description {
                            descriptionSection(description)
                        }

                        if !viewModel.attachments.isEmpty {
                            attachmentsSection
                        }

                        commentsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollContentBackground(.hidden)
            } else if viewModel.isLoading {
                ProgressView("Loading issue…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No Issue Selected",
                    systemImage: "doc.text",
                    description: Text("Select an issue from the board to view details.")
                )
            }
        }
        .frame(minWidth: 320, idealWidth: 400)
    }

    // MARK: - Header

    private func header(_ issue: IssueRecord) -> some View {
        HStack(spacing: 8) {
            IssueTypeIcon(typeName: issue.issueTypeName)
            Text(issue.key)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle().fill(Color.primary.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)
            .help("Close")
        }
    }

    // MARK: - Summary

    private func summarySection(_ issue: IssueRecord) -> some View {
        Group {
            if isEditingSummary {
                HStack {
                    TextField("Summary", text: $editedSummary)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .semibold))
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
                    .controlSize(.small)
                    Button("Cancel") {
                        isEditingSummary = false
                    }
                    .controlSize(.small)
                }
            } else {
                Text(issue.summary)
                    .font(.system(size: 18, weight: .semibold))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture(count: 2) {
                        editedSummary = issue.summary
                        isEditingSummary = true
                    }
            }
        }
    }

    // MARK: - Properties

    private func propertiesBlock(_ issue: IssueRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().opacity(0.6)

            VStack(alignment: .leading, spacing: 0) {
                IssueFieldRow(label: "Status") {
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
                        .controlSize(.small)
                    } else {
                        StatusBadge(name: issue.statusName ?? "Unknown", category: issue.statusCategory)
                    }
                }

                if let priorityName = issue.priorityName {
                    IssueFieldRow(label: "Priority") {
                        HStack(spacing: 6) {
                            PriorityBadge(priorityName: priorityName)
                            Text(priorityName)
                        }
                    }
                }

                IssueFieldRow(label: "Assignee") {
                    HStack(spacing: 6) {
                        AvatarView(
                            url: issue.assigneeAvatarUrl,
                            displayName: issue.assigneeDisplayName,
                            size: 18
                        )
                        Text(issue.assigneeDisplayName ?? "Unassigned")
                            .foregroundStyle(issue.assigneeDisplayName != nil ? .primary : .secondary)
                    }
                }

                IssueFieldRow(label: "Reporter") {
                    Text(issue.reporterDisplayName ?? "Unknown")
                }

                if let labels = decodedLabels(issue), !labels.isEmpty {
                    IssueFieldRow(label: "Labels") {
                        FlowLayout(spacing: 4) {
                            ForEach(labels, id: \.self) { label in
                                Text(label)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(VibrancyTokens.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(VibrancyTokens.accent.opacity(0.12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .strokeBorder(VibrancyTokens.accent.opacity(0.25), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }

                if let storyPoints = issue.storyPoints {
                    IssueFieldRow(label: "Story Points") {
                        Text("\(Int(storyPoints))")
                    }
                }

                if let dueDate = issue.dueDate, !dueDate.isEmpty {
                    IssueFieldRow(label: "Due") {
                        Text(formattedDueDate(dueDate))
                    }
                }

                if let created = issue.createdAt {
                    IssueFieldRow(label: "Created") {
                        Text(DateFormatters.parseJiraDate(created).map(DateFormatters.displayString) ?? created)
                            .foregroundStyle(.secondary)
                    }
                }

                if let updated = issue.updatedAt {
                    IssueFieldRow(label: "Updated") {
                        Text(DateFormatters.parseJiraDate(updated).map(DateFormatters.relativeString) ?? updated)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider().opacity(0.6)
        }
    }

    private func decodedLabels(_ issue: IssueRecord) -> [String]? {
        guard let labelsJSON = issue.labels else { return nil }
        return try? JSONDecoder().decode([String].self, from: Data(labelsJSON.utf8))
    }

    private func formattedDueDate(_ raw: String) -> String {
        let parsed = Self.dueDateInputFormatter.date(from: raw)
            ?? DateFormatters.parseJiraDate(raw)
        guard let date = parsed else { return raw }
        return Self.dueDateDisplayFormatter.string(from: date)
    }

    private static let dueDateInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let dueDateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    // MARK: - Description

    private func descriptionSection(_ description: ADFDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Description")
            ADFRendererView(document: description)
                .font(.system(size: 13))
        }
    }

    // MARK: - Attachments

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Attachments (\(viewModel.attachments.count))")

            ForEach(viewModel.attachments, id: \.id) { attachment in
                HStack(spacing: 8) {
                    Image(systemName: iconForMimeType(attachment.mimeType))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(attachment.filename)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        if let size = attachment.size {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    if let urlString = attachment.contentUrl, let url = URL(string: urlString) {
                        Link(destination: url) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
            }
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Comments (\(viewModel.comments.count))")

            HStack(alignment: .top, spacing: 8) {
                TextField("Add a comment…", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
                    .lineLimit(1...5)

                Button {
                    let text = newComment
                    newComment = ""
                    Task { await viewModel.addComment(text: text) }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(VibrancyTokens.accent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ForEach(viewModel.comments, id: \.id) { comment in
                CommentRowView(comment: comment)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
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
