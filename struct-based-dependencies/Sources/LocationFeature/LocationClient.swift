import CoreLocation

public struct LocationClient: Sendable {
  public var requestAuthorization: @Sendable () async -> CLAuthorizationStatus
  public var startUpdates: @Sendable () -> AsyncStream<CLLocation>
  public var stop: @Sendable () -> Void

  public init(
    requestAuthorization: @Sendable @escaping () async -> CLAuthorizationStatus,
    startUpdates: @Sendable @escaping () -> AsyncStream<CLLocation>,
    stop: @Sendable @escaping () -> Void
  ) {
    self.requestAuthorization = requestAuthorization
    self.startUpdates = startUpdates
    self.stop = stop
  }
}
