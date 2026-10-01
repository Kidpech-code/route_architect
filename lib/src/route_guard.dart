import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// RouteGuard – Abstract Guard Interface
// ---------------------------------------------------------------------------

/// A single routing guard in the [GuardPipeline].
///
/// Implement this class to encapsulate **one discrete routing concern** such as
/// authentication, onboarding, feature flags, role-based access, or
/// subscription gating.
///
/// The [redirect] method returns a `FutureOr<String?>`:
/// - Return a **non-null** path string to halt the pipeline and redirect.
/// - Return **`null`** to allow navigation to proceed to the next guard.
///
/// Because the return type is `FutureOr`, guards can be **synchronous or
/// asynchronous** – check a simple in-memory flag *or* await a database /
/// SecureStorage / network call.
///
/// ### Example – Synchronous Guard
/// ```dart
/// class OnboardingGuard extends RouteGuard {
///   final AppConfig config;
///   OnboardingGuard(this.config);
///
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
///     if (config.hasCompletedOnboarding) return null;
///     return state.matchedLocation == '/onboarding' ? null : '/onboarding';
///   }
/// }
/// ```
///
/// ### Example – Asynchronous Guard (SecureStorage / SQLite)
/// ```dart
/// class AuthGuard extends RouteGuard {
///   final AuthRepository _repo;
///   AuthGuard(this._repo);
///
///   @override
///   Future<String?> redirect(BuildContext context, GoRouterState state) async {
///     final token = await _repo.getStoredToken();
///     if (token != null && !token.isExpired) return null;
///     return state.matchedLocation == '/login' ? null : '/login';
///   }
/// }
/// ```
///
/// ### Example – Role-Based Guard
/// ```dart
/// class AdminGuard extends RouteGuard {
///   final UserSession session;
///   AdminGuard(this.session);
///
///   @override
///   FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
///     final path = state.matchedLocation;
///     if ((path == '/admin' || path.startsWith('/admin/')) &&
///         session.role != UserRole.admin) return '/unauthorized';
///     return null;
///   }
/// }
/// ```
abstract class RouteGuard {
  /// Creates a [RouteGuard].
  const RouteGuard();

  /// Called sequentially by [GuardPipeline.run].
  ///
  /// [context] – the current [BuildContext] (the navigator's context).
  /// [state]   – the [GoRouterState] describing the pending navigation.
  ///
  /// Returns a redirect path, or `null` to pass control to the next guard.
  ///
  /// **Note:** The return type is `FutureOr<String?>` so you may return a
  /// plain `String?` for purely synchronous checks, or `Future<String?>` when
  /// an asynchronous lookup is required. The pipeline handles both
  /// transparently.
  FutureOr<String?> redirect(BuildContext context, GoRouterState state);
}

// ---------------------------------------------------------------------------
// GuardPipeline – Chain of Responsibility Executor
// ---------------------------------------------------------------------------

/// Executes a [List<RouteGuard>] sequentially using the
/// **Chain of Responsibility** pattern.
///
/// The pipeline short-circuits on the **first non-null** redirect returned by
/// any guard; subsequent guards are never invoked. If every guard returns
/// `null`, navigation proceeds normally.
///
/// ### How it integrates with `GoRouter.redirect`
///
/// ```dart
/// GoRouter(
///   redirect: (context, state) =>
///       GuardPipeline.run(myGuards, context, state),
///   // ...
/// );
/// ```
///
/// You should **not** need to call this directly – [RouteArchitect.create]
/// wires it up automatically.
abstract final class GuardPipeline {
  GuardPipeline._();

  /// Runs [guards] in insertion order, returning the first non-null redirect.
  ///
  /// Guards returning `FutureOr<String?>` are awaited transparently –
  /// synchronous guards incur no unnecessary microtask overhead.
  static Future<String?> run(
    List<RouteGuard> guards,
    BuildContext context,
    GoRouterState state,
  ) async {
    for (final guard in guards) {
      final result = await guard.redirect(context, state);
      if (result != null) return result;
    }
    return null;
  }
}
