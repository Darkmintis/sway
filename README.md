<p align="center">
  <img src="branding/app_logo.png" alt="Sway" width="120" />
</p>

<h1 align="center">Sway</h1>

<p align="center">
  The localization layer for Flutter — simple to author, instant to test, painless to migrate into.
</p>

<p align="center">
  <table>
    <tr>
      <td align="center" width="20%"><img src="branding/ss1.png" alt="Screenshot 1" width="100%" /></td>
      <td align="center" width="20%"><img src="branding/ss2.png" alt="Screenshot 2" width="100%" /></td>
      <td align="center" width="20%"><img src="branding/ss3.png" alt="Screenshot 3" width="100%" /></td>
      <td align="center" width="20%"><img src="branding/ss4.png" alt="Screenshot 4" width="100%" /></td>
      <td align="center" width="20%"><img src="branding/ss5.png" alt="Screenshot 5" width="100%" /></td>
    </tr>
  </table>
</p>

[![pub package](https://img.shields.io/pub/v/sway.svg)](https://pub.dev/packages/sway)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Type-safe Flutter localization with an instant in-app locale switcher and zero-friction migration from ARB, easy_localization, and slang.

## Features

- **Format + Codegen** — write plain JSON per locale, get type-safe Dart accessors
- **Overlay** — floating debug widget to switch locale and force RTL/LTR preview instantly
- **Migration CLI** — one-shot conversion from ARB, easy_localization, or slang formats
- CLDR plural rules, RTL table, cross-locale validation

## Quickstart

```dart
// 1. Create locale files: lib/i18n/en.sway.json, lib/i18n/ar.sway.json
// 2. Generate code:
//    dart run sway:codegen
// 3. Use in your app:
import 'package:sway/sway.dart';

// Generated output gives you:
// Text(t.home.welcome(name: 'Dipesh'));
// Text(t.home.itemCount(count: cartItems.length));
```

## Locale File Format

```json
{
  "home": {
    "title": "Home",
    "welcome": "Welcome, {name}!",
    "itemCount": {
      "one": "{count} item",
      "other": "{count} items"
    }
  }
}
```

## Commands

```bash
# Generate Dart code from .sway.json files
dart run sway:codegen

# Migrate from other formats
dart run sway:migrate --from arb --input lib/l10n
dart run sway:migrate --from easy_localization --input lib/translations
dart run sway:migrate --from slang --input lib/i18n
```

## Testing

```bash
flutter test
```

## License

MIT — see [LICENSE](LICENSE).

<p align="center">© Darkmintis</p>
