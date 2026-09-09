import 'package:flutter/material.dart';
import 'package:sway/sway.dart';

import '../i18n/sway.g.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  final SwayTranslations t;
  final Locale locale;

  const SettingsScreen({super.key, required this.t, required this.locale});

  @override
  Widget build(BuildContext context) {
    final meta = SwayLocaleMeta.fromLanguageCode(locale.languageCode);
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.settings.language),
            subtitle: Text(meta.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(t.settings.darkMode),
            subtitle: Text(t.settings.off),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(t.settings.notifications),
            subtitle: Text(t.settings.on),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              t.settings.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final state = context.findAncestorStateOfType<ExampleAppState>();
    if (state == null) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  t.settings.language,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final locale in SwayTranslations.supportedLocales)
                ListTile(
                  title: Text(
                    SwayLocaleMeta.fromLanguageCode(locale.languageCode)
                        .displayName,
                  ),
                  subtitle: Text(locale.languageCode),
                  trailing: locale.languageCode == this.locale.languageCode
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    state.adapter.setLocale(locale);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
