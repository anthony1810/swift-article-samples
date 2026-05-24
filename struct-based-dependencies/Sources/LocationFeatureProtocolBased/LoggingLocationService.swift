import CoreLocation

public final class LoggingLocationService: LocationServiceProtocol, @unchecked Sendable {
  private let wrapped: LocationServiceProtocol
  private let log: @Sendable (String) -> Void

  public init(wrapping wrapped: LocationServiceProtocol, log: @escaping @Sendable (String) -> Void) {
    self.wrapped = wrapped
    self.log = log
  }

  public func requestAuthorization() async -> CLAuthorizationStatus {
    log("LocationService.requestAuthorization")
    let result = await wrapped.requestAuthorization()
    log("LocationService.requestAuthorization → \(result.label)")
    return result
  }

  public func startUpdates() -> AsyncStream<CLLocation> {
    wrapped.startUpdates()
  }

  public func stop() {
    wrapped.stop()
  }
}

extension CLAuthorizationStatus {
  fileprivate var label: String {
    switch self {
    case .notDetermined: "notDetermined"
    case .restricted: "restricted"
    case .denied: "denied"
    case .authorizedAlways: "authorizedAlways"
    case .authorizedWhenInUse: "authorizedWhenInUse"
    @unknown default: "unknown(\(rawValue))"
    }
  }
}
