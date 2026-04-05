import SwiftUI

/// Main board view showing kanban columns
struct BoardView: View {
    @Bindable var viewModel: BoardViewModel
    let onIssueSelected: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            BoardToolbar(viewModel: viewModel)

            Divider()

            // Board columns
            if viewModel.isLoading && viewModel.columns.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Loading board...")
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
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(viewModel.columns) { column in
                            BoardColumnView(
                                column: column,
                                onIssueSelected: onIssueSelected
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
