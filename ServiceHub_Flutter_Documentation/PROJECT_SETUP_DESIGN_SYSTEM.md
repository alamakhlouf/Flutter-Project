# Flutter Project Setup & Design System

This document defines shared Flutter setup and the design system's **colors and fonts only**.

## 1. Setup
- Create a stable Flutter app; commit `pubspec.yaml` and `pubspec.lock`.
- Keep secrets/environment-specific values out of source control.
- Keep API base URL in one config file.
- Verify emulator and physical-device connectivity to local Spring Boot.
- Document setup/run instructions.

Suggested packages only when needed: `http` or `dio`; secure storage for JWT; `shared_preferences` for non-sensitive preferences; `image_picker`; `cached_network_image`; `intl`; `google_fonts` for Inter during development. Bundle Inter font files for offline production if needed.

## 2. Suggested structure
```text
lib/
  main.dart
  app/
    app.dart
    app_routes.dart
  core/
    config/app_config.dart
    network/api_client.dart
    network/api_exception.dart
    storage/token_storage.dart
    utils/validators.dart
    widgets/
  design_system/
    app_colors.dart
    app_fonts.dart
    app_text_styles.dart
  features/
    auth/
    profile/
    services/
    inventory/
    bookings/
    supplier_orders/
    workshops/
    reviews_reports/
    dashboard/
```
Each feature may contain `models/`, `services/`, `screens/`, and `widgets/`. Do not add empty layers.

## 3. State management
Use Flutter's built-in `setState` only.
- Screen-local state belongs in the screen's State class.
- Use setState for loading, forms, filters, and local UI state.
- Keep API calls in service classes, never in build().
- Use initState() for initial loading where appropriate.
- Check mounted before calling setState after async work.
- Do not introduce Bloc, Cubit, Provider, Riverpod, GetX, Redux, or similar packages.
- Avoid global mutable state; centralize session/token access in a small service.

## 4. Official brand palette
Use these exact base colors:

| Token | Name | HEX |
|---|---|---|
| primary | Deep Navy Blue | `#163B60` |
| secondary | Terracotta Orange | `#E05A36` |
| tertiary | Amber Yellow | `#F59E0B` |
| neutral | Warm Off-White | `#F5F3EF` |

Usage:
- Navy: brand identity, key headings, selected navigation, structural emphasis.
- Terracotta: prominent calls to action and selective highlights; not every button/card.
- Amber: small highlights, ratings, attention indicators; avoid large surfaces.
- Warm off-white: page background and subtle surfaces.
- White: elevated cards and form surfaces where useful.
- Neutral surfaces should dominate. Check foreground/background contrast; do not assume white text works on every brand color.

Functional semantic colors, separate from brand colors:

| Token | HEX | Usage |
|---|---|---|
| success | `#287A4B` | completed/successful |
| warning | `#A96608` | pending attention/low stock |
| error | `#C43D35` | errors/rejected/destructive |
| info | `#39769A` | informational |
| textPrimary | `#263238` | main text |
| textSecondary | `#667078` | supporting text |
| border | `#E5E0D8` | borders/dividers |
| surface | `#FFFFFF` | cards/elevated surfaces |

Status must never be communicated by color alone; pair it with text or an icon.

## 5. Fonts
Use **Inter** throughout.
- Inter Regular 400: body text.
- Inter Medium 500: labels/supporting emphasis.
- Inter SemiBold 600: buttons, card titles, section headings.
- Inter Bold 700: page titles and major headings.

Suggested sizes: display 30–32; page title 24; section title 20; card title 16; body 14–16; supporting 12–13; metadata 11–12.

Use `google_fonts` with Inter during development or bundle Inter font files for offline production.

## 6. Implementation
Create `AppColors`, `AppFonts`, shared text styles, and one shared `ThemeData` applied through `MaterialApp`. Do not hardcode competing colors/font families in feature screens.
