import SwiftUI
import ScreenStateKit

public struct TeamHeaderView: View {
    @State private var viewState = TeamHeaderState()
    @State private var store = TeamHeaderStore()

    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: viewState.colorHex))
                .frame(width: 28, height: 28)
            Text(viewState.name).font(.headline)
            Spacer()
        }
        .task { await store.binding(state: viewState) }
        .onAppRefresh(TeamRefresh.settings) { (source: TeamSource?) in
            guard case let .settingsUpdated(settings) = source else { return }
            store.nonisolatedReceive(action: .applySettings(settings))
        }
    }
}

#if DEBUG
#Preview("Header") {
    TeamHeaderView().padding()
}
#endif
