import Testing
import ScreenStateKit
@testable import TeamSyncFeature

@MainActor
@Suite("Stores")
struct TeamSyncStoreTests {

    @Test("header store applies the settings payload to its state")
    func test_header_appliesPayload() async throws {
        let state = TeamHeaderState()
        let store = TeamHeaderStore()
        await store.binding(state: state)

        try await store.receive(action: .applySettings(
            TeamSettings(id: "team-1", name: "Strikers", colorHex: "#22D3EE")
        ))

        #expect(state.name == "Strikers")
        #expect(state.colorHex == "#22D3EE")
    }

    @Test("saving on the edit store broadcasts the updated settings")
    func test_edit_broadcastsOnSave() async throws {
        let refresher = TeamRefresher()
        let store = EditTeamSettingsStore(refresher: refresher)

        try await store.receive(action: .save(name: "Strikers", colorHex: "#22D3EE"))

        #expect(refresher.action?.option == TeamRefresh.settings)
        if case let .settingsUpdated(settings) = refresher.action?.source {
            #expect(settings.name == "Strikers")
            #expect(settings.colorHex == "#22D3EE")
        } else {
            Issue.record("expected a .settingsUpdated source")
        }
    }
}
