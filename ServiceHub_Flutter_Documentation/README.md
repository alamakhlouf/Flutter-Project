# ServiceHub Flutter documentation

This pack defines the Flutter mobile app, ordered member assignments, project context, design-system setup, and a Spring Boot backend-generation prompt.

## Flutter setup

Requires the Flutter stable SDK. From the project root, fetch dependencies and run the app:

```powershell
flutter pub get
flutter run
```

The app's API base URL is centralized in `lib/core/config/app_config.dart`. Override the local default without editing source files by passing a Dart define:

```powershell
flutter run --dart-define="API_BASE_URL=http://10.0.2.2:8080"
```

Use the Spring Boot host's LAN IP instead of `10.0.2.2` on a physical Android device; the backend must be reachable over the network and allow the device through any firewall. iOS simulators can generally use `http://localhost:8080`. Do not put credentials or other secrets in Dart defines.

Android debug and profile builds allow cleartext HTTP so a local API can be reached. Release builds do not. The app needs the `INTERNET` permission, which is declared in the main manifest.

## Authentication

On launch the app reads the stored JWT and calls `GET /api/auth/me`. Customers, providers, and suppliers continue into the app. An administrator is stopped with: "Administration will be available through the web backoffice." Registration offers only Customer, Service provider, and Supplier.

The token is stored in platform secure storage and attached as `Authorization: Bearer` by `ApiClient`. Passwords and tokens are not written to logs. Log out deletes the stored token. Local seeded accounts, when the backend local profile is enabled, are documented with the API and must not be used in production.

## Profile

My profile loads `GET /api/users/me`. Customers, providers, and suppliers can update their name, phone, and profile image link with `PUT /api/users/me`. Email and role are shown and cannot be changed. A supplier edits the stored name as the business name. The API stores an image link, not an uploaded file. Log out on the profile screen uses the same session service as sign-in.

The shared Inter typography and ServiceHub color palette are in `lib/design_system/` and are applied by the app theme. Inter is loaded through `google_fonts` during development, so the first load may require internet access.

Run the widget tests and static analysis with:

```powershell
flutter test
flutter analyze
```

## Feature order
1. Authentication & role-based access — Member 1
2. User profiles — Member 2
3. Services & catalog — Member 3
4. Inventory management — Member 4
5. Service booking & requests — Member 5
6. Supplier & product orders — Member 6
7. Workshops — Member 7
8. Reviews & report submission — Member 8
9. Dashboards & notifications — Member 9

Complete shared setup first. Each member should work on a feature branch, pull the latest shared branch, test their feature, and submit a pull request. Agree on API contracts and shared-file ownership before parallel work.

## Mobile/backoffice boundary
Flutter is for customers, providers, and suppliers. Mobile users can submit reports. Admin report listing, review, assignment, resolution, dismissal, and moderation belong to a future web backoffice. Do not build an admin reports screen or admin dashboard in Flutter.
