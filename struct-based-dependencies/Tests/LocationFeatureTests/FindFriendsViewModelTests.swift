import Testing
import CoreLocation
@testable import LocationFeature

@MainActor
@Suite("FindFriendsViewModel — struct-based dependency")
struct FindFriendsViewModelTests {

  @Test func deniedAuthorization_surfacesEmptyState() async {
    var client = LocationClient.testValue
    client.requestAuthorization = { .denied }
    // Intentionally not overriding startUpdates or stop —
    // if the system under test calls them, we crash and find out.

    let vm = FindFriendsViewModel(location: client)
    await vm.onAppear()

    #expect(vm.shouldShowEnableLocationEmptyState == true)
    #expect(vm.observedLocations.isEmpty)
  }

  @Test func authorized_consumesLocationsFromStream() async {
    var client = LocationClient.testValue
    client.requestAuthorization = { .authorizedAlways }
    client.startUpdates = {
      AsyncStream { continuation in
        continuation.yield(CLLocation(latitude: 1, longitude: 1))
        continuation.yield(CLLocation(latitude: 2, longitude: 2))
        continuation.yield(CLLocation(latitude: 3, longitude: 3))
        continuation.finish()
      }
    }
    // stop is still fatalError — vm doesn't call it.

    let vm = FindFriendsViewModel(location: client)
    await vm.onAppear()

    #expect(vm.observedLocations.count == 3)
    #expect(vm.shouldShowEnableLocationEmptyState == false)
  }
}
