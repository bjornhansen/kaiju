import SwiftUI

/// Inline toolbar that runs above the board. Replaces the system window
/// toolbar to match the Vibrancy variation's hidden-title-bar layout.
struct BoardToolbar: View {
    @Bindable var viewModel: BoardViewModel
    @Binding var filterText: String
    var onSearchToggle: () -> Void
    var onCreateIssue: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            titleBlock

            Spacer(minLength: 8)

            filterField

            commandPill

            refreshButton

            newButton
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 12)
    }

    // MARK: - Title block

    @ViewBuilder
    private var titleBlock: some View {
        HStack(spacing: 8) {
            if !viewModel.boardName.isEmpty {
                Text(viewModel.boardName)
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
            } else {
                Text("Board")
                    .font(.system(size: 17, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(.tertiary)
            }

            if let projectKey = viewModel.availableBoards.first?.projectKey {
                Text("· \(projectKey)")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }

            if viewModel.availableBoards.count > 1 {
                boardPicker
            }
        }
    }

    private var boardPicker: some View {
        Picker("Board", selection: Binding(
            get: { viewModel.selectedBoardId ?? 0 },
            set: { viewModel.selectedBoardId = $0 }
        )) {
            ForEach(viewModel.availableBoards, id: \.id) { board in
                Text(board.name).tag(board.id)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .controlSize(.small)
    }

    // MARK: - Filter field

    private var filterField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            TextField("Filter issues…", text: $filterText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .frame(minWidth: 200)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Command (⌘K) pill

    private var commandPill: some View {
        Button(action: onSearchToggle) {
            HStack(spacing: 3) {
                Image(systemName: "command")
                    .font(.system(size: 10, weight: .medium))
                Text("K")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Search (⌘K)")
    }

    // MARK: - Refresh

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help("Refresh (⌘R)")
    }

    // MARK: - New

    private var newButton: some View {
        Button(action: onCreateIssue) {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("New")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(VibrancyTokens.accent)
            )
            .shadow(color: VibrancyTokens.accent.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .help("New Issue (⌘N)")
    }
}
