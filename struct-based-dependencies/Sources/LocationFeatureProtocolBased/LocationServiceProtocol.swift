import CoreLocation

public protocol LocationServiceProtocol: Sendable {
  func requestAuthorization() async -> CLAuthorizationStatus
  func startUpdates() -> AsyncStream<CLLocation>
  func stop()
}
