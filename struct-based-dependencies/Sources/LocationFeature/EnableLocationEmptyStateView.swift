import SwiftUI
import CoreLocation

public struct EnableLocationEmptyStateView: View {
  @State private var viewModel: EnableLocationEmptyStateViewModel

  public init(viewModel: EnableLocationEmptyStateViewModel) {
    self.viewModel = viewModel
  }

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "location.slash.circle")
        .font(.system(size: 56))
        .foregroundStyle(.secondary)
      Text("Find friends near you")
        .font(.headline)
      Text("Turn on location to discover who's around.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button {
        Task { await viewModel.onCTATap() }
      } label: {
        Text("Enable location")
          .padding(.horizontal, 24)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
      if let status = viewModel.lastStatus {
        Text("status: \(String(describing: status))")
          .font(.footnote)
          .foregroundStyle(.tertiary)
      }
    }
    .padding()
  }
}

#if DEBUG
// Note the per-endpoint injection: this preview only constructs ONE closure
// (`requestAuthorization`). There's no `LocationClient` here, no protocol,
// no full service to mock. The view model's dependency is exactly one
// function and that's all the preview has to provide.

#Preview("CTA — grants authorization") {
  EnableLocationEmptyStateView(
    viewModel: EnableLocationEmptyStateViewModel(
      requestAuthorization: { .authorizedAlways }
    )
  )
}

#Preview("CTA — user denies") {
  EnableLocationEmptyStateView(
    viewModel: EnableLocationEmptyStateViewModel(
      requestAuthorization: { .denied }
    )
  )
}
#endif
