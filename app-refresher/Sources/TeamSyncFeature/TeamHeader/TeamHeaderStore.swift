import ScreenStateKit

public actor TeamHeaderStore: ScreenActionStore {
    public private(set) var viewState: TeamHeaderState?
    private let actionLocker = ActionLocker.nonIsolated

    public init() {}

    public func binding(state: TeamHeaderState) {
        self.viewState = state
    }

    public func receive(action: Action) async throws {
 
        guard actionLocker.canExecute(action) else { return }
        defer { actionLocker.unlock(action) }
        
        switch action {
        case let .applySettings(settings):
            await viewState?.updateState {
                $0.name = settings.name
                $0.colorHex = settings.colorHex
            }
        }
    }

    public enum Action: ActionLockable, LoadingTrackable, Hashable {
        case applySettings(TeamSettings)
        public var canTrackLoading: Bool { false }
    }
}
