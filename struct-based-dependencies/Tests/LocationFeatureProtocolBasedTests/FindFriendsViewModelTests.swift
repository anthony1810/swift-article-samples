import Testing
import CoreLocation
@testable import LocationFeatureProtocolBased

@MainActor
@Suite("FindFriendsViewModel — protocol-based dependency")
struct FindFriendsViewModelTests {

  @Test func deniedAuthorization_surfacesEmptyState() async {
    let service = MockLocationService(stubbedAuthorization: .denied)
    let vm = FindFriendsViewModel(location: service)
    await vm.onAppear()

    #expect(vm.shouldShowEnableLocationEmptyState == true)
    #expect(vm.observedLocations.isEmpty)
  }

  @Test func authorized_consumesLocationsFromStream() async {
    let service = MockLocationService(
      stubbedAuthorization: .authorizedAlways,
      stubbedLocations: [
        CLLocation(latitude: 1, longitude: 1),
        CLLocation(latitude: 2, longitude: 2),
        CLLocation(latitude: 3, longitude: 3),
      ]
    )
    let vm = FindFriendsViewModel(location: service)
    await vm.onAppear()

    #expect(vm.observedLocations.count == 3)
    #expect(vm.shouldShowEnableLocationEmptyState == false)
  }
}
