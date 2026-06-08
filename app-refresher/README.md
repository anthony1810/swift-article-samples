# AppRefresher: keep screens in sync with a typed refresh bus

[![Tests](https://github.com/anthony1810/swift-article-samples/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/anthony1810/swift-article-samples/actions/workflows/test.yml)

Companion code for [*Move away from NotificationCenter with AppRefresher — a SwiftUI-native sender*](https://medium.com/@qquang269/move-away-from-notificationcenter-with-apprefresher-a-swiftui-native-sender-8184bd5b95e7).

One screen changes data; another must reflect it instantly. The usual fixes — `NotificationCenter` strings, delegate wiring — couple screens that shouldn't know about each other. `AppRefresher` is a tiny, type-safe bus on the SwiftUI environment: broadcast a change from anywhere, react anywhere, and hand the **fresh object** straight to the listener.

This sample wires the whole flow end to end with the ScreenStateKit Three Pillars (State + Store + View).

## The scenario

A team app. On **Screen A** the user edits the team name & colour. **Screen B** (a header) must show the new values at once — with no API refetch and no local DB.

```
EditTeamSettings (sender)
        │  refresh(.settings, source: .settingsUpdated(updated))
        ▼
   AppRefresher  ← one instance, hosted at the root via the environment
        │  .onAppRefresh(.settings) { source in … }
        ▼
TeamHeader (receiver) → forwards the payload to its store → store mutates state
```

## What it shows

| Capability | Where |
|---|---|
| Define your own `Option` (OptionSet) + `Source` (payload enum) | [`Refresh/TeamRefresh.swift`](./Sources/TeamSyncFeature/Refresh/TeamRefresh.swift) |
| Broadcast an option **plus the fresh object** | [`EditTeamSettings/EditTeamSettingsStore.swift`](./Sources/TeamSyncFeature/EditTeamSettings/EditTeamSettingsStore.swift) — `refresher.refresh(.settings, source: .settingsUpdated(updated))` |
| React, and route the payload through the **store** (never `viewState`) | [`TeamHeader/TeamHeaderView.swift`](./Sources/TeamSyncFeature/TeamHeader/TeamHeaderView.swift) — `.onAppRefresh(...) { store.nonisolatedReceive(action: .applySettings(s)) }` |
| Host one shared instance at the root | [`App/TeamSyncRootView.swift`](./Sources/TeamSyncFeature/App/TeamSyncRootView.swift) — `.appRefresherHost(refresher)` |

## Layout

```
app-refresher/
├── Package.swift                              Depends on ScreenStateKit 1.3.1
├── Sources/TeamSyncFeature/
│   ├── Domain/                                Sendable models
│   │   ├── TeamSettings.swift
│   │   └── Player.swift
│   ├── Refresh/
│   │   └── TeamRefresh.swift                  Option + Source + typealias TeamRefresher
│   ├── EditTeamSettings/                      the SENDER (Three Pillars)
│   │   ├── EditTeamSettingsState.swift
│   │   ├── EditTeamSettingsStore.swift        broadcasts on save
│   │   └── EditTeamSettingsView.swift
│   ├── TeamHeader/                            the RECEIVER (Three Pillars)
│   │   ├── TeamHeaderState.swift
│   │   ├── TeamHeaderStore.swift              applies the payload
│   │   └── TeamHeaderView.swift               .onAppRefresh → store action
│   ├── Support/
│   │   └── Color+Hex.swift
│   └── App/
│       └── TeamSyncRootView.swift             Hosts the bus, composes both screens (+ #Preview)
└── Tests/TeamSyncFeatureTests/
    ├── RefreshFlowTests.swift                 Payload carried, option filtering, unique id
    └── TeamSyncStoreTests.swift               Store applies payload; saving broadcasts
```

## Why it's nice

- **Type-safe** — no notification strings, no `userInfo` casting; `Source` is an enum you `switch` on.
- **Payload included** — the receiver applies the object straight from the signal, skipping a refetch/DB read.
- **Auto lifecycle** — SwiftUI subscribes/unsubscribes with the view; no `addObserver`/`removeObserver`, no leaks.
- **Concurrency-safe** — `AppRefresher` is `@MainActor @Observable` and every payload is `Sendable`; zero Combine.
- **Mutations stay in the store** — the View forwards an action; the Store owns the state change.

## Running

```sh
swift test
```

Resolves ScreenStateKit 1.3.1 from SPM, builds, and runs the flow tests. Open in Xcode (`xed .`) to drive the `#Preview` blocks: edit the name/colour on the sender, pop back, and watch the header update from the payload.
