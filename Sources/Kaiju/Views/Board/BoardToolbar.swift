import SwiftUI

/// Toolbar for the board view with board selector and actions
struct BoardToolbar: View {
    @Bindable var viewModel: BoardViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Board name
            if !viewModel.boardName.isEmpty {
                Text(viewModel.boardName)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Board selector (if multiple boards)
            if viewModel.availableBoards.count > 1 {
                Picker("Board", selection: Binding(
                    get: { viewModel.selectedBoardId ?? 0 },
                    set: { viewModel.selectedBoardId = $0 }
                )) {
                    ForEach(viewModel.availableBoards, id: \.id) { board in
                        Text(board.name).tag(board.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 200)
            }

            Spacer()

            // Refresh button
            Button(action: {
                Task { await viewModel.refresh() }
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh (Cmd+R)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
