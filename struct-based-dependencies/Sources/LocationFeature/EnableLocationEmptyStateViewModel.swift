import CoreLocation
import Observation

@Observable
@MainActor
public final class EnableLocationEmptyStateViewModel {
  public private(set) var lastStatus: CLAuthorizationStatus?

  private let requestAuthorization: @Sendable () async -> CLAuthorizationStatus

  public init(requestAuthorization: @Sendable @escaping () async -> CLAuthorizationStatus) {
    self.requestAuthorization = requestAuthorization
  }

  public func onCTATap() async {
    lastStatus = await requestAuthorization()
  }
}
