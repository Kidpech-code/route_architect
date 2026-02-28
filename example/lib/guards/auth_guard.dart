import 'package:flutter/widgets.dart';
import 'package:route_architect/route_architect.dart';

import '../auth/auth_notifier.dart';

/// Routes that are accessible without authentication.
const _publicRoutes = ['/login', '/onboarding', '/forgot-password'];

/// Redirects unauthenticated users to `/login`.
///
/// Returns `null` (pass-through) when:
/// - the user is already authenticated, OR
/// - they are navigating to a public route.
class AuthGuard extends RouteGuard {
  const AuthGuard(this._auth);

  final AuthNotifier _auth;

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final isPublic = _publicRoutes.any((route) => state.matchedLocation.startsWith(route));

    if (_auth.isAuthenticated) {
      // If authenticated user hits login, send them home.
      if (state.matchedLocation == '/login') return '/home';
      return null;
    }

    // Not authenticated and on a protected route → redirect to login.
    return isPublic ? null : '/login';
  }
}
