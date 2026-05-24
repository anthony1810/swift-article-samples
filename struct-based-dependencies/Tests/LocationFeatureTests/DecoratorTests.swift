import Testing
import CoreLocation
import Foundation
@testable import LocationFeature

@Suite("LocationClient decorators")
struct DecoratorTests {

  @Test func logged_capturesBeforeAndAfter() async {
    let messages = SafeBox<[String]>([])

    var client = LocationClient.testValue
    client.requestAuthorization = { .authorizedAlways }
    let logged = client.logged { msg in
      messages.update { $0.append(msg) }
    }

    let status = await logged.requestAuthorization()

    #expect(status == .authorizedAlways)
    #expect(messages.value == [
      "LocationClient.requestAuthorization",
      "LocationClient.requestAuthorization → authorizedAlways"
    ])
  }

  @Test func logged_canBeChainedWithoutTouchingBaseImplementation() async {
    let messages = SafeBox<[String]>([])

    var base = LocationClient.testValue
    base.requestAuthorization = { .denied }
    let logged = base.logged { msg in messages.update { $0.append("a: " + msg) } }
    let twiceLogged = logged.logged { msg in messages.update { $0.append("b: " + msg) } }

    _ = await twiceLogged.requestAuthorization()

    #expect(messages.value.count == 4)
    #expect(messages.value.contains(where: { $0.hasPrefix("a:") }))
    #expect(messages.value.contains(where: { $0.hasPrefix("b:") }))
  }
}

final class SafeBox<Value: Sendable>: @unchecked Sendable {
  private let lock = NSLock()
  private var _value: Value
  init(_ value: Value) { self._value = value }
  var value: Value { lock.withLock { _value } }
  func update<T>(_ op: (inout Value) -> T) -> T {
    lock.withLock { op(&_value) }
  }
}
