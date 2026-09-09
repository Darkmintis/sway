<p align="center">
  <img src="branding/app_logo.png" alt="Darkmintis" width="120" />
</p>

<h1 align="center">BasePackage Flutter</h1>

<p align="center">
  Darkmintis Flutter pub.dev package template (v0.1.0). Package + example + CI + tag-based publish.
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

[![pub package](https://img.shields.io/pub/v/basepackage.svg)](https://pub.dev/packages/basepackage)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Private Darkmintis template for bootstrapping new Flutter pub.dev packages.

## What this gives you

- Package + example + test structure
- CI checks (format, analyze, test, pana score)
- Tag-based GitHub Release workflow
- Tag-based pub.dev publish workflow
- Example Android config with `compileSdk = 36` and `targetSdk = 36`

## Quick start

1. Clone this repo
2. Rename package in `pubspec.yaml` and remove `publish_to: none`
3. Replace `lib/` with your real package API
4. Update `example/` and `test/`
5. Push to public GitHub and enable automated publishing on pub.dev
6. Release with:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## Run locally

- Use `.vscode/launch.json` to run the example app
- Run tests:

```bash
flutter test
cd example && flutter test
```

## Branding

Lighter than BaseApp — packages only need logo + screenshots:

| File | Purpose |
|---|---|
| `app_logo.png` | Darkmintis mark — README header |
| `ss1.png` … `ss5.png` | Example / pub.dev screenshots (sample placeholders; replace per package) |

No feature graphic or store frames — those are for Play Store apps, not pub.dev packages.

## License

MIT — see [LICENSE](LICENSE).

<p align="center">© Darkmintis</p>
