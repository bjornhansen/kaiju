import SwiftUI

/// A row in the issue detail fields section
struct IssueFieldRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 16)
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)

            content()
                .font(.callout)
        }
    }
}
