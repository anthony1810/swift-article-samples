import ScreenStateKit

public actor EditTeamSettingsStore: ScreenActionStore {
    public private(set) var viewState: EditTeamSettingsState?
    private let refresher: TeamRefresher
    private let actionLocker = ActionLocker.nonIsolated

    public init(refresher: TeamRefresher) {
        self.refresher = refresher
    }

    public func binding(state: EditTeamSettingsState) {
        self.viewState = state
    }

    public func receive(action: Action) async throws {
        guard actionLocker.canExecute(action) else { return }
        defer { actionLocker.unlock(action) }

        switch action {
        case let .save(name, colorHex):
            let updated = TeamSettings(id: "team-1", name: name, colorHex: colorHex)
            await refresher.refresh(.settings, source: .settingsUpdated(updated))
            await viewState?.updateState { $0.lastSavedName = name }
        }
    }

    public enum Action: ActionLockable, LoadingTrackable, Hashable {
        case save(name: String, colorHex: String)
        public var canTrackLoading: Bool { true }
    }
}
