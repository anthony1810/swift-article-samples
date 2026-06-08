import SwiftUI
import ScreenStateKit

public struct TeamSyncRootView: View {
    @State private var refresher = TeamRefresher()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Receiver — reacts to the bus") {
                    TeamHeaderView()
                }
                Section {
                    NavigationLink("Open Edit Settings (sender)") {
                        EditTeamSettingsView(refresher: refresher)
                            .navigationTitle("Edit Settings")
                    }
                }
            }
            .navigationTitle("Team")
        }
        .appRefresherHost(refresher)
    }
}

#if DEBUG
#Preview("Team sync") {
    TeamSyncRootView()
}
#endif
