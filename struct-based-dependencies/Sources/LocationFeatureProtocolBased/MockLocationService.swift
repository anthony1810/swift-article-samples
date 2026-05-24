import CoreLocation

public final class MockLocationService: LocationServiceProtocol, @unchecked Sendable {
  public var stubbedAuthorization: CLAuthorizationStatus = .notDetermined
  public var stubbedLocations: [CLLocation] = []

  public init(
    stubbedAuthorization: CLAuthorizationStatus = .notDetermined,
    stubbedLocations: [CLLocation] = []
  ) {
    self.stubbedAuthorization = stubbedAuthorization
    self.stubbedLocations = stubbedLocations
  }

  public func requestAuthorization() async -> CLAuthorizationStatus {
    stubbedAuthorization
  }

  public func startUpdates() -> AsyncStream<CLLocation> {
    let locations = stubbedLocations
    return AsyncStream { continuation in
      locations.forEach { continuation.yield($0) }
      continuation.finish()
    }
  }

  public func stop() {}
}
