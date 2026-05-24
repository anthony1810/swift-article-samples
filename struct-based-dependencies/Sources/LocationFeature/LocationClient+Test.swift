import CoreLocation

extension LocationClient {
  public static let testValue = LocationClient(
    requestAuthorization: {
      fatalError("LocationClient.requestAuthorization — unimplemented")
    },
    startUpdates: {
      fatalError("LocationClient.startUpdates — unimplemented")
    },
    stop: {
      fatalError("LocationClient.stop — unimplemented")
    }
  )
}
