import 'dart:async';

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// ListenableNotifier – Agnostic Auth Synchronization Helper
// ---------------------------------------------------------------------------

/// A mixin that converts a class into a [Listenable] backed by
/// [ChangeNotifier], suitable for passing to `GoRouter.refreshListenable`.
///
/// This is the **single bridge** between your state management solution and
/// the router – keeping `route_architect` completely agnostic.
///
/// ### Why?
/// `GoRouter.refreshListenable` requires a [Listenable]. If you use
/// `ChangeNotifier` natively (Provider, GetX, vanilla Flutter), you already
/// have one. But if you use **Riverpod**, **Bloc**, **MobX**, or **Signals**,
/// you need a small adapter. This mixin provides that.
///
/// ### Example – With Riverpod `Notifier`
/// ```dart
/// class AuthNotifier extends Notifier<AuthState> with ListenableNotifier {
///   @override
///   AuthState build() => const AuthState.unauthenticated();
///
///   void login(User user) {
///     state = AuthState.authenticated(user);
///     notifyRouteListeners(); // triggers GoRouter re-evaluation
///   }
///
///   void logout() {
///     state = const AuthState.unauthenticated();
///     notifyRouteListeners();
///   }
/// }
/// ```
///
/// ### Example – With Bloc / Cubit
/// ```dart
/// class AuthCubit extends Cubit<AuthState> with ListenableNotifier {
///   AuthCubit() : super(const AuthState.initial());
///
///   void login(User user) {
///     emit(AuthState.authenticated(user));
///     notifyRouteListeners();
///   }
/// }
/// ```
///
/// ### Example – Simple ChangeNotifier (Provider)
/// ```dart
/// class AuthNotifier extends ChangeNotifier with ListenableNotifier {
///   bool _isLoggedIn = false;
///   bool get isLoggedIn => _isLoggedIn;
///
///   void login() {
///     _isLoggedIn = true;
///     notifyRouteListeners(); // also calls notifyListeners() via the mixin
///   }
/// }
/// ```
///
/// Then pass the notifier to [RouteArchitect.create]:
/// ```dart
/// final router = RouteArchitect.create(
///   refreshListenable: authNotifier,
///   // ...
/// );
/// ```
mixin ListenableNotifier implements Listenable {
  final _routeNotifier = ChangeNotifier();

  /// Call this whenever your auth / session state changes to trigger
  /// `GoRouter` re-evaluation of the guard pipeline.
  ///
  /// This is intentionally named differently from `ChangeNotifier.notifyListeners`
  /// to avoid conflicts when mixed into classes that already extend
  /// `ChangeNotifier`.
  @protected
  void notifyRouteListeners() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    _routeNotifier.notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _routeNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _routeNotifier.removeListener(listener);
  }

  /// Disposes the internal [ChangeNotifier]. Call this in your class's
  /// `dispose` method if applicable.
  void disposeRouteListenable() {
    _routeNotifier.dispose();
  }
}

// ---------------------------------------------------------------------------
// StreamListenable – Convert any Stream into a Listenable
// ---------------------------------------------------------------------------

/// Converts a [Stream] into a [Listenable] that notifies when the stream
/// emits a new value.
///
/// This is useful for **Bloc**, **Riverpod StreamProvider**, **RxDart**,
/// or any reactive pipeline that exposes a `Stream` rather than a
/// `ChangeNotifier`.
///
/// ### Example – Bloc Stream
/// ```dart
/// final authBloc = AuthBloc();
/// final router = RouteArchitect.create(
///   refreshListenable: StreamListenable(authBloc.stream),
///   // ...
/// );
/// ```
///
/// ### Example – Riverpod StreamProvider
/// ```dart
/// final router = RouteArchitect.create(
///   refreshListenable: StreamListenable(ref.read(authStreamProvider.stream)),
///   // ...
/// );
/// ```
///
/// **Important:** Call [dispose] when the router is no longer needed to cancel
/// the underlying stream subscription.
class StreamListenable extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  /// Creates a [StreamListenable] that listens to [stream] and calls
  /// [notifyListeners] on every emission.
  StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
