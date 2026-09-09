import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway/src/overlay/locale_adapter.dart';
import 'package:sway/src/overlay/overlay_controller.dart';

void main() {
  group('OverlayController', () {
    late SwayFormatAdapter adapter;
    late OverlayController controller;

    setUp(() {
      adapter = SwayFormatAdapter(
        supportedLocales: const [Locale('en'), Locale('ar')],
        currentLocale: const Locale('en'),
        onLocaleChange: (_) {},
      );
      controller = OverlayController(adapter: adapter);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes with adapter current locale', () {
      expect(controller.currentLocale, const Locale('en'));
      expect(controller.forceRtl, isFalse);
      expect(controller.forceLtr, isFalse);
      expect(controller.isExpanded, isFalse);
    });

    test('syncs when adapter locale changes outside the overlay', () {
      var notified = false;
      controller.addListener(() => notified = true);

      adapter.setLocale(const Locale('ar'));

      expect(controller.currentLocale, const Locale('ar'));
      expect(notified, isTrue);
    });

    test('setLocale changes current locale', () {
      controller.setLocale(const Locale('ar'));
      expect(controller.currentLocale, const Locale('ar'));
    });

    test('setLocale no-op for same locale', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setLocale(const Locale('en'));
      expect(notifyCount, 0);
    });

    test('toggleExpanded toggles panel state', () {
      controller.toggleExpanded();
      expect(controller.isExpanded, isTrue);

      controller.toggleExpanded();
      expect(controller.isExpanded, isFalse);
    });

    test('collapse closes panel', () {
      controller.toggleExpanded();
      expect(controller.isExpanded, isTrue);

      controller.collapse();
      expect(controller.isExpanded, isFalse);
    });

    test('setForceRtl enables RTL and disables LTR', () {
      controller.setForceRtl(true);
      expect(controller.forceRtl, isTrue);
      expect(controller.forceLtr, isFalse);
    });

    test('setForceLtr enables LTR and disables RTL', () {
      controller.setForceLtr(true);
      expect(controller.forceLtr, isTrue);
      expect(controller.forceRtl, isFalse);
    });

    test('clearForceDirection resets both flags', () {
      controller.setForceRtl(true);
      controller.clearForceDirection();
      expect(controller.forceRtl, isFalse);
      expect(controller.forceLtr, isFalse);
    });

    test('notifies listeners on state change', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setLocale(const Locale('ar'));
      expect(notified, isTrue);
    });
  });

  group('ManualAdapter', () {
    test('stores and returns locale state', () {
      final adapter = ManualAdapter(
        supportedLocales: const [Locale('en'), Locale('fr')],
        currentLocale: const Locale('en'),
        onLocaleChange: (_) {},
      );

      expect(adapter.currentLocale, const Locale('en'));
      expect(adapter.supportedLocales.length, 2);
    });

    test('setLocale invokes callback', () {
      Locale? changedTo;
      final adapter = ManualAdapter(
        supportedLocales: const [Locale('en'), Locale('fr')],
        currentLocale: const Locale('en'),
        onLocaleChange: (locale) => changedTo = locale,
      );

      adapter.setLocale(const Locale('fr'));
      expect(changedTo, const Locale('fr'));
    });
  });
}
