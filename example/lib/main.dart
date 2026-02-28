// =============================================================================
//  route_architect – Full Usage Example
//
//  Architecture
//  ─────────────
//  1. AuthNotifier  (ChangeNotifier)  →  state-management-agnostic auth state
//  2. AuthGuard     (RouteGuard)      →  redirects unauthenticated users
//  3. RoleGuard     (RouteGuard)      →  redirects non-admins from /admin
//  4. DebugRouteObserver              →  prints screen views/pops to console
//  5. RouteArchitect.create           →  assembles the GoRouter declaratively
//  6. InheritedAuthNotifier           →  zero-dependency DI for AuthNotifier
//  7. appRoutes(auth)                 →  manually declared type-safe route tree
// =============================================================================

import 'package:flutter/material.dart';
import 'package:route_architect/route_architect.dart';

import 'auth/auth_notifier.dart';
import 'guards/auth_guard.dart';
import 'guards/role_guard.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const RouteArchitectExampleApp());
}

class RouteArchitectExampleApp extends StatefulWidget {
  const RouteArchitectExampleApp({super.key});

  @override
  State<RouteArchitectExampleApp> createState() => _RouteArchitectExampleAppState();
}

class _RouteArchitectExampleAppState extends State<RouteArchitectExampleApp> {
  // ── Auth state ────────────────────────────────────────────────────────────

  /// Single source of auth truth.
  ///
  /// Because [AuthNotifier] extends [ChangeNotifier] (a [Listenable]), it can
  /// be passed directly to `RouteArchitect.create(refreshListenable: ...)`.
  /// No Riverpod, Bloc, or Provider needed.
  final AuthNotifier _authNotifier = AuthNotifier();

  // ── Router ────────────────────────────────────────────────────────────────

  late final GoRouter _router = RouteArchitect.create(
    // ① Manually declared route tree – no build_runner required.
    routes: appRoutes(_authNotifier),
    // ② Guard pipeline – AuthGuard runs first, then RoleGuard.
    //    First non-null redirect wins; subsequent guards are skipped.
    guards: [AuthGuard(_authNotifier), RoleGuard(_authNotifier)],
    // ③ Attach the AuthNotifier as the refresh trigger.
    //    Login/logout automatically re-runs the guard pipeline – no manual
    //    router.refresh() call required.
    refreshListenable: _authNotifier,
    // ④ App entry point. AuthGuard will redirect to /login if needed.
    initialLocation: '/home',
    // ⑤ Analytics observer. DebugRouteObserver prints to the console; swap
    //    for a FirebaseRouteObserver in production.
    observers: [DebugRouteObserver()],
    // ⑥ Broken deep links silently redirect to '/home' instead of crashing.
    //    Set to null (or omit) to show the built-in 404 error page instead.
    fallbackLocation: '/home',
    // ⑦ Redirect loop guard (default 20).
    redirectLimit: 10,
    // ⑧ Verbose go_router logging in debug mode.
    debugLogDiagnostics: true,
  );

  @override
  void dispose() {
    _router.dispose();
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // InheritedAuthNotifier gives every GoRouteData.build() method access to
    // AuthNotifier via InheritedAuthNotifier.of(context) – no package needed.
    return InheritedAuthNotifier(
      notifier: _authNotifier,
      child: MaterialApp.router(
        title: 'Route Architect Demo',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
        routerConfig: _router,
      ),
    );
  }
}
