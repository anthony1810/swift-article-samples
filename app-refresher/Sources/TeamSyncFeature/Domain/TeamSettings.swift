import Foundation

public struct TeamSettings: Hashable, Sendable, Identifiable {
    public let id: String
    public var name: String
    public var colorHex: String

    public init(id: String, name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}
