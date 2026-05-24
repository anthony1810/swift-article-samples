# Dependency design: struct-based vs protocol-based

Companion code for *Dependency design: where struct-based wins over protocol-based*.

Two parallel implementations of the same toy feature (a `LocationService` consumed by a `FindFriendsViewModel`), so you can see the line-by-line difference and run the tests side by side.

## Layout

```
struct-based-dependencies/
├── Package.swift                                    Two libraries, two test targets
├── Sources/
│   ├── LocationFeature/                             ← struct-based (recommended)
│   │   ├── LocationClient.swift                     The struct-of-closures definition
│   │   ├── LocationClient+Live.swift                liveValue wrapping CoreLocation
│   │   ├── LocationClient+Preview.swift             previewValue simulating coordinates
│   │   ├── LocationClient+Test.swift                testValue with fatalError closures
│   │   ├── LocationClient+Decorators.swift          .logged() as a value transformation
│   │   ├── FindFriendsViewModel.swift               Consumer taking the whole client
│   │   └── EnableLocationEmptyStateViewModel.swift  Consumer taking ONE closure
│   └── LocationFeatureProtocolBased/                ← protocol-based (the conventional way)
│       ├── LocationServiceProtocol.swift            The protocol
│       ├── LiveLocationService.swift                Real CoreLocation conformance
│       ├── MockLocationService.swift                Hand-rolled mock
│       ├── LoggingLocationService.swift             Decorator wrapper class
│       └── FindFriendsViewModel.swift               Consumer typed against the protocol
└── Tests/
    ├── LocationFeatureTests/                        Tests using testValue + per-field override
    │   ├── FindFriendsViewModelTests.swift
    │   └── DecoratorTests.swift
    └── LocationFeatureProtocolBasedTests/           Tests using the hand-rolled mock
        └── FindFriendsViewModelTests.swift
```

## What to compare

| Aspect | Protocol-based | Struct-based |
|---|---|---|
| Files needed for the same interface + 3 implementations | 5 (protocol, live, mock, logging, vm) | 5 (struct, live, preview, test, vm) — same count, but… |
| Adding a logging decorator | A new class with forwarding stubs for every protocol method | A single function `.logged()` returning a `LocationClient` |
| Composing decorators (logging + retrying + metrics) | Nested constructors: `Logging(wrapping: Retrying(wrapping: Metrics(wrapping: Live())))` | Method chain: `.liveValue.logged().retrying().metricsed()` |
| Test mock for "denied authorization only" | A `MockLocationService` that implements all 3 methods, with `startUpdates` and `stop` doing nothing | `testValue` with the one closure overridden; the other two stay as `fatalError` |
| What happens when test scope grows | Mock silently passes through new code paths | Test crashes with "X — unimplemented", flagging the new dependency |
| Depending on just one method (e.g. `EnableLocationEmptyStateViewModel`) | Must take the whole `LocationServiceProtocol` | Takes a single `@Sendable () async -> CLAuthorizationStatus` closure |

## Running

```sh
swift test
```

Both targets build and test. No external dependencies. Pure SPM + CoreLocation.

## What's NOT in here

A dependency injection framework. Init injection covers all uses. If you want `@Dependency` / `withDependencies` ergonomics, see [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies) — this sample shows the pattern can live without the library too.
