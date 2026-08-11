# Design system

The app uses a **vibrant gradient + glassmorphism** style — a dark navy/indigo gradient backdrop (light mode: soft cloud gradient) with frosted glass surfaces floating on top. Chosen to feel like a modern security/surveillance product (Ring, Nest, UniFi Protect) rather than a generic Material app. See `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`, `lib/widgets/gradient_background.dart`, `lib/widgets/glass_card.dart`.

## Color

All colors are named tokens in `lib/theme/app_colors.dart` — change the look by editing there, not by hardcoding colors in screens.

| Token | Hex | Use |
|---|---|---|
| `indigo` | `#5B6EF5` | Primary brand accent — buttons, active tab indicator, links, selected nav icon |
| `cyan` | `#22D3EE` | Secondary accent — paired with indigo in gradients (tab indicator, camera thumbnail placeholder) |
| `online` | `#34D399` (green) | Semantic status — camera online, independent of brand accent |
| `offline` | `#FB7185` (coral/red) | Semantic status — camera offline |
| `darkBase` | `#0B1120` | Dark theme background base |
| `darkMid` | `#141B33` | Dark theme gradient highlight (top-left glow) |
| `darkGlass` | `#1B2340` | Dark theme `surfaceContainerHighest` |
| `lightBase` | `#F4F6FB` | Light theme background base |
| `lightMid` | `#E7ECFB` | Light theme gradient highlight (top-left glow) |
| `lightGlass` | `#FFFFFF` | Light theme `surfaceContainerHighest` |

Both `indigo` and `cyan` seed a Material 3 `ColorScheme.fromSeed` (`AppTheme.light()` / `AppTheme.dark()`), so all derived roles (`primary`, `onPrimary`, `surfaceVariant`, etc.) come from those two seeds rather than being hand-picked per-widget.

Status colors (`online`/`offline`) are always used directly from `AppColors`, never derived from the theme — they must stay legible and consistent regardless of brand accent changes.

## Backgrounds: gradient mesh

`GradientBackground` (`lib/widgets/gradient_background.dart`) wraps every screen's `Scaffold`. It paints a `RadialGradient` centered top-left (`Alignment(-0.7, -0.9)`, radius `1.6`):

- **Dark:** `darkMid → darkBase → black`, stops `[0.0, 0.55, 1.0]`
- **Light:** `lightMid → lightBase → lightBase`, stops `[0.0, 0.55, 1.0]`

Every `Scaffold` sets `backgroundColor: Colors.transparent` and is itself wrapped in `GradientBackground`, so the gradient shows through the AppBar and bottom nav bar too — not just the body. (Wrap the whole `Scaffold`, not just `body:` — wrapping only the body leaves the AppBar/nav-bar area painting over plain black, which was a real bug fixed during development.)

## Surfaces: glassmorphism

`GlassCard` (`lib/widgets/glass_card.dart`) is the frosted-glass container used everywhere a Card/Container would otherwise sit on the gradient — login/signup forms, camera tiles, home rows in Manage Homes.

- **Blur:** `BackdropFilter` with `ImageFilter.blur(sigmaX: 24, sigmaY: 24)`
- **Fill:** `Colors.white` at 6% opacity (dark) / 55% opacity (light)
- **Border:** `Colors.white` at 12% opacity (dark) / 70% opacity (light)
- **Shadow:** black at 35% opacity (dark) / indigo (`#5B6EF5`) at 8% opacity (light), `blurRadius: 32`, `offset: (0, 12)`
- **Corner radius:** 20px default (`borderRadius` param), 16px for smaller elements like list rows and camera tiles

The light-mode shadow being tinted indigo (not black) is deliberate — a plain black shadow on a light background reads as dirty; a brand-tinted shadow reads as a considered choice.

## Typography

Two typefaces, bundled locally as assets (`assets/fonts/`, declared in `pubspec.yaml`) rather than fetched at runtime, for offline reliability:

- **Manrope** (variable font) — headings, AppBar titles, button labels, tab labels, nav bar labels. Bold, geometric, gives the UI personality. Weights used: 500–800.
- **Inter** — body text, form field text, everything else. Chosen for proven legibility at small sizes in dense UI, not as a "safe default."

Type scale (defined in `AppTheme._themeFrom`, `lib/theme/app_theme.dart`):

| Style | Font | Size | Weight |
|---|---|---|---|
| `headlineMedium` | Manrope | 30 | 800 |
| `headlineSmall` | Manrope | 26 | 800 |
| AppBar title | Manrope | 22 | 800 |
| `titleLarge` | Manrope | 20 | 700 |
| `titleMedium` | Manrope | (default) | 700 |
| Button/tab labels | Manrope | 16 | 700 |
| `bodyMedium` | Inter | (default) | height 1.4 |

## Components

- **Buttons:** `ElevatedButton` = solid `primary` fill, white text, 16px radius, no elevation (flat, relies on the glass/gradient context for depth), 52px min height. `OutlinedButton` = transparent fill, theme-aware border (white 16% dark / black 10% light).
- **Inputs:** filled style, white fill at low opacity (6% dark / 60% light), 16px radius, no border until focused (then 1.6px `primary` border).
- **Tabs:** active indicator is a **gradient pill** (`primary → cyan` `LinearGradient`), not a flat underline or fill — one of the few places the two accent colors appear together directly.
- **Bottom navigation:** floating glass bar (`NavigationBarThemeData`, white 6%/70% fill matching `GlassCard`'s tone), selected icon renders white inside the `primary`-colored indicator pill.
- **Camera tiles:** thumbnail image fills the card; name + status dot + favorite star are overlaid directly on the image with a bottom gradient scrim (`Colors.transparent → Colors.black45`) for legibility, not placed in a separate text row below the image.
- **Status dots:** 8px circle, `online`/`offline` color, with a matching-color glow (`BoxShadow`, same color at 60–70% opacity, `blurRadius: 6`) — a plain filled dot looked flat without it.

## Layout conventions

- Screen content padding: 16px standard (`EdgeInsets.all(16)`) for lists/grids.
- Card-to-card spacing: 12–16px.
- Full-width single-column camera list (not a 2-up grid) — an earlier 2-column grid was replaced per user feedback in favor of larger, more legible cards.
- Every screen route-level widget is documented individually in `docs/screens/` with stable design IDs (`<SCREEN-PREFIX>-NNN`) per the project's screen-documentation rule (see root `CLAUDE.md`) — this file describes the shared visual language those screens are built from, not screen-specific layout.

## Design direction rationale

Chosen over alternatives (bold flat color, warm minimal/soft-depth) because:
- The subject (CCTV/security monitoring) benefits from a "techy," slightly high-tech feel that glassmorphism + gradient naturally conveys.
- Camera thumbnails are the primary content — floating glass cards let imagery read as the focal point rather than competing with heavy chrome.
- Both light and dark themes are fully designed (not a dark-only commitment) since users expect standard OS-level theme switching, with a persisted in-app override (`ThemeController`, cycles System → Light → Dark).
