## Unreleased

- Fix the default 404 page's return button for apps whose initial route is not `/`.
- Keep route errors off the default 404 page outside debug builds.
- Print `DebugRouteObserver` events only in debug builds.
- Make the quick start runnable, clarify guard and tab behavior, and document
  how to run the example.
- Run analysis and tests for the package and example on every push and PR.

## 1.0.1

- Fix: trim `pubspec.yaml` description to satisfy pub.dev's 60-180 character requirement.
- Fix: broaden `go_router` constraint from `^14.0.0` to `'>=14.0.0 <18.0.0'` to support all current stable versions (14.x – 17.x).

## 1.0.0

Initial public release.

### Core

- `RouteArchitect.create` – single static factory that builds a fully-configured `GoRouter`
  with an optional guard pipeline, fallback/error-screen strategy, analytics observers,
  refresh listenable, restoration scope, and redirect limit.
- `RouteGuard` – abstract base class for a single guard step (`FutureOr<String?>`).
- `GuardPipeline.run` – Chain-of-Responsibility executor; short-circuits on the first
  non-null redirect.

### Navigation Shell

- `EnterpriseBottomNav` – production-ready bottom navigation widget for `StatefulShellRoute`
  with **double-tap-to-root** support.
- `NavigationItem` – immutable tab descriptor (label, icon, activeIcon, tooltip).
- `ShellBranchItem` – combines `NavigationItem` metadata with branch routes for fully
  declarative shell setup.
- `EnterpriseShell.buildRoute` – zero-boilerplate `StatefulShellRoute` builder from a list
  of `ShellBranchItem`s.

### Analytics

- `RouteAnalyticsObserver` – abstract `NavigatorObserver` with `onScreenView`,
  `onScreenPop`, and `onRouteError` hooks.
- `DebugRouteObserver` – dev-mode console logger (ships with the package).

### State-Management Bridge

- `ListenableNotifier` mixin – bridges Riverpod, Bloc, MobX, and any state manager to
  `GoRouter.refreshListenable`.
- `StreamListenable` – converts any `Stream` into a `Listenable`.

### Extensions

- `RouteArchitectExtensions` on `BuildContext`:
  - `architectPush<T>` – push a route and await a compile-time-safe typed return value.
  - `architectPop<T>` – pop and return a typed result to the awaiting caller.
  - `architectPushNamed<T>` – named-route variant with path/query parameters.
