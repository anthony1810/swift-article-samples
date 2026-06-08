import Foundation

public struct Player: Hashable, Sendable, Identifiable {
    public let id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
