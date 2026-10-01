// Route tree for the route_architect example app.
//
// Demonstrates the new declarative EnterpriseShell.buildRoute API.
// No manual StatefulShellRoute.indexedStack or StatefulShellBranch required –
// the package handles all of that from a plain list of ShellBranchItems.

import 'package:material_ui/material_ui.dart';
import 'package:route_architect/route_architect.dart';

import '../auth/auth_notifier.dart';
import '../screens/screens.dart';

// ---------------------------------------------------------------------------
// InheritedWidget – lightweight DI for AuthNotifier (no external DI lib)
// ---------------------------------------------------------------------------

/// Provides [AuthNotifier] to the widget tree via Flutter's built-in
/// [InheritedNotifier] – no Riverpod, Provider, or GetIt required.
class InheritedAuthNotifier extends InheritedNotifier<AuthNotifier> {
  const InheritedAuthNotifier(
      {super.key, required AuthNotifier notifier, required super.child})
      : super(notifier: notifier);

  static AuthNotifier of(BuildContext context) {
    final w =
        context.dependOnInheritedWidgetOfExactType<InheritedAuthNotifier>();
    assert(w != null, 'No InheritedAuthNotifier found in widget tree.');
    return w!.notifier!;
  }
}

// ---------------------------------------------------------------------------
// Route tree
// ---------------------------------------------------------------------------

/// The complete route tree passed to [RouteArchitect.create].
///
/// Structure:
/// ```
/// /login              – public (auth redirect)
/// /admin              – role-guarded (admin only via RoleGuard)
/// EnterpriseShell     – bottom nav (StatefulShellRoute built by the package)
///   /home             – Home tab
///     detail/:id      – deep-nested detail screen
///     address-picker  – Push & Custom Pop demo (returns ShippingAddress)
///   /search           – Search tab
///   /profile          – Profile tab
/// ```
List<RouteBase> appRoutes(AuthNotifier auth) => [
      // ── Public routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(authNotifier: auth),
      ),

      // ── Admin route (role-guarded by RoleGuard in the pipeline) ─────────
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),

      // ── Bottom navigation shell (fully declarative via EnterpriseShell) ──
      //
      // Before this API, this required ~30 lines of StatefulShellRoute +
      // StatefulShellBranch + EnterpriseBottomNav boilerplate.
      // Now: one call, one list, zero duplication.
      EnterpriseShell.buildRoute(
        // ① Demo badge: red dot on the Search tab.
        badgeBuilder: (index) => index == 1
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              )
            : null,

        items: [
          // ── Home branch ────────────────────────────────────────────────
          ShellBranchItem(
            label: 'Home',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => HomeScreen(authNotifier: auth),
                routes: [
                  // Deep-nested detail route.
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) =>
                        DetailScreen(id: state.pathParameters['id']!),
                  ),

                  // ② Push & Custom Pop demo: Screen A → Screen B → returns
                  //   a typed ShippingAddress back to Screen A.
                  GoRoute(
                      path: 'address-picker',
                      builder: (context, state) => const AddressPickerScreen()),
                ],
              ),
            ],
          ),

          // ── Search branch ───────────────────────────────────────────────
          ShellBranchItem(
            label: 'Search',
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            routes: [
              GoRoute(
                  path: '/search',
                  builder: (context, state) => const SearchScreen())
            ],
          ),

          // ── Profile branch ──────────────────────────────────────────────
          ShellBranchItem(
            label: 'Profile',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => ProfileScreen(authNotifier: auth),
              ),
            ],
          ),
        ],
      ),
    ];
