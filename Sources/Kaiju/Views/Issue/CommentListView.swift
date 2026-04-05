import SwiftUI

/// A single comment row
struct CommentRowView: View {
    let comment: CommentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Author and date
            HStack(spacing: 8) {
                AvatarView(
                    url: comment.authorAvatarUrl,
                    displayName: comment.authorDisplayName,
                    size: 24
                )

                Text(comment.authorDisplayName ?? "Unknown")
                    .fontWeight(.medium)
                    .font(.callout)

                Spacer()

                if let created = comment.createdAt,
                   let date = DateFormatters.parseJiraDate(created) {
                    Text(DateFormatters.relativeString(from: date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Comment body (ADF)
            if let bodyAdf = comment.bodyAdf,
               let data = bodyAdf.data(using: .utf8),
               let doc = try? ADFParser.parse(data: data) {
                ADFRendererView(document: doc)
                    .font(.callout)
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}
