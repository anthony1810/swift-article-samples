# AppRefresher: a SwiftUI-native sender — move on from NotificationCenter

*You want to tell a distant view that a piece of data just changed — immediately, with a typed payload, and with fine-grained control over exactly who reacts — without cluttering your code with NotificationCenter. New in ScreenStateKit 1.3.0.*

---

## The problem

You need to inform a *distant* view that a piece of data just changed — right now, not on its next fetch. And you want control: **which** screens hear it, **when** they react, and **what** data rides along.

Take a concrete case: you edit a team's name on a settings screen. Tucked behind it in the navigation stack is a header still showing the old name. When the user taps back, it should already be correct.

`NotificationCenter` can do this — but it makes you pay:

- **Stringly-typed names** — a typo compiles fine and silently never fires.
- **`userInfo: [AnyHashable: Any]`** — you box the payload and cast it back by hand on the other side.
- **Manual lifecycle** — `addObserver` / `removeObserver` you have to remember to balance.
- **No real targeting** — every observer of a name wakes up; "when and who" is left to you.

The other fallbacks aren't free either: re-fetching on `onAppear` is a network round-trip for data you *already hold*, and threading delegates through coordinators couples two screens that shouldn't know each other exists.

What you actually want: the screen that *made* the change says "team settings just changed — here's the new object," and any interested screen reacts — **without the two ever referencing each other**, and written natively for SwiftUI.

That's `AppRefresher` — another tool from ScreenStateKit, new in v1.3.0.

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

## Three steps to implement

**1 — Define what changes + the payload.** An `OptionSet` for *what*, an enum for the object that rides along:

```swift
struct TeamRefresh: OptionSet, Sendable {
    let rawValue: Int
    static let settings = TeamRefresh(rawValue: 1 << 0)
}

enum TeamSource: Sendable {
    case settingsUpdated(TeamSettings)        // the payload travels here
}

typealias TeamRefresher = AppRefresher<TeamRefresh, TeamSource>
```

**2 — Broadcast from the sender.** Host one instance at the root, then fire the option + the fresh object:

```swift
RootView().appRefresherHost(refresher)        // once, near the root

refresher.refresh(.settings, source: .settingsUpdated(updated))
```

**3 — React on the receiver.** Filter by option, read the payload, forward it to your store:

```swift
.onAppRefresh(TeamRefresh.settings) { (source: TeamSource?) in
    guard case let .settingsUpdated(settings) = source else { return }
    store.nonisolatedReceive(action: .applySettings(settings))
}
```

That's the whole loop: **define → broadcast → react.**

## The keys to getting it right

A few details make or break it:

- **Host once.** `appRefresherHost(_:)` injects a single shared instance — the sender and every receiver share that one.
- **Mark your `ScreenState` subclass `@Observable`.** The macro only instruments the class it's attached to; a subclass's *own* properties won't trigger SwiftUI re-renders unless the subclass is `@Observable` too. (Silent trap: the model updates, the view doesn't.)
- **Mutations go through the store, never `viewState`.** The view forwards an action; the store owns the change.
- **Spell the option type at the call site** (`TeamRefresh.settings`) and annotate the closure's `Source?` — a chained modifier gives the compiler nothing to infer the generics from.
- **Pick the timing.** `.onNextAppear` (default) defers until a hidden screen reappears — perfect for push/pop, so dismiss the sender after saving and the receiver applies the change as it comes back. `.immediate` runs right away, even off-screen. Every emission carries a unique id, so firing the same option twice still delivers both times.

## See the full example

A complete, tested package — sender, receiver, the ScreenStateKit Three Pillars, and `#Preview`s you can drive — lives here:

> 📦 **[github.com/anthony1810/swift-article-samples → `app-refresher/`](https://github.com/anthony1810/swift-article-samples/tree/main/app-refresher)**

```sh
swift test     # runs the flow; open in Xcode (xed .) to drive the previews
```

Tap Save on the edit screen, pop back, and watch the header update straight from the payload — no network in sight.

## Why this is better

Next to reaching for `NotificationCenter`:

- **Type-safe end to end** — no notification strings, no `userInfo` casting; `Source` is an enum you `switch` on.
- **Payload included** — the receiver applies the fresh object straight from the signal, skipping a refetch or DB read.
- **Auto lifecycle** — SwiftUI subscribes/unsubscribes with the view; no `addObserver`/`removeObserver`, no leaks.
- **Real targeting** — receivers filter by option and choose their own timing; you control *when, where, and who*.
- **Concurrency-safe, SwiftUI-native** — `@MainActor @Observable`, `Sendable` payloads, zero Combine; mutations stay in the store.

You wanted to tell a distant view about a change — immediately, precisely, and without the NotificationCenter tax. That's exactly what AppRefresher gives you.

---

*AppRefresher ships in ScreenStateKit 1.3.0. ⭐️ [github.com/anthony1810/ScreenStateKit](https://github.com/anthony1810/ScreenStateKit)*
