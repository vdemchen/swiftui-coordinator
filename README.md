# SwiftUI-Coordinator

A lightweight, protocol-based implementation of the **Coordinator pattern** for SwiftUI.
It keeps navigation state (push/pop stack, modal presentation, root switching) out of your views
and in a single `@Observable` object, built on top of `NavigationStack` and `NavigationPath`.

- One protocol, zero dependencies
- Default implementations for every navigation action — you only declare state
- Optional features: modal presentation and root switching are opt-in via associated types
- `@MainActor`-isolated and ready for Swift 6 strict concurrency

## Requirements

| Platform | Minimum |
|----------|---------|
| iOS      | 17.0    |
| macOS    | 14.0    |
| watchOS  | 11.0    |

Swift tools version 6.4 (Xcode with Swift 6.4 or later).

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies…** and enter the repository URL.

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<owner>/SwiftUI-Coordinator.git", branch: "main")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "SwiftUI-Coordinator", package: "SwiftUI-Coordinator")
        ]
    )
]
```

Then import the module:

```swift
import SwiftUI_Coordinator
```

## Overview

```swift
@MainActor public protocol Coordinator: AnyObject, Observable {
    associatedtype PathType: Hashable                    // destinations pushed on the stack
    associatedtype RootType: Hashable = Never            // optional: switchable root state
    associatedtype PresentType: Identifiable = Never     // optional: modally presented items

    var path: NavigationPath { get set }
    var presented: PresentType? { get set }
    var rootState: RootType { get set }
    var presentedQueue: [PresentType] { get set }

    func push(_ route: PathType)
    func pop()
    func popToRoot()
    func set(_ state: RootType)
    func present(_ type: PresentType)
    func dismiss()
    func presentLast()
}
```

All methods have default implementations. You only declare the stored properties for the
features you use:

| Associated type | Required stored properties | Enables |
|-----------------|----------------------------|---------|
| `PathType` (always) | `path` | `push`, `pop`, `popToRoot` |
| `PresentType` (optional) | `presented`, `presentedQueue` | `present`, `dismiss`, `presentLast` |
| `RootType` (optional) | `rootState` | `set(_:)` |

If you leave `PresentType` or `RootType` as `Never`, the corresponding properties and methods
are provided as no-op stubs, so you don't need to implement them.

### Behavior

| Method | Effect |
|--------|--------|
| `push(_:)` | Appends a route to `path`. |
| `pop()` | Removes the last route (no-op if the stack is empty). |
| `popToRoot()` | Clears the whole stack. |
| `present(_:)` | Presents an item. If something is already presented, it is moved to `presentedQueue` first. |
| `presentLast()` | Restores the most recently queued item, or clears `presented` if the queue is empty. |
| `dismiss()` | Sets `presented` to `nil` (the queue is left untouched). |
| `set(_:)` | Resets the navigation stack and switches `rootState`. |

## Usage

### 1. Push navigation only

```swift
import SwiftUI
import SwiftUI_Coordinator

enum Route: Hashable {
    case detail(id: Int)
    case settings
}

@Observable
final class AppCoordinator: Coordinator {
    typealias PathType = Route
    var path = NavigationPath()
}

struct RootView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let id): DetailView(id: id)
                    case .settings:       SettingsView()
                    }
                }
        }
        .environment(coordinator)
    }
}

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack {
            Button("Open detail") { coordinator.push(.detail(id: 42)) }
            Button("Settings")    { coordinator.push(.settings) }
        }
    }
}
```

### 2. Adding modal presentation

```swift
enum Sheet: Identifiable {
    case login
    case paywall

    var id: Self { self }
}

@Observable
final class AppCoordinator: Coordinator {
    typealias PathType = Route
    typealias PresentType = Sheet

    var path = NavigationPath()
    var presented: Sheet?
    var presentedQueue: [Sheet] = []
}

struct RootView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Route.self) { /* ... */ }
        }
        .sheet(item: $coordinator.presented, onDismiss: coordinator.presentLast) { sheet in
            switch sheet {
            case .login:   LoginView()
            case .paywall: PaywallView()
            }
        }
        .environment(coordinator)
    }
}
```

Calling `present(.paywall)` while `.login` is on screen queues `.login`; when the paywall is
dismissed, `presentLast()` (wired to `onDismiss`) brings `.login` back.

### 3. Switching the root

Use `RootType` for top-level flows such as onboarding → main app:

```swift
enum AppRoot: Hashable {
    case onboarding
    case main
}

@Observable
final class AppCoordinator: Coordinator {
    typealias PathType = Route
    typealias RootType = AppRoot

    var path = NavigationPath()
    var rootState: AppRoot = .onboarding
}

struct RootView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            switch coordinator.rootState {
            case .onboarding: OnboardingView()
            case .main:       MainView()
            }
        }
        .environment(coordinator)
    }
}

// Somewhere in OnboardingView:
coordinator.set(.main)   // clears the stack and switches the root
```

> **Note:** If `RootType` is `Never`, reading `rootState` triggers a `fatalError`. Only read it
> when your coordinator declares a `RootType`.

## Project structure

```
SwiftUI-Coordinator/
├── Package.swift
└── Sources/
    └── Coordinator/
        └── Coordinator.swift   // Coordinator protocol + default implementations
```

## License

Add a license of your choice (e.g. MIT) in a `LICENSE` file.
