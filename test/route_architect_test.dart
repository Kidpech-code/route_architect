import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_architect/route_architect.dart';

// ---------------------------------------------------------------------------
// Test Guards
// ---------------------------------------------------------------------------

class _AllowGuard extends RouteGuard {
  const _AllowGuard();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) => null;
}

class _BlockGuard extends RouteGuard {
  final String redirectTo;
  const _BlockGuard(this.redirectTo);

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      redirectTo;
}

class _AsyncGuard extends RouteGuard {
  final Duration delay;
  final String? result;

  const _AsyncGuard({required this.delay, this.result});

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    await Future<void>.delayed(delay);
    return result;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RouteArchitect.create', () {
    test('creates a GoRouter instance with valid routes', () {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SizedBox(),
          ),
        ],
      );
      expect(router, isA<GoRouter>());
      router.dispose();
    });

    test('asserts when routes are empty', () {
      expect(
        () => RouteArchitect.create(routes: []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts guards, observers, and refresh listenable', () {
      final notifier = _TestNotifier();
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/login', builder: (_, __) => const SizedBox()),
        ],
        guards: [const _AllowGuard()],
        observers: [DebugRouteObserver()],
        refreshListenable: notifier,
        initialLocation: '/',
        debugLogDiagnostics: false,
      );
      expect(router, isA<GoRouter>());
      router.dispose();
      notifier.disposeRouteListenable();
    });

    testWidgets('unknown routes return to fallbackLocation', (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Home')),
        ],
        fallbackLocation: '/',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/missing');
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      router.dispose();
    });

    test('accepts custom error screen builder', () {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        ],
        errorScreenBuilder: (context, state) => const Scaffold(
          body: Center(child: Text('Custom 404')),
        ),
      );
      expect(router, isA<GoRouter>());
      router.dispose();
    });

    testWidgets('redirect fires blocking guard', (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Home')),
          GoRoute(path: '/login', builder: (_, __) => const Text('Login')),
        ],
        guards: [const _BlockGuard('/login')],
        initialLocation: '/',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      router.dispose();
    });

    testWidgets('allows navigation when all guards pass', (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Home')),
          GoRoute(path: '/login', builder: (_, __) => const Text('Login')),
        ],
        guards: [const _AllowGuard()],
        initialLocation: '/',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      router.dispose();
    });

    testWidgets('async guards work correctly', (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Home')),
          GoRoute(path: '/login', builder: (_, __) => const Text('Login')),
        ],
        guards: [
          const _AsyncGuard(
            delay: Duration(milliseconds: 10),
            result: '/login',
          ),
        ],
        initialLocation: '/',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      router.dispose();
    });

    testWidgets('shows default error page for unknown routes', (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('Home')),
        ],
        initialLocation: '/',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Navigate to a non-existent route.
      router.go('/nonexistent');
      await tester.pumpAndSettle();

      // Should show the built-in 404 page.
      expect(find.text('404'), findsOneWidget);
      router.dispose();
    });

    testWidgets('error page returns to the configured initial location',
        (tester) async {
      final router = RouteArchitect.create(
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const Text('Home')),
        ],
        initialLocation: '/home',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/missing');
      await tester.pumpAndSettle();
      expect(find.text('404'), findsOneWidget);

      await tester.tap(find.text('Go to Start'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      router.dispose();
    });
  });

  group('ListenableNotifier', () {
    test('notifies listeners on notifyRouteListeners()', () {
      final notifier = _TestNotifier();
      var called = false;
      notifier.addListener(() => called = true);
      notifier.triggerChange();
      expect(called, isTrue);
      notifier.disposeRouteListenable();
    });

    test('supports multiple listeners', () {
      final notifier = _TestNotifier();
      var count = 0;
      notifier.addListener(() => count++);
      notifier.addListener(() => count++);
      notifier.triggerChange();
      expect(count, 2);
      notifier.disposeRouteListenable();
    });

    test('removeListener stops notifications', () {
      final notifier = _TestNotifier();
      var count = 0;
      void listener() => count++;
      notifier.addListener(listener);
      notifier.triggerChange();
      expect(count, 1);

      notifier.removeListener(listener);
      notifier.triggerChange();
      expect(count, 1); // unchanged
      notifier.disposeRouteListenable();
    });
  });

  group('StreamListenable', () {
    test('notifies on stream emission', () async {
      final controller = StreamController<int>.broadcast();
      final listenable = StreamListenable(controller.stream);
      var callCount = 0;
      listenable.addListener(() => callCount++);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 2);

      listenable.dispose();
      await controller.close();
    });

    test('stops notifying after dispose', () async {
      final controller = StreamController<int>.broadcast();
      final listenable = StreamListenable(controller.stream);
      var callCount = 0;
      listenable.addListener(() => callCount++);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);

      listenable.dispose();
      // This emission should not trigger the listener.
      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 1);

      await controller.close();
    });
  });

  group('NavigationItem', () {
    test('creates with required parameters', () {
      const item = NavigationItem(
        label: 'Home',
        icon: Icons.home_outlined,
      );
      expect(item.label, 'Home');
      expect(item.icon, Icons.home_outlined);
      expect(item.activeIcon, isNull);
      expect(item.tooltip, isNull);
    });

    test('creates with all parameters', () {
      const item = NavigationItem(
        label: 'Search',
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        tooltip: 'Search everything',
      );
      expect(item.activeIcon, Icons.search);
      expect(item.tooltip, 'Search everything');
    });
  });

  group('DebugRouteObserver', () {
    test('does not throw on screen view / pop / error', () {
      final observer = DebugRouteObserver();
      expect(() => observer.onScreenView('/test'), returnsNormally);
      expect(() => observer.onScreenPop('/test'), returnsNormally);
      expect(
        () => observer.onRouteError('/bad', Exception('fail')),
        returnsNormally,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test Helpers
// ---------------------------------------------------------------------------

class _TestNotifier with ListenableNotifier {
  /// Exposed for tests – wraps the @protected [notifyRouteListeners].
  void triggerChange() => notifyRouteListeners();

  @override
  // ignore: invalid_use_of_protected_member
  void notifyRouteListeners() => super.notifyRouteListeners();
}
