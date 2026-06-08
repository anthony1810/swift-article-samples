import ScreenStateKit

public struct TeamRefresh: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let settings = TeamRefresh(rawValue: 1 << 0)
    public static let roster   = TeamRefresh(rawValue: 1 << 1)
}

public enum TeamSource: Sendable, Equatable {
    case settingsUpdated(TeamSettings)
    case playerJoined(Player)
}

public typealias TeamRefresher = AppRefresher<TeamRefresh, TeamSource>
