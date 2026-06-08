import Observation
import ScreenStateKit

@Observable
@MainActor
public final class EditTeamSettingsState: ScreenState, StateUpdatable {
    public var lastSavedName: String = ""
}
