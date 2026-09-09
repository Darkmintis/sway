import 'package:flutter/material.dart';

import '../main.dart';

class SettingsScreen extends StatelessWidget {
  final dynamic t;
  final Locale locale;
  const SettingsScreen({super.key, required this.t, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isEn = locale.languageCode == 'en';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(t.settingsLanguage),
          subtitle: Text(isEn ? 'English' : 'العربية'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguagePicker(context),
        ),
        const ListTile(leading: Icon(Icons.dark_mode), title: Text('Dark Mode'), subtitle: Text('Off')),
        const ListTile(leading: Icon(Icons.notifications), title: Text('Notifications'), subtitle: Text('On')),
        const Divider(),
        ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text(t.settingsLogout, style: const TextStyle(color: Colors.red))),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final current = locale.languageCode;
    final state = context.findAncestorStateOfType<ExampleAppState>();
    if (state == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(t.settingsLanguage, style: Theme.of(context).textTheme.titleLarge)),
            ListTile(
              leading: const Text('English', style: TextStyle(fontSize: 18)),
              trailing: current == 'en' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                state.adapter.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('العربية', style: TextStyle(fontSize: 18)),
              trailing: current == 'ar' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                state.adapter.setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
