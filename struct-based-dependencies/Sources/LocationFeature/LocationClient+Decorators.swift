import CoreLocation
import Foundation

extension LocationClient {
  public func logged(_ log: @escaping @Sendable (String) -> Void) -> LocationClient {
    var copy = self
    let originalRequest = copy.requestAuthorization
    copy.requestAuthorization = {
      log("LocationClient.requestAuthorization")
      let result = await originalRequest()
      log("LocationClient.requestAuthorization → \(result.label)")
      return result
    }
    return copy
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
