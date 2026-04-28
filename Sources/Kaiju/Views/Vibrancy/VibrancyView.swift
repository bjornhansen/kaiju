import SwiftUI

/// Root view for the Translucent Vibrancy variation — a NavigationSplitView
/// with a translucent inset sidebar and a board pane on top of a radial-gradient
/// wallpaper that extends through the whole window via `.containerBackground`.
struct VibrancyView: View {
    @State private var selectedNav: VibrancyNavItem = .board
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationSplitView {
            VibrancySidebarView(selectedNav: $selectedNav)
                .navigationSplitViewColumnWidth(min: 220, ideal: 232, max: 260)
                .toolbar(removing: .sidebarToggle)
                .scrollContentBackground(.hidden)
        } detail: {
            VibrancyBoardView()
                .scrollContentBackground(.hidden)
        }
        .navigationSplitViewStyle(.balanced)
        .containerBackground(for: .window) {
            VibrancyTokens.wallpaper(for: colorScheme)
        }
    }
}

#Preview("Vibrancy — Light") {
    VibrancyView()
        .frame(width: 1200, height: 760)
        .preferredColorScheme(.light)
}

#Preview("Vibrancy — Dark") {
    VibrancyView()
        .frame(width: 1200, height: 760)
        .preferredColorScheme(.dark)
}
