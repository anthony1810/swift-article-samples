import CoreLocation

extension LocationClient {
  public static let previewValue = LocationClient(
    requestAuthorization: { .authorizedAlways },
    startUpdates: {
      AsyncStream { continuation in
        Task {
          let coordinates: [(Double, Double)] = [
            (37.7749, -122.4194),
            (37.7849, -122.4094),
            (37.7949, -122.3994)
          ]
          for (lat, lng) in coordinates {
            try? await Task.sleep(for: .seconds(1))
            continuation.yield(CLLocation(latitude: lat, longitude: lng))
          }
          continuation.finish()
        }
      }
    },
    stop: {}
  )
}
