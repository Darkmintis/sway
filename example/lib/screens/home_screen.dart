import 'package:flutter/material.dart';

import '../i18n/sway.g.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  const HomeScreen({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: const [
          _HomeTab(),
          SettingsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: onTabChanged,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.app.title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.settings.title,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: t.profile.title,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _itemCount = 1;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.app.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            t.app.subtitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.home.welcome(name: 'Dipesh'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(t.home.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            t.home.overlayHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.home.itemCount(count: _itemCount),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed:
                    _itemCount > 0 ? () => setState(() => _itemCount--) : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Slider(
                  value: _itemCount.toDouble().clamp(0, 20),
                  min: 0,
                  max: 20,
                  divisions: 20,
                  label: '$_itemCount',
                  onChanged: (v) => setState(() => _itemCount = v.round()),
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    _itemCount < 20 ? () => setState(() => _itemCount++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t.home.messageCount(count: _itemCount),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            t.profile.memberSince(date: '2024'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
