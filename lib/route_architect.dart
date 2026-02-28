/// **route_architect** – Enterprise-grade Flutter routing on top of `go_router`.
///
/// This package provides a zero-friction, fully declarative API for
/// production Flutter apps. It handles guard pipelines, deep-link safety,
/// bottom-navigation shells, analytics observers, and auth-reactive routing
/// out of the box.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:route_architect/route_architect.dart';
///
/// final router = RouteArchitect.create(
///   routes: $appRoutes,                          // from go_router_builder
///   guards: [AuthGuard(auth), RoleGuard(auth)],
///   refreshListenable: authNotifier,
///   initialLocation: '/home',
///   fallbackLocation: '/',                       // broken deep links → here
///   observers: [DebugRouteObserver()],
/// );
///
/// // In your widget tree:
/// MaterialApp.router(routerConfig: router);
/// ```
///
/// ## What's Included
///
/// | Export | Purpose |
/// |---|---|
/// | [RouteArchitect] | Static factory that creates a configured `GoRouter`. |
/// | [RouteGuard] | Abstract async guard for the redirect pipeline. |
/// | [GuardPipeline] | Chain-of-Responsibility executor for guards. |
/// | [RouteAnalyticsObserver] | Abstract navigator observer for analytics. |
/// | [DebugRouteObserver] | Dev-mode console logger. |
/// | [EnterpriseBottomNav] | Plug-and-play bottom nav shell with double-tap-to-root. |
/// | [NavigationItem] | Tab descriptor for `EnterpriseBottomNav`. |
/// | [ListenableNotifier] | Mixin to bridge any state management to `Listenable`. |
/// | [StreamListenable] | Converts a `Stream` into a `Listenable`. |
/// | [RouteArchitectExtensions] | `context.architectPush<T>()` and `context.architectPop<T>()`. |
/// | [ShellBranchItem] | Combines tab descriptor + branch routes for declarative shell setup. |
/// | [EnterpriseShell] | Zero-boilerplate `StatefulShellRoute` builder. |
library;

// ── Core API ────────────────────────────────────────────────────────────────
export 'src/route_architect_config.dart' show RouteArchitect;
export 'src/route_guard.dart' show RouteGuard, GuardPipeline;

// ── Observability ───────────────────────────────────────────────────────────
export 'src/analytics_observer.dart'
    show RouteAnalyticsObserver, DebugRouteObserver;

// ── Navigation Shell ────────────────────────────────────────────────────────
export 'src/enterprise_bottom_nav.dart'
    show EnterpriseBottomNav, NavigationItem, ShellBranchItem, EnterpriseShell;

// ── Context Extensions ──────────────────────────────────────────────────────
export 'src/route_extensions.dart' show RouteArchitectExtensions;

// ── State-Management Bridge ─────────────────────────────────────────────────
export 'src/listenable_notifier.dart' show ListenableNotifier, StreamListenable;

// ── Re-export go_router so consumers only depend on route_architect. ────────
export 'package:go_router/go_router.dart';
