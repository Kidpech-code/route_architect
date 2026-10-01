import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

// ---------------------------------------------------------------------------
// ShellBranchItem – Declarative Tab + Branch Descriptor
// ---------------------------------------------------------------------------

/// Combines a tab's visual descriptor ([NavigationItem]) with its branch
/// [routes], enabling fully declarative bottom-nav setup via
/// [EnterpriseShell.buildRoute].
///
/// Each [ShellBranchItem] maps 1-to-1 with a `StatefulShellBranch` and its
/// corresponding `BottomNavigationBarItem` – you no longer need to maintain
/// two parallel lists in sync.
///
/// ### Quick Example
/// ```dart
/// ShellBranchItem(
///   label: 'Home',
///   icon: Icons.home_outlined,
///   activeIcon: Icons.home,
///   routes: [
///     GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
///   ],
/// )
/// ```
@immutable
class ShellBranchItem {
  /// Creates a [ShellBranchItem].
  const ShellBranchItem({
    required this.label,
    required this.icon,
    required this.routes,
    this.activeIcon,
    this.tooltip,
    this.navigatorKey,
  });

  /// Display label shown below the tab icon.
  final String label;

  /// Icon shown when the tab is **not** selected.
  final IconData icon;

  /// Icon shown when the tab **is** selected. Falls back to [icon].
  final IconData? activeIcon;

  /// Optional tooltip override. Defaults to [label].
  final String? tooltip;

  /// The routes served by this branch.
  ///
  /// Typically a single root `GoRoute` whose `path` is the branch entry
  /// (e.g. `/home`), optionally with nested `routes`.
  final List<RouteBase> routes;

  /// Optional `GlobalKey` for the branch navigator.
  ///
  /// Useful when you need direct access to the navigator outside the widget
  /// tree (e.g. for imperative navigation from a service layer).
  final GlobalKey<NavigatorState>? navigatorKey;
}

// ---------------------------------------------------------------------------
// EnterpriseShell – Zero-Boilerplate StatefulShellRoute Builder
// ---------------------------------------------------------------------------

/// Static factory that builds a fully-configured `StatefulShellRoute` from a
/// list of [ShellBranchItem]s.
///
/// Removes **all** `StatefulShellRoute.indexedStack` / `StatefulShellBranch`
/// boilerplate from the host project. The host only declares what each tab
/// looks like and what routes it owns.
///
/// ## Before (manual boilerplate – 30+ lines)
/// ```dart
/// StatefulShellRoute.indexedStack(
///   builder: (context, state, shell) => EnterpriseBottomNav(
///     navigationShell: shell,
///     items: const [
///       NavigationItem(label: 'Home',   icon: Icons.home_outlined, activeIcon: Icons.home),
///       NavigationItem(label: 'Search', icon: Icons.search),
///     ],
///   ),
///   branches: [
///     StatefulShellBranch(routes: [GoRoute(path: '/home', ...)]),
///     StatefulShellBranch(routes: [GoRoute(path: '/search', ...)]),
///   ],
/// )
/// ```
///
/// ## After (declarative – 10 lines)
/// ```dart
/// EnterpriseShell.buildRoute(
///   items: [
///     ShellBranchItem(label: 'Home',   icon: Icons.home_outlined, activeIcon: Icons.home,
///                     routes: [GoRoute(path: '/home', ...)]),
///     ShellBranchItem(label: 'Search', icon: Icons.search,
///                     routes: [GoRoute(path: '/search', ...)]),
///   ],
/// )
/// ```
abstract final class EnterpriseShell {
  EnterpriseShell._();

