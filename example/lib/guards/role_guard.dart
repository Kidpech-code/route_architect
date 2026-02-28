import 'package:flutter/widgets.dart';
import 'package:route_architect/route_architect.dart';

import '../auth/auth_notifier.dart';

/// Routes that require [UserRole.admin] access.
const _adminRoutes = ['/admin'];

/// Redirects non-admin users away from admin-only routes.
///
/// This guard is intentionally narrow: it only acts on [_adminRoutes] and is
/// otherwise transparent (returns `null`). It relies on [AuthGuard] having
/// already verified that the user is authenticated.
class RoleGuard extends RouteGuard {
  const RoleGuard(this._auth);

  final AuthNotifier _auth;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final isAdminRoute =
        _adminRoutes.any((route) => state.matchedLocation.startsWith(route));

    if (!isAdminRoute) return null; // Not our concern.

    final user = _auth.currentUser;

    // currentUser is null only if somehow AuthGuard was bypassed.
    if (user == null || !user.isAdmin) {
      return '/home'; // Soft redirect – no crash, no error.
    }

    return null; // Admin confirmed – proceed.
  }
}
