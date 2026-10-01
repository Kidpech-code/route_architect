import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
// RouteAnalyticsObserver
// ---------------------------------------------------------------------------

/// Memory-safe abstract [NavigatorObserver] for routing analytics.
///
/// Extend this class and override [onScreenView] / [onScreenPop] to wire up
/// any analytics backend (Firebase Analytics, Amplitude, Mixpanel, Sentry,
/// or your own internal logging system).
///
/// The observer tracks the **full route name** including query parameters as
/// provided by `go_router` (e.g. `/home/detail?id=42`).
///
/// ### Example – Firebase Analytics
/// ```dart
/// class FirebaseRouteObserver extends RouteAnalyticsObserver {
///   @override
///   void onScreenView(String? screenName) {
///     FirebaseAnalytics.instance.setCurrentScreen(screenName: screenName);
///   }
///
///   @override
///   void onScreenPop(String? screenName) {
///     // optionally track screen exit events
///   }
/// }
/// ```
///
/// ### Example – Multiple Analytics
/// ```dart
/// RouteArchitect.create(
///   observers: [
///     FirebaseRouteObserver(),
///     AmplitudeRouteObserver(),
///     DebugRouteObserver(),        // built-in dev logger
///   ],
///   // ...
/// );
/// ```
abstract class RouteAnalyticsObserver extends NavigatorObserver {
  /// Called when a new screen is pushed or revealed after a pop/replace.
  ///
  /// [screenName] derives from [RouteSettings.name], which `go_router`
  /// populates with the full URL path.
  void onScreenView(String? screenName);

  /// Called when the user navigates *away* from [screenName] via a pop.
  void onScreenPop(String? screenName);

  /// Called when a route error is intercepted (e.g. broken deep link).
  ///
  /// Override to send error events to your analytics backend.
  /// The default implementation is a no-op.
  void onRouteError(String? attemptedPath, Object? error) {}

  // ── NavigatorObserver overrides ──────────────────────────────────────────

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onScreenView(_nameOf(route));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onScreenPop(_nameOf(route));
    // Re-surface the screen that becomes active after the pop.
    onScreenView(_nameOf(previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onScreenView(_nameOf(newRoute));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onScreenPop(_nameOf(route));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _nameOf(Route<dynamic>? route) => route?.settings.name;
}

// ---------------------------------------------------------------------------
// DebugRouteObserver
// ---------------------------------------------------------------------------

/// A development-only [RouteAnalyticsObserver] that prints route events
/// to the debug console.
///
/// Drop this in during development to verify your route names are correct
/// without wiring up a real analytics service.
///
/// ```dart
/// RouteArchitect.create(
///   observers: [DebugRouteObserver()],
///   // ...
/// );
/// ```
class DebugRouteObserver extends RouteAnalyticsObserver {
  /// Creates a [DebugRouteObserver].
  DebugRouteObserver();

  @override
  void onScreenView(String? screenName) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[RouteArchitect] ▶ SCREEN VIEW : $screenName');
    }
  }

  @override
  void onScreenPop(String? screenName) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[RouteArchitect] ◀ SCREEN POP  : $screenName');
    }
  }

  @override
  void onRouteError(String? attemptedPath, Object? error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
          '[RouteArchitect] ✖ ROUTE ERROR : path=$attemptedPath error=$error');
    }
  }
}
