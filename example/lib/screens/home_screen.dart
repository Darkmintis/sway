import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final dynamic t;
  final Locale locale;
  const HomeScreen({super.key, required this.t, required this.locale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(t: t),
          SettingsScreen(t: t, locale: widget.locale),
          ProfileScreen(t: t),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.appTitle),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: t.settingsTitle),
          NavigationDestination(icon: const Icon(Icons.person_outlined), selectedIcon: const Icon(Icons.person), label: t.profileTitle),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic t;
  const _HomeTab({required this.t});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.homeWelcome(name: 'Dipesh'), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(t.homeDescription),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pluralization', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('1: ${t.itemCountOne(count: 1)}'),
                Text('5: ${t.itemCountOther(count: 5)}'),
                Text('100: ${t.itemCountOther(count: 100)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }
}
