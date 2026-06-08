import SwiftUI
import ScreenStateKit

public struct EditTeamSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewState = EditTeamSettingsState()
    @State private var store: EditTeamSettingsStore
    @State private var name = "Wanderers"
    @State private var colorHex = "#34D399"

    public init(refresher: TeamRefresher) {
        _store = State(initialValue: EditTeamSettingsStore(refresher: refresher))
    }

    public var body: some View {
        Form {
            TextField("Team name", text: $name)
            TextField("Colour hex", text: $colorHex)
            Button("Save") {
                Task {
                    try? await store
                        .nonisolatedReceive(action: .save(name: name, colorHex: colorHex))
                        .waitComplete()
                    dismiss()
                }
            }
        }
        .task { await store.binding(state: viewState) }
    }
}

#if DEBUG
#Preview("Edit settings") {
    EditTeamSettingsView(refresher: TeamRefresher())
}
#endif
