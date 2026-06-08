# AppRefresher: a typed refresh bus for SwiftUI

*Keep your screens in sync by broadcasting a change once — and handing the fresh object straight to whoever's listening. New in ScreenStateKit 1.3.0.*

---

## The problem

Every app hits this eventually: one screen changes data, and another screen is now showing something stale.

You edit a team's name on a settings screen. Tucked behind it in the navigation stack is a header that still shows the old name. When the user taps back, it should already be correct.

The usual fixes all have a tax:

- **Re-fetch on `onAppear`** — a network round-trip for data you *already have in hand*.
- **`NotificationCenter`** — stringly-typed names, `userInfo: [AnyHashable: Any]` you have to cast back, and `addObserver`/`removeObserver` you have to remember to balance.
- **Delegates / closures threaded through coordinators** — couples two screens that shouldn't know each other exists.

What we actually want: the screen that *made* the change should be able to say "team settings just changed — and here's the new object," and any interested screen should be able to react, **without the two ever referencing each other.**

That's `AppRefresher`.

## The idea

`AppRefresher` is a tiny, typed refresh bus that lives in the SwiftUI environment. It's generic over two types **you** define:

- **`Option`** — an `OptionSet` describing *what* changed. Receivers filter on it.
- **`Source`** — a `Sendable` enum carrying an optional **payload**. Its associated values hand the fresh object to the receiver.

```
EditTeamSettings (sender)
        │  refresh(.settings, source: .settingsUpdated(updated))
        ▼
   AppRefresher        ← one instance, hosted at the root via the environment
        │  .onAppRefresh(.settings) { source in … }
        ▼
TeamHeader (receiver)  → forwards the payload to its store → store mutates state
```

It's `@MainActor @Observable` (no Combine), and every payload is `Sendable`, so it's concurrency-safe by construction.

## The scenario

A team app. On **Screen A** the user edits the team's name and colour. **Screen B** — a header — must reflect the new values the instant they're saved, with no API refetch and no local database to re-read.

Let's wire it end to end. (Full runnable package: [`app-refresher/`](./).)

## Step 1 — Define your domain

Two types: what can change, and the payload it carries. The `Source` enum's associated values are where the fresh object travels.

```swift
import ScreenStateKit

public struct TeamRefresh: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let settings = TeamRefresh(rawValue: 1 << 0)
    public static let roster   = TeamRefresh(rawValue: 1 << 1)
}

public enum TeamSource: Sendable, Equatable {
    case settingsUpdated(TeamSettings)
    case playerJoined(Player)
}

public typealias TeamRefresher = AppRefresher<TeamRefresh, TeamSource>
```

Because `Option` is an `OptionSet`, you can broadcast combined signals (`[.settings, .roster]`) in one call. And because `Source` is a plain enum, the payload is fully typed — no casting on the other end.

## Step 2 — Create once, host at the root

Create a single `TeamRefresher` and inject it into the environment with `.appRefresherHost(_:)`. Every screen below can now send or receive.

```swift
import SwiftUI
import ScreenStateKit

public struct TeamSyncRootView: View {
    @State private var refresher = TeamRefresher()

    public var body: some View {
        NavigationStack {
            List {
                Section("Receiver — reacts to the bus") {
                    TeamHeaderView()
                }
                Section {
                    NavigationLink("Open Edit Settings (sender)") {
                        EditTeamSettingsView(refresher: refresher)
                    }
                }
            }
        }
        .appRefresherHost(refresher)
    }
}
```

## Step 3 — Broadcast on Screen A

The sender is a ScreenStateKit store. After it saves, it fires the option **and** the brand-new object:

