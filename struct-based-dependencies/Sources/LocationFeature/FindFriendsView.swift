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
#Preview("Happy path — previewValue (3 coords arrive 1s apart)") {
  FindFriendsView(
    viewModel: FindFriendsViewModel(location: .previewValue)
  )
}

#Preview("Denied authorization — partial override of previewValue") {
  FindFriendsView(
    viewModel: FindFriendsViewModel(
      location: {
        var c = LocationClient.previewValue
        c.requestAuthorization = { .denied }
        return c
      }()
    )
  )
}
#endif
