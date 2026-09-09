import 'package:flutter/material.dart';
import 'package:sway/sway.dart';

import 'i18n/sway.g.dart';

void main() {
  runApp(const ExampleApp());
}

/// Example app demonstrating Sway localization with overlay.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sway Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const SwayOverlay(
        child: HomeScreen(),
      ),
    );
  }
}

/// Home screen showing Sway translations in action.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final t = SwayTranslations.en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(t: t),
          _SettingsTab(t: t),
          _ProfileTab(t: t),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.settingsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.settingsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: t.profileTitle,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final SwayTranslationsEn t;
  const _HomeTab({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(t.appTitle)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.homeWelcome(name: 'Dipesh'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(t.homeDescription),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pluralization', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('0: No items'),
                      Text('1: ${t.itemCountOne}'),
                      Text('5: ${t.itemCountOther(count: 5)}'),
                      Text('100: ${t.itemCountOther(count: 100)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Placeholders', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(t.profileMemberSince(date: '2024')),
                      Text(t.messageCountOther(count: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Overlay', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Tap the floating bubble to switch locales.'),
                      const Text('Drag the bubble to move it.'),
                      const Text('Use the RTL toggle to preview right-to-left layout.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final SwayTranslationsEn t;
  const _SettingsTab({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(t.settingsTitle)),
        SliverList.list(
          children: [
            _SettingsTile(icon: Icons.language, title: t.settingsLanguage, subtitle: 'English'),
            _SettingsTile(icon: Icons.dark_mode, title: t.settingsDarkMode, subtitle: 'Off'),
            _SettingsTile(icon: Icons.notifications, title: t.settingsNotifications, subtitle: 'On'),
            const Divider(),
            _SettingsTile(icon: Icons.logout, title: t.settingsLogout, subtitle: '', color: Colors.red),
          ],
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final SwayTranslationsEn t;
  const _ProfileTab({required this.t});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(t.profileTitle)),
        SliverList.list(
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 16),
            Center(
              child: Text(t.profileName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const Center(child: Text('Darkmintis', style: TextStyle(fontSize: 16, color: Colors.grey))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    _ProfileTile(icon: Icons.person, title: t.profileName, value: 'Dipesh Mahat'),
                    const Divider(height: 1),
                    _ProfileTile(icon: Icons.email, title: t.profileEmail, value: 'dipesh@darkmintis.com'),
                    const Divider(height: 1),
                    _ProfileTile(icon: Icons.calendar_today, title: t.profileMemberSince(date: '2024'), value: ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(onPressed: () {}, child: Text(t.profileEditProfile)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _ProfileTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: value.isNotEmpty ? Text(value, style: const TextStyle(color: Colors.grey)) : null,
    );
  }
}
