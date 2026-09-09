# Migration guide

Convert existing localization files into Sway's `.sway.json` format.

```bash
dart run sway:migrate --from <arb|easy_localization|slang> \
  --input <source_dir> \
  --output <dest_dir> \
  [--dry-run] [--force] [--nest-on-prefix]
```

**Always run `--dry-run` first.** The CLI never overwrites the source directory.

## ARB / Flutter gen-l10n

```bash
dart run sway:migrate --from arb --input lib/l10n --output lib/i18n --dry-run
dart run sway:migrate --from arb --input lib/l10n --output lib/i18n
```

| ARB | Sway |
|-----|------|
| `app_en.arb` | `en.sway.json` |
| `@key` metadata | Dropped (placeholders inferred from `{name}`) |
| `{count, plural, one{…} other{…}}` | `{ "one": "…", "other": "…" }` |
| Exact forms `=0` / `=1` / `=2` | Mapped to `zero` / `one` / `two` |
| Other exact forms (`=3`, …) | Left as string + “Needs manual conversion” |
| `{sex, select, …}` | Left as string + listed under “Needs manual conversion” |
| Flat `home_title` | Flat key, or nest with `--nest-on-prefix` → `home.title` |

Then:

```bash
dart run sway:codegen --input lib/i18n --output lib/i18n/sway.g.dart
```

## easy_localization

JSON files are supported directly:

```bash
dart run sway:migrate --from easy_localization --input assets/translations --output lib/i18n
```

- Nested maps copy through.
- Positional `{}` / `{0}` become `{arg1}`, `{arg2}` (rename for clarity — warned in the report).
- YAML/CSV: convert to JSON first (v0.1.0 keeps zero extra dependencies).

## slang

```bash
dart run sway:migrate --from slang --input lib/i18n --output lib/i18n_migrated
```

- `$name` → `{name}`
- Plural maps copy through when they already use CLDR category keys
- slang-only context/enum variants are flagged for manual cleanup

## Safety flags

| Flag | Behavior |
|------|----------|
| `--dry-run` | Report only; write nothing |
| `--force` | Allow writing into a non-empty output dir that already has `*.sway.json` |
| `--nest-on-prefix` | ARB: split `foo_bar` keys into nested `foo.bar` |

If the output directory already has Sway files and you omit `--force`, the CLI exits non-zero.

## After migration

1. Open the report: fix any “Needs manual conversion” keys.
2. Align all locales to the base locale schema (`baseLocale` in `sway.config.json`).
3. Run `dart run sway:codegen`.
4. Swap call sites to `context.t.…` (see [INTEGRATION.md](INTEGRATION.md)).
