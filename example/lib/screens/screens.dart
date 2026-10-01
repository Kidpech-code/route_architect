import 'package:flutter/material.dart';
import 'package:route_architect/route_architect.dart';

import '../auth/auth_notifier.dart';

// ---------------------------------------------------------------------------
// ShippingAddress – Domain model used in the Push & Custom Pop demo
// ---------------------------------------------------------------------------

/// Immutable value object returned by [AddressPickerScreen].
///
/// Demonstrates type-safe return data: `context.architectPop<ShippingAddress>()`
/// encodes the return type at the call-site so the compiler rejects wrong types.
@immutable
class ShippingAddress {
  const ShippingAddress(
      {required this.label,
      required this.street,
      required this.city,
      required this.postcode});

  final String label;
  final String street;
  final String city;
  final String postcode;

  @override
  String toString() => '$label · $street, $city $postcode';
}

/// Sample addresses shown in [AddressPickerScreen].
const _kSampleAddresses = [
  ShippingAddress(
      label: 'Home',
      street: '88 Sukhumvit Rd',
      city: 'Bangkok',
      postcode: '10110'),
  ShippingAddress(
      label: 'Office',
      street: '14 Silom Complex',
      city: 'Bangkok',
      postcode: '10500'),
  ShippingAddress(
      label: 'Warehouse',
      street: '321 Lat Krabang Industrial,',
      city: 'Bangkok',
      postcode: '10520'),
  ShippingAddress(
      label: 'Parent\'s House',
      street: '7 Nimman Rd',
      city: 'Chiang Mai',
      postcode: '50200'),
];

// ---------------------------------------------------------------------------
// Login Screen
// ---------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authNotifier});
  final AuthNotifier authNotifier;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _loginAsMember() async {
    setState(() => _loading = true);
    await widget.authNotifier.login(email: 'member@example.com');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loginAsAdmin() async {
    setState(() => _loading = true);
    await widget.authNotifier
        .login(email: 'admin@example.com', role: UserRole.admin);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                      onPressed: _loginAsMember,
                      child: const Text('Login as Member')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: _loginAsAdmin,
                      child: const Text('Login as Admin')),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authNotifier});
  final AuthNotifier authNotifier;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State for the Push & Custom Pop demo ───────────────────────────────
  ShippingAddress? _selectedAddress;

  /// Pushes [AddressPickerScreen] and awaits the user's selection.
  ///
  /// Uses `context.architectPush<ShippingAddress>` for a typed result.
  Future<void> _pickAddress() async {
    final result =
        await context.architectPush<ShippingAddress>('/home/address-picker');
    // result is null when the user presses the system back button.
    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authNotifier.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.authNotifier.logout,
              tooltip: 'Logout')
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, ${user?.displayName ?? 'Guest'}!',
                style: Theme.of(context).textTheme.headlineSmall),
            Text('Role: ${user?.role.name ?? 'none'}'),
            const SizedBox(height: 24),

            // ── Push & Custom Pop Demo ─────────────────────────────────
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Push & Await Typed Return',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress != null
                          ? '📦  ${_selectedAddress.toString()}'
                          : 'No address selected yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Pick Shipping Address'),
                      // ① Screen A pushes Screen B and awaits a typed result.
                      //   context.architectPush<ShippingAddress>() returns
                      //   Future<ShippingAddress?>. Screen B must pop the
                      //   same type.
                      onPressed: _pickAddress,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => context.go('/home/detail/42'),
                child: const Text('Open Detail (Deep Nest)')),
            const SizedBox(height: 8),
            if (user?.isAdmin ?? false)
              ElevatedButton(
                  onPressed: () => context.go('/admin'),
                  child: const Text('Go to Admin Panel')),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Try Admin (non-admin redirect test)')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail Screen (deeply nested within Home branch)
// ---------------------------------------------------------------------------

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail #$id')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Viewing item $id'),
            const SizedBox(height: 16),
            const Text(
              'Tip: tap the Home tab again to pop back to the root.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Screen
// ---------------------------------------------------------------------------

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: const Center(child: Text('Search Screen')),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Screen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.authNotifier});
  final AuthNotifier authNotifier;

  @override
  Widget build(BuildContext context) {
    final user = authNotifier.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 80),
            const SizedBox(height: 12),
            Text(user?.email ?? 'Not logged in'),
            Text('Role: ${user?.role.name ?? 'none'}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: authNotifier.logout),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin Screen
// ---------------------------------------------------------------------------

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.red.shade700),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.red),
            SizedBox(height: 12),
            Text('You have admin access! 🎉'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AddressPickerScreen – Screen B in the Push & Custom Pop demo
// ---------------------------------------------------------------------------

/// Presents a list of [ShippingAddress]es.
///
/// When the user taps one, calls `context.architectPop<ShippingAddress>(address)`
/// to return the typed value to the previous screen **without any cast**.
///
/// Screen A uses the same result type in its push call.
class AddressPickerScreen extends StatelessWidget {
  const AddressPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Shipping Address')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _kSampleAddresses.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final address = _kSampleAddresses[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(address.label),
            subtitle:
                Text('${address.street}, ${address.city} ${address.postcode}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // ② Screen B pops with a *typed* ShippingAddress.
              //   Keep this type in sync with Screen A's push call.
              context.architectPop<ShippingAddress>(address);
            },
          );
        },
      ),
    );
  }
}