  /// Assembles a [StatefulShellRoute] from a list of [ShellBranchItem]s.
  ///
  /// All [EnterpriseBottomNav] customisation options are exposed directly so
  /// you never need to instantiate `EnterpriseBottomNav` manually.
  ///
  /// ### Parameters
  ///
  /// - **[items]** *(required)* – At least 2 [ShellBranchItem]s. Order
  ///   determines left-to-right tab order.
  /// - **[badgeBuilder]** – Return a badge widget for an index, or `null`.
  /// - **[themeData]** – Full `BottomNavigationBarThemeData` override.
  /// - **[backgroundColor]** / **[elevation]** / **[selectedItemColor]** /
  ///   **[unselectedItemColor]** – Granular style overrides.
  /// - **[showUnselectedLabels]** – Defaults to `true`.
  /// - **[type]** – `fixed` (default) or `shifting`.
  static StatefulShellRoute buildRoute({
    required List<ShellBranchItem> items,
    Widget? Function(int index)? badgeBuilder,
    BottomNavigationBarThemeData? themeData,
    Color? backgroundColor,
    double? elevation,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    bool showUnselectedLabels = true,
    BottomNavigationBarType type = BottomNavigationBarType.fixed,
  }) {
    assert(
      items.length >= 2,
      'EnterpriseShell.buildRoute requires at least 2 ShellBranchItems.',
    );

    return StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => EnterpriseBottomNav(
        navigationShell: shell,
        items: items
            .map(
              (item) => NavigationItem(
                label: item.label,
                icon: item.icon,
                activeIcon: item.activeIcon,
                tooltip: item.tooltip,
              ),
            )
            .toList(growable: false),
        badgeBuilder: badgeBuilder,
        themeData: themeData,
        backgroundColor: backgroundColor,
        elevation: elevation,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        showUnselectedLabels: showUnselectedLabels,
        type: type,
      ),
      branches: items
          .map(
            (item) => StatefulShellBranch(
              navigatorKey: item.navigatorKey,
              routes: item.routes,
            ),
          )
          .toList(growable: false),
    );
  }
}

// ---------------------------------------------------------------------------
// NavigationItem – Tab Descriptor
// ---------------------------------------------------------------------------

/// Describes a single tab in [EnterpriseBottomNav].
///
/// Each [NavigationItem] maps 1-to-1 with a `StatefulShellBranch` in your
/// route configuration.
///
/// ```dart
/// const items = [
///   NavigationItem(label: 'Home',    icon: Icons.home_outlined,   activeIcon: Icons.home),
///   NavigationItem(label: 'Search',  icon: Icons.search_outlined, activeIcon: Icons.search),
///   NavigationItem(label: 'Profile', icon: Icons.person_outline,  activeIcon: Icons.person),
/// ];
/// ```
@immutable
class NavigationItem {
  /// Creates a [NavigationItem].
  const NavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.tooltip,
  });

  /// Display label shown below the icon.
  final String label;

  /// Icon shown when the tab is **not** selected.
  final IconData icon;

  /// Icon shown when the tab **is** selected.
  /// Falls back to [icon] when omitted.
  final IconData? activeIcon;

  /// Optional tooltip override (defaults to [label]).
  final String? tooltip;
}

// ---------------------------------------------------------------------------
// EnterpriseBottomNav – Plug-and-Play Bottom Navigation Shell
// ---------------------------------------------------------------------------

/// A production-ready bottom-navigation host for `StatefulShellRoute`.
///
/// ## Features
/// - Tapping the already-active tab pops the entire
///   branch back to its root route, matching iOS / Android platform
///   conventions.
/// - **Minimal API** – just pass a list of [NavigationItem]s. The widget
///   handles `StatefulShellRoute.indexedStack` integration internally.
/// - **Full Theming** – respects `BottomNavigationBarThemeData` from the
///   ambient `Theme`, or accepts per-property overrides.
/// - **Badge Support** – supply [badgeBuilder] to render notification dots
///   or counts over any tab icon.
///
/// ## Usage
///
/// ### 1. Define your items
/// ```dart
/// const kNavItems = [
///   NavigationItem(label: 'Home',    icon: Icons.home_outlined,   activeIcon: Icons.home),
///   NavigationItem(label: 'Search',  icon: Icons.search,          activeIcon: Icons.search),
///   NavigationItem(label: 'Profile', icon: Icons.person_outline,  activeIcon: Icons.person),
/// ];
/// ```
///
/// ### 2. Wire into your route tree
/// ```dart
/// StatefulShellRoute.indexedStack(
///   builder: (context, state, shell) => EnterpriseBottomNav(
///     navigationShell: shell,
///     items: kNavItems,
///   ),
///   branches: [
///     StatefulShellBranch(routes: [GoRoute(path: '/home',    ...)]),
///     StatefulShellBranch(routes: [GoRoute(path: '/search',  ...)]),
///     StatefulShellBranch(routes: [GoRoute(path: '/profile', ...)]),
///   ],
/// )
/// ```
///
/// ### 3. (Optional) Add badges
/// ```dart
/// EnterpriseBottomNav(
///   navigationShell: shell,
///   items: kNavItems,
///   badgeBuilder: (index) => index == 2
///       ? const Badge(label: Text('3'))
///       : null,
/// )
/// ```
///
/// That's it – no boilerplate, no manual index tracking, no custom callbacks.
class EnterpriseBottomNav extends StatelessWidget {
  /// Creates an [EnterpriseBottomNav].
  ///
  /// [items] must contain at least 2 entries and must match the number of
  /// `branches` in your `StatefulShellRoute`.
  const EnterpriseBottomNav({
    super.key,
    required this.navigationShell,
    required this.items,
    this.themeData,
    this.badgeBuilder,
    this.backgroundColor,
    this.elevation,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.showUnselectedLabels = true,
    this.type = BottomNavigationBarType.fixed,
  }) : assert(
          items.length >= 2,
          'EnterpriseBottomNav requires at least 2 navigation items.',
        );

