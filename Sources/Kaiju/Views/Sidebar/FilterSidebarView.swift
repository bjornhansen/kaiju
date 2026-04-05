import SwiftUI

/// Sidebar section for saved/recent searches
struct FilterSidebarView: View {
    let recentSearches: [String]
    let onSelect: (String) -> Void

    var body: some View {
        Section("Recent Searches") {
            if recentSearches.isEmpty {
                Text("No recent searches")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            } else {
                ForEach(recentSearches, id: \.self) { query in
                    Button(action: { onSelect(query) }) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text(query)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
