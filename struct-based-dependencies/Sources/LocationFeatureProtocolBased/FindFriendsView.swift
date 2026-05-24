import SwiftUI
import CoreLocation

public struct FindFriendsView: View {
  @State private var viewModel: FindFriendsViewModel

  public init(viewModel: FindFriendsViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    Group {
      if viewModel.shouldShowEnableLocationEmptyState {
        ContentUnavailableView(
          "Location off",
          systemImage: "location.slash",
          description: Text("Turn on location to find friends near you.")
        )
      } else if viewModel.observedLocations.isEmpty {
        ProgressView("Finding your location…")
      } else {
        List(viewModel.observedLocations.indices, id: \.self) { idx in
          let loc = viewModel.observedLocations[idx]
          HStack {
            Image(systemName: "mappin.and.ellipse")
              .foregroundStyle(.tint)
            Text(String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude))
              .monospaced()
          }
        }
      }
    }
    .task { await viewModel.onAppear() }
  }
}

#if DEBUG
// Compare with LocationFeature/FindFriendsView.swift:
// • The struct-based preview uses `.previewValue` + per-field override.
// • This one constructs a full MockLocationService for each scenario,
//   because that's the smallest unit a `LocationServiceProtocol`-typed
//   dependency can take.

#Preview("Happy path — mock service") {
  FindFriendsView(
    viewModel: FindFriendsViewModel(
      location: MockLocationService(
        stubbedAuthorization: .authorizedAlways,
        stubbedLocations: [
          CLLocation(latitude: 37.7749, longitude: -122.4194),
          CLLocation(latitude: 37.7849, longitude: -122.4094),
          CLLocation(latitude: 37.7949, longitude: -122.3994),
        ]
      )
    )
  )
}

#Preview("Denied authorization") {
  FindFriendsView(
    viewModel: FindFriendsViewModel(
      location: MockLocationService(stubbedAuthorization: .denied)
    )
  )
}
#endif
