import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// RouteArchitectExtensions – Navigation Context Extensions
// ---------------------------------------------------------------------------

/// Convenience navigation extensions for `BuildContext`.
///
/// These extensions complement `go_router`'s built-in `context.go()` /
/// `context.push()` methods with intent-revealing helpers specifically
/// designed for the **"Push → Select → Pop Result"** enterprise pattern,
/// where Screen A opens Screen B to collect typed data and receives it back
/// without casting at the caller. Use the same result type on both screens;
/// Dart cannot check that separate push and pop calls agree.
///
/// ## The Enterprise "Push & Custom Pop" Pattern
///
/// ### Step 1 – Screen A pushes Screen B and awaits a typed result
/// ```dart
/// // In HomeScreen (Screen A):
/// final address = await context.architectPush<ShippingAddress>(
///   '/home/address-picker',
/// );
/// if (address != null) {
///   setState(() => _selectedAddress = address);
/// }
/// ```
///
/// ### Step 2 – Screen B pops and returns the typed result
/// ```dart
/// // In AddressPickerScreen (Screen B):
/// ElevatedButton(
///   onPressed: () => context.architectPop(selectedAddress),
///   child: const Text('Confirm'),
/// )
/// ```
///
/// Match the push type to the value returned by the pop call.
extension RouteArchitectExtensions on BuildContext {
  // ── Pop with Return Data ─────────────────────────────────────────────────

  /// Pops the current route and passes [result] back to the awaiting caller.
  ///
  /// This is the **return half** of the "Push & Custom Pop" pattern.
  /// [T] checks the value passed to this call. The caller's push type must
  /// match it; separate screens are not checked against each other.
  ///
  /// ### Usage – the picker / selector screen (Screen B)
  /// ```dart
  /// context.architectPop(ShippingAddress(city: 'Bangkok', street: '...'));
  /// ```
  ///
  void architectPop<T extends Object?>(T result) => pop<T>(result);

  // ── Push and Await Return Data ───────────────────────────────────────────

  /// Pushes [location] onto the navigator stack and **awaits a typed return
  /// value** from the pushed screen.
  ///
  /// This is the **call half** of the "Push & Custom Pop" pattern.
  /// Returns `null` if the user pops without selecting (back button / swipe).
  ///
  /// ### Usage – the initiator screen (Screen A)
  /// ```dart
  /// final address = await context.architectPush<ShippingAddress>(
  ///   '/home/address-picker',
  /// );
  /// if (address != null) setState(() => _selectedAddress = address);
  /// ```
  ///
  /// ### With extra payload (pass query data to the picker)
  /// ```dart
  /// final filter = await context.architectPush<SearchFilter>(
  ///   '/filter-picker',
  ///   extra: FilterOptions(category: 'electronics'),
  /// );
  /// ```
  Future<T?> architectPush<T extends Object?>(
    String location, {
    Object? extra,
  }) =>
      push<T>(location, extra: extra);

  // ── Push Named and Await Return Data ─────────────────────────────────────

  /// Named-route variant of [architectPush] for routes with path parameters.
  ///
  /// Equivalent to `context.pushNamed<T>` but intent-revealing and aligned
  /// with the `architectPush` / `architectPop` naming convention.
  ///
  /// ### Usage
  /// ```dart
  /// final product = await context.architectPushNamed<Product>(
  ///   'product-picker',
  ///   queryParameters: {'category': 'electronics'},
  /// );
  /// ```
  Future<T?> architectPushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) =>
      pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
}