  /// The [StatefulNavigationShell] provided by
  /// `StatefulShellRoute.indexedStack`'s builder callback.
  final StatefulNavigationShell navigationShell;

  /// One item per branch – order must match the `branches` list in your
  /// `StatefulShellRoute`.
  final List<NavigationItem> items;

  /// Optional theme override. When `null`, inherits from the ambient
  /// [ThemeData.bottomNavigationBarTheme].
  final BottomNavigationBarThemeData? themeData;

  /// Optional builder for per-tab badge overlays.
  ///
  /// Return a widget (e.g. `Badge`) for the given [index], or `null` for no
  /// badge on that tab.
  ///
  /// ```dart
  /// badgeBuilder: (index) => index == 1
  ///     ? const Badge(label: Text('5'))
  ///     : null,
  /// ```
  final Widget? Function(int index)? badgeBuilder;

  /// Overrides [BottomNavigationBarThemeData.backgroundColor].
  final Color? backgroundColor;

  /// Overrides elevation. Defaults to the theme's value, then `8`.
  final double? elevation;

  /// Color of the selected item. Falls back to theme defaults.
  final Color? selectedItemColor;

  /// Color of unselected items. Falls back to theme defaults.
  final Color? unselectedItemColor;

  /// Whether to show labels for unselected items. Defaults to `true`.
  final bool showUnselectedLabels;

  /// Bar type – [BottomNavigationBarType.fixed] (default) or `.shifting`.
  final BottomNavigationBarType type;

  // ── Tap Handler ───────────────────────────────────────────────────────────

  /// Handles tab taps:
  /// - **Same tab** → pops the branch to its root (initial location).
  /// - **Different tab** → switches to that branch preserving its state.
  void _onItemTapped(int index) {
    if (index == navigationShell.currentIndex) {
      // Pop the entire branch navigator back to its
      // root route. This matches standard iOS/Android behaviour.
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(index);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveTheme =
        themeData ?? Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBarTheme(
        data: effectiveTheme,
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onItemTapped,
          backgroundColor: backgroundColor ?? effectiveTheme.backgroundColor,
          elevation: elevation ?? effectiveTheme.elevation ?? 8,
          selectedItemColor:
              selectedItemColor ?? effectiveTheme.selectedItemColor,
          unselectedItemColor:
              unselectedItemColor ?? effectiveTheme.unselectedItemColor,
          showUnselectedLabels: showUnselectedLabels,
          type: type,
          items: List.generate(items.length, (i) {
            final item = items[i];
            final badgeWidget = badgeBuilder?.call(i);

            Widget iconWidget = Icon(item.icon);
            Widget activeIconWidget = Icon(item.activeIcon ?? item.icon);

            if (badgeWidget != null) {
              iconWidget = Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  Positioned(right: -6, top: -6, child: badgeWidget),
                ],
              );
              activeIconWidget = Stack(
                clipBehavior: Clip.none,
                children: [
                  activeIconWidget,
                  Positioned(right: -6, top: -6, child: badgeWidget),
                ],
              );
            }

            return BottomNavigationBarItem(
              icon: iconWidget,
              activeIcon: activeIconWidget,
              label: item.label,
              tooltip: item.tooltip ?? item.label,
            );
          }),
        ),
      ),
    );
  }
}
