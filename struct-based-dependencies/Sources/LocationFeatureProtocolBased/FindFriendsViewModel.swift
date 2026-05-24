import CoreLocation
import Observation

@Observable
@MainActor
public final class FindFriendsViewModel {
  public private(set) var observedLocations: [CLLocation] = []
  public private(set) var shouldShowEnableLocationEmptyState = false

  private let location: LocationServiceProtocol

  public init(location: LocationServiceProtocol) {
    self.location = location
  }

  public func onAppear() async {
    let status = await location.requestAuthorization()
    guard status == .authorizedAlways else {
      shouldShowEnableLocationEmptyState = true
      return
    }
    for await coord in location.startUpdates() {
      observedLocations.append(coord)
    }
  }
}
