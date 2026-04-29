import SwiftUI

/// Main board view — Vibrancy variation: inline toolbar above a horizontally
/// scrolling row of translucent columns.
struct BoardView: View {
    @Bindable var viewModel: BoardViewModel
    let onIssueSelected: (String) -> Void
    var onCreateIssue: () -> Void = {}
    var onSearchToggle: () -> Void = {}

    @State private var filterText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            BoardToolbar(
                viewModel: viewModel,
                filterText: $filterText,
                onSearchToggle: onSearchToggle,
                onCreateIssue: onCreateIssue
            )

            content
        }
        .padding(VibrancyTokens.Spacing.windowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.columns.isEmpty {
            VStack {
                Spacer()
                ProgressView("Loading board…")
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else if viewModel.columns.isEmpty {
            VStack {
                Spacer()
                ContentUnavailableView(
                    "No Board Selected",
                    systemImage: "rectangle.3.group",
                    description: Text("Select a project from the sidebar to view its board.")
                )
                Spacer()
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: VibrancyTokens.Spacing.columnGap) {
                    ForEach(viewModel.columns) { column in
                        BoardColumnView(
                            column: filteredColumn(column),
                            onIssueSelected: onIssueSelected
                        )
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: .infinity, alignment: .top)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
    }

    private func filteredColumn(_ column: BoardColumn) -> BoardColumn {
        guard !filterText.isEmpty else { return column }
        let needle = filterText.lowercased()
        var copy = column
        copy.issues = column.issues.filter {
            $0.summary.lowercased().contains(needle)
                || $0.key.lowercased().contains(needle)
        }
        return copy
    }
}
