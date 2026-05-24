import CoreLocation

public final class LiveLocationService: NSObject, LocationServiceProtocol, CLLocationManagerDelegate, @unchecked Sendable {
  private let manager = CLLocationManager()
  private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
  private var updateContinuation: AsyncStream<CLLocation>.Continuation?

  public override init() {
    super.init()
    manager.delegate = self
  }

  public func requestAuthorization() async -> CLAuthorizationStatus {
    if manager.authorizationStatus != .notDetermined {
      return manager.authorizationStatus
    }
    return await withCheckedContinuation { continuation in
      self.authContinuation = continuation
      #if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
      manager.requestWhenInUseAuthorization()
      #elseif os(macOS)
      manager.requestAlwaysAuthorization()
      #endif
    }
  }

  public func startUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
      self.updateContinuation = continuation
      manager.startUpdatingLocation()
      continuation.onTermination = { [weak self] _ in
        self?.manager.stopUpdatingLocation()
      }
    }
  }

  public func stop() {
    manager.stopUpdatingLocation()
  }

  public func locationManager(_ m: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authContinuation?.resume(returning: status)
    authContinuation = nil
  }

  public func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let last = locations.last {
      updateContinuation?.yield(last)
    }
  }
}
