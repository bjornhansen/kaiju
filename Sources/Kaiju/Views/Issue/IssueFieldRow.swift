import SwiftUI

/// A row in the inspector's properties block. Matches the Vibrancy spec:
/// 88px label column on the left, value on the right, no icons.
struct IssueFieldRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)

            content()
                .font(.system(size: 12.5))

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}
