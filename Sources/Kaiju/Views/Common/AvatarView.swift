import SwiftUI

/// Displays a user avatar or initials fallback
struct AvatarView: View {
    let url: String?
    let displayName: String?
    let size: CGFloat

    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { image in
                image.resizable()
            } placeholder: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else if displayName != nil {
            initialsView
        } else {
            // Unassigned
            Circle()
                .fill(Color(.separatorColor))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "person")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.4))
                    .fontWeight(.medium)
            }
    }

    private var initials: String {
        guard let name = displayName else { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}