```swift
public actor EditTeamSettingsStore: ScreenActionStore {
    private let refresher: TeamRefresher

    public init(refresher: TeamRefresher) { self.refresher = refresher }

    public func receive(action: Action) async throws {
        switch action {
        case let .save(name, colorHex):
            let updated = TeamSettings(id: "team-1", name: name, colorHex: colorHex)
            await refresher.refresh(.settings, source: .settingsUpdated(updated))
        }
    }

    public enum Action: ActionLockable, LoadingTrackable, Hashable {
        case save(name: String, colorHex: String)
        public var canTrackLoading: Bool { true }
    }
}
```

That's the whole "publish" side: `refresher.refresh(.settings, source: .settingsUpdated(updated))`.

## Step 4 — React on Screen B

The receiver listens with `.onAppRefresh(_:)`. It pattern-matches the payload and — importantly — **forwards it to its store as an action**. In ScreenStateKit all mutations go through the store; the view never touches `viewState` directly.

```swift
public struct TeamHeaderView: View {
    @State private var viewState = TeamHeaderState()
    @State private var store = TeamHeaderStore()

    public var body: some View {
        HStack {
            Circle().fill(Color(hex: viewState.colorHex)).frame(width: 28, height: 28)
            Text(viewState.name).font(.headline)
        }
        .task { await store.binding(state: viewState) }
        .onAppRefresh(TeamRefresh.settings) { (source: TeamSource?) in
            guard case let .settingsUpdated(settings) = source else { return }
            store.nonisolatedReceive(action: .applySettings(settings))
        }
    }
}
```

And the store applies it — straight from the payload, **zero refetch**:

```swift
public actor TeamHeaderStore: ScreenActionStore {
    public private(set) var viewState: TeamHeaderState?

    public func receive(action: Action) async throws {
        switch action {
        case let .applySettings(settings):
            await viewState?.updateState {
                $0.name = settings.name
                $0.colorHex = settings.colorHex
            }
        }
    }

    public enum Action: ActionLockable, LoadingTrackable, Hashable {
        case applySettings(TeamSettings)
        public var canTrackLoading: Bool { false }
    }
}
```

> **Spell the option type at the call site** (`TeamRefresh.settings`, not `.settings`). A chained view modifier gives the compiler no contextual type to infer the generic `Option` from. Annotate the closure's `Source?` for the same reason.

## A detail worth knowing: delivery timing

`onAppRefresh` takes a `behavior`:

- **`.onNextAppear`** (default) — if the screen is hidden (behind a pushed view), the signal is *stored* and runs on the screen's next `onAppear`. No point reloading a list nobody is looking at.
- **`.immediate`** — runs the instant the signal fires, even off-screen, when freshness can't wait.

In our scenario the header sits *under* the edit screen in the nav stack, so `.onNextAppear` is exactly right: it applies the new settings the moment the user pops back.

One more subtlety: every emission carries a unique `id`, so firing the **same** option twice in a row still triggers the receiver both times — something a naive `@Published` value would coalesce away.

## Why it's nice

- **Type-safe** — no notification strings, no `userInfo` casting. `Source` is an enum you `switch` on exhaustively.
- **Payload included** — the receiver applies the object straight from the signal, skipping a refetch or DB read.
- **Auto lifecycle** — SwiftUI subscribes/unsubscribes with the view. No `addObserver`/`removeObserver`, no leaks, no `[weak self]` dance.
- **Concurrency-safe** — `@MainActor @Observable`, payloads are `Sendable`; zero Combine.
- **Mutations stay in the store** — the view forwards an action; the store owns the state change.

## Try it

```swift
// Package.swift
.package(url: "https://github.com/anthony1810/ScreenStateKit.git", from: "1.3.0")
```

The complete, tested sample lives in [`app-refresher/`](./). Run the flow:

```sh
swift test
```

…or open it in Xcode (`xed .`) and drive the `#Preview` blocks: edit the name and colour, pop back, and watch the header update from the payload — no network in sight.

---

*`AppRefresher` ships in ScreenStateKit 1.3.0. ⭐️ [github.com/anthony1810/ScreenStateKit](https://github.com/anthony1810/ScreenStateKit)*
