import CoreLocation

extension LocationClient {
  public static let liveValue: LocationClient = {
    let manager = LiveLocationManager()
    return LocationClient(
      requestAuthorization: { await manager.requestAuthorization() },
      startUpdates: { manager.makeUpdateStream() },
      stop: { manager.stop() }
    )
  }()
}

private final class LiveLocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
  private let manager = CLLocationManager()
  private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
  private var updateContinuation: AsyncStream<CLLocation>.Continuation?

  override init() {
    super.init()
    manager.delegate = self
  }

  func requestAuthorization() async -> CLAuthorizationStatus {
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

  func makeUpdateStream() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
      self.updateContinuation = continuation
      manager.startUpdatingLocation()
      continuation.onTermination = { [weak self] _ in
        self?.manager.stopUpdatingLocation()
      }
    }
  }

  func stop() {
    manager.stopUpdatingLocation()
  }

  func locationManager(_ m: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authContinuation?.resume(returning: status)
    authContinuation = nil
  }

  func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let last = locations.last {
      updateContinuation?.yield(last)
    }
  }
}
