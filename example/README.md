# Sway example

Runnable demo for the [sway](https://pub.dev/packages/sway) package.

## Features shown

- Nested type-safe strings via `context.t`
- CLDR plurals with a live count slider
- Six locales: `en`, `ar`, `es`, `de`, `ja`, `he`
- RTL (Arabic + Hebrew)
- Draggable overlay with Force RTL/LTR
- Tab index preserved across locale changes

## Run

From the **package root**:

```bash
dart run sway:codegen --config example/lib/i18n/sway.config.json
cd example
flutter run
```

## Tips

- Drag the floating button; tap to open locales.
- Change language in **Settings** or via the overlay — both stay in sync.
- Hot **reload** keeps the forced locale; hot **restart** resets it.
