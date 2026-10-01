# route_architect example

Run this app with Flutter 3.22 or newer:

```bash
cd example
flutter pub get
flutter run
```

The app starts at Login. Choose **Login as Member** or **Login as Admin** to
enter the three-tab shell. On Home, try the address picker for a typed result,
open a nested detail route, and test the admin guard. Tap the active tab to
return to its root. Log out from Home or Profile to see the auth guard react.

Run the example checks with `flutter analyze` and `flutter test` from this
directory.
