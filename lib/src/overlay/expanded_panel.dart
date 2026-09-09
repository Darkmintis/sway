/// The expanded locale-switching panel for the Sway overlay.
library;

import 'package:flutter/material.dart';

import 'overlay_controller.dart';

/// A compact panel listing all detected locales with a search field
/// (when count > 8) and a manual RTL force-toggle.
class ExpandedPanel extends StatefulWidget {
  /// The overlay controller managing locale state.
  final OverlayController controller;

  /// Callback when the panel should be collapsed.
  final VoidCallback onCollapse;

  /// Creates an [ExpandedPanel].
  const ExpandedPanel({
    super.key,
    required this.controller,
    required this.onCollapse,
  });

  @override
  State<ExpandedPanel> createState() => _ExpandedPanelState();
}

class _ExpandedPanelState extends State<ExpandedPanel> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final locales = controller.supportedLocales;
    final filteredLocales = _searchQuery.isEmpty
        ? locales
        : locales
            .where((l) =>
                l.languageCode.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Sway',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.onCollapse,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Search (only when > 8 locales)
            if (locales.length > 8)
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search locales...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

            // Locale list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredLocales.length,
                itemBuilder: (context, index) {
                  final locale = filteredLocales[index];
                  final isActive = locale == controller.currentLocale;

                  return ListTile(
                    dense: true,
                    title: Text(
                      _localeDisplayName(locale),
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => controller.setLocale(locale),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // RTL/LTR force toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Text('RTL:', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Switch(
                    value: controller.forceRtl,
                    onChanged: (v) => controller.setForceRtl(v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearForceDirection,
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localeDisplayName(Locale locale) {
    const names = {
      'en': 'English',
      'ar': 'العربية',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
      'ko': '한국어',
      'hi': 'हिन्दी',
      'tr': 'Türkçe',
    };
    return names[locale.languageCode] ?? locale.languageCode;
  }
}
