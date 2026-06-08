import Observation
import ScreenStateKit

@Observable
@MainActor
public final class TeamHeaderState: ScreenState, StateUpdatable {
    public var name: String = "—"
    public var colorHex: String = "#888888"
}
