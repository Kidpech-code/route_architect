# route_architect

[![pub version](https://img.shields.io/pub/v/route_architect.svg)](https://pub.dev/packages/route_architect)
[![pub points](https://img.shields.io/pub/points/route_architect)](https://pub.dev/packages/route_architect/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Enterprise-grade Flutter routing built on [`go_router`](https://pub.dev/packages/go_router).**

`route_architect` wraps `go_router` in a clean, declarative API designed for
production apps. You get an async guard pipeline, deep-link safety, a
stateful bottom-nav shell with double-tap-to-root, analytics observers, and
state-management bridges — all without writing a single line of `go_router`
boilerplate.

---

## Features

| Feature                             | Description                                                                                                                                       |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Async Guard Pipeline**            | Chain-of-Responsibility guards (`FutureOr<String?>`) — authenticate, role-check, gate features, all in one pipeline.                              |
| **Deep-Link Safety**                | Broken deep links are intercepted and silently redirected or shown a polished built-in 404 screen.                                                |
| **EnterpriseBottomNav**             | Plug-and-play `StatefulShellRoute` shell with **double-tap-to-root** out of the box.                                                              |
| **Analytics Observers**             | Abstract `RouteAnalyticsObserver` — wire Firebase, Amplitude, Sentry, or any backend.                                                             |
| **State-Management Bridge**         | `ListenableNotifier` mixin + `StreamListenable` class — connect Riverpod, Bloc, MobX, etc. to the router's refresh pipeline, completely agnostic. |
| **Type-Safe Navigation Extensions** | `context.architectPush<T>` / `context.architectPop<T>` — compile-time enforced return types across screens.                                       |
| **Zero Native Code**                | 100% pure Dart. Works on every platform Flutter supports.                                                                                         |

---

## Requirements

| Dependency | Version  |
| ---------- | -------- |
| Flutter    | ≥ 3.22.0 |
| Dart SDK   | ≥ 3.4.0  |
| go_router  | ≥ 14.0.0 |

---

## Installation

```yaml
dependencies:
  route_architect: ^1.0.0
```

```bash
flutter pub get
```

> You do **not** need to add `go_router` separately — `route_architect`
> re-exports the entire `go_router` API so you only need one import in your app files.

---

## Quick Start

```dart
import 'package:route_architect/route_architect.dart';

final router = RouteArchitect.create(
  routes: [
    GoRoute(path: '/',      builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  ],
  guards: [AuthGuard(authNotifier)],
  refreshListenable: authNotifier,   // re-runs guards on auth state change
  initialLocation: '/home',
  fallbackLocation: '/',             // broken deep links → here
  observers: [DebugRouteObserver()],
  debugLogDiagnostics: true,
);

// In your widget tree:
MaterialApp.router(routerConfig: router);
```

---

## Guards

Implement `RouteGuard` for each routing concern. Guards run **in order**;
the first non-null redirect wins.

```dart
// Synchronous guard
class AuthGuard extends RouteGuard {
  final AuthNotifier _auth;
  AuthGuard(this._auth);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (!_auth.isLoggedIn) return '/login';
    return null; // pass through
  }
}

// Asynchronous guard (SecureStorage / network)
class TokenGuard extends RouteGuard {
  final AuthRepository _repo;
  TokenGuard(this._repo);

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final token = await _repo.getToken();
    if (token == null || token.isExpired) return '/login';
    return null;
  }
}

// Role-based guard
class AdminGuard extends RouteGuard {
  final UserSession _session;
  AdminGuard(this._session);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (_session.role != UserRole.admin) return '/unauthorized';
    return null;
  }
}
```

Pass them in order to `RouteArchitect.create`:

```dart
RouteArchitect.create(
  guards: [AuthGuard(auth), AdminGuard(session), SubscriptionGuard(billing)],
  // ...
);
```

---

## Bottom Navigation Shell

`EnterpriseShell.buildRoute` eliminates all `StatefulShellRoute` boilerplate:

```dart
EnterpriseShell.buildRoute(
  items: [
    ShellBranchItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())],
    ),
    ShellBranchItem(
      label: 'Search',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      routes: [GoRoute(path: '/search', builder: (_, __) => const SearchScreen())],
    ),
    ShellBranchItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
    ),
  ],
  // Optional badges:
  badgeBuilder: (index) => index == 1 ? const Badge(label: Text('3')) : null,
)
```

**Double-Tap to Root** is automatic — tapping the already-active tab pops the
entire branch back to its root route, matching native iOS/Android behaviour.

---

## Analytics Observers

```dart
class FirebaseRouteObserver extends RouteAnalyticsObserver {
  @override
  void onScreenView(String? screenName) =>
      FirebaseAnalytics.instance.setCurrentScreen(screenName: screenName);

  @override
  void onScreenPop(String? screenName) {}

  @override
  void onRouteError(String? attemptedPath, Object? error) =>
      FirebaseCrashlytics.instance.recordError(error, null);
}

RouteArchitect.create(
  observers: [FirebaseRouteObserver(), DebugRouteObserver()],
  // ...
);
```

`DebugRouteObserver` — included out of the box — prints all route events to
the debug console during development.

---

## State-Management Bridge

### ListenableNotifier (mixin)

Use this when your state object cannot extend `ChangeNotifier` (Riverpod
`Notifier`, Bloc, MobX, etc.):

```dart
class AuthNotifier extends Notifier<AuthState> with ListenableNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  void login(User user) {
    state = AuthState.authenticated(user);
    notifyRouteListeners(); // triggers GoRouter guard re-evaluation
  }

  void logout() {
    state = const AuthState.unauthenticated();
    notifyRouteListeners();
  }
}
```

### StreamListenable (class)

Use this for Bloc streams, Riverpod `StreamProvider`, RxDart, etc.:

```dart
final authBloc = AuthBloc();

final router = RouteArchitect.create(
  refreshListenable: StreamListenable(authBloc.stream),
  // ...
);
```

> Remember to call `dispose()` on `StreamListenable` when the router is
> destroyed to cancel the underlying stream subscription.

---

## Type-Safe Navigation Extensions

```dart
// Screen A — push Screen B and await a typed return value
final address = await context.architectPush<ShippingAddress>(
  '/address-picker',
);
if (address != null) setState(() => _selected = address);

// Screen B — pop and return the typed result
ElevatedButton(
  onPressed: () => context.architectPop(selectedAddress),
  child: const Text('Confirm'),
);

// Named route variant with path/query parameters
final product = await context.architectPushNamed<Product>(
  'product-detail',
  pathParameters: {'id': '42'},
);
```

---

## Complete Example

A full working example is in the [`example/`](example/) directory, including:

- `AuthNotifier` (ChangeNotifier) as the auth source of truth
- `AuthGuard` + `RoleGuard` in the pipeline
- `EnterpriseShell` with three tabs
- `DebugRouteObserver` for console logging
- `InheritedWidget`-based DI without any extra packages

---

## API Reference

| Symbol                            | Description                                               |
| --------------------------------- | --------------------------------------------------------- |
| `RouteArchitect.create(...)`      | Static factory for a configured `GoRouter`.               |
| `RouteGuard`                      | Abstract base class for a single guard step.              |
| `GuardPipeline.run(...)`          | Executes guards in order (used internally).               |
| `RouteAnalyticsObserver`          | Abstract `NavigatorObserver` for analytics.               |
| `DebugRouteObserver`              | Dev-mode console-logging observer.                        |
| `EnterpriseBottomNav`             | Bottom-nav widget for `StatefulShellRoute`.               |
| `NavigationItem`                  | Tab descriptor (label, icon, activeIcon).                 |
| `ShellBranchItem`                 | Tab descriptor + branch routes combined.                  |
| `EnterpriseShell.buildRoute(...)` | Zero-boilerplate `StatefulShellRoute` builder.            |
| `ListenableNotifier`              | Mixin to bridge any state manager to `Listenable`.        |
| `StreamListenable`                | Converts a `Stream` into a `Listenable`.                  |
| `RouteArchitectExtensions`        | `architectPush<T>` / `architectPop<T>` on `BuildContext`. |

---

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/Kidpech-code/route_architect).

---

## License

MIT — see [LICENSE](LICENSE).
