import Testing
import ScreenStateKit
@testable import TeamSyncFeature

@MainActor
@Suite("AppRefresher flow")
struct RefreshFlowTests {

    private let sample = TeamSettings(id: "team-1", name: "Wanderers", colorHex: "#34D399")

    @Test("refresh carries the option and the payload object")
    func test_refresh_carriesPayload() {
        let refresher = TeamRefresher()

        refresher.refresh(.settings, source: .settingsUpdated(sample))

        #expect(refresher.action?.option == TeamRefresh.settings)
        #expect(refresher.action?.source == TeamSource.settingsUpdated(sample))
    }

    @Test("an observer on .settings ignores a .roster-only signal")
    func test_optionFiltering() {
        let refresher = TeamRefresher()

        refresher.refresh(.roster, source: .playerJoined(Player(id: "p1", name: "Kim")))

        let matchesSettings = refresher.action?.option.isSuperset(of: .settings) ?? false
        #expect(matchesSettings == false)
    }

    @Test("each refresh gets a unique id")
    func test_uniqueId() {
        let refresher = TeamRefresher()

        refresher.refresh(.settings, source: .settingsUpdated(sample))
        let first = refresher.action?.id
        refresher.refresh(.settings, source: .settingsUpdated(sample))

        #expect(first != nil)
        #expect(first != refresher.action?.id)
    }
}
