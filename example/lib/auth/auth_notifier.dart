import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Domain model
// ---------------------------------------------------------------------------

/// User roles for role-based access control.
enum UserRole { guest, member, admin }

/// Immutable user entity (mirrors a typical Freezed data class pattern).
///
/// In a real app this would be annotated with `@freezed` – the structure and
/// immutability contract are identical.
@immutable
class AppUser {
  const AppUser({required this.id, required this.email, required this.displayName, this.role = UserRole.member});

  final String id;
  final String email;
  final String displayName;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  AppUser copyWith({String? id, String? email, String? displayName, UserRole? role}) {
    return AppUser(id: id ?? this.id, email: email ?? this.email, displayName: displayName ?? this.displayName, role: role ?? this.role);
  }

  @override
  String toString() => 'AppUser($email, role: $role)';
}

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

/// Discriminated union representing authentication state.
sealed class AuthState {
  const AuthState();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  const Authenticated({required this.user});
  final AppUser user;
}

// ---------------------------------------------------------------------------
// AuthNotifier  (state-management agnostic – just ChangeNotifier)
// ---------------------------------------------------------------------------

/// Holds authentication state and notifies listeners on changes.
///
/// Because it extends [ChangeNotifier] it is a [Listenable], making it a
/// drop-in argument for `RouteArchitectBuilder.withRefreshListenable`.
class AuthNotifier extends ChangeNotifier {
  AuthState _state = const Unauthenticated();

  AuthState get state => _state;

  bool get isAuthenticated => _state is Authenticated;

  AppUser? get currentUser => _state is Authenticated ? (_state as Authenticated).user : null;

  /// Simulates a successful login.
  Future<void> login({required String email, String password = 'password', UserRole role = UserRole.member}) async {
    // Simulate network delay.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _state = Authenticated(
      user: AppUser(id: 'usr_${email.hashCode.abs()}', email: email, displayName: email.split('@').first, role: role),
    );
    notifyListeners();
  }

  /// Logs out the current user.
  void logout() {
    _state = const Unauthenticated();
    notifyListeners();
  }
}
