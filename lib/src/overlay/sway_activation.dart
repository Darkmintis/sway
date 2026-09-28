import 'package:flutter/foundation.dart';

/// Resolves whether the Sway overlay should run for a set of flags + build
/// mode. Same switch model as Mole and Ferret: `enabled` is the master switch,
/// `enableInRelease` opts in to release builds (with a loud warning).
class SwayActivation {
  /// Creates an activation snapshot for tests or custom wiring.
  const SwayActivation({
    required this.active,
    required this.showReleaseWarning,
  });

  /// Whether the floating bubble should render.
  final bool active;

  /// `true` only when Sway is active in a release build: print the console
  /// banner and show the red on-screen tag.
  final bool showReleaseWarning;

  /// Forces release-mode resolution in tests (`null` uses [kReleaseMode]).
  @visibleForTesting
  static bool? debugReleaseModeOverride;

  static bool _bannerPrinted = false;

  /// Compute activation. [debugOnly] additionally hides the bubble in profile
  /// builds.
  factory SwayActivation.resolve({
    bool enabled = true,
    bool enableInRelease = false,
    bool debugOnly = false,
    bool? isReleaseMode,
    bool? isDebugMode,
  }) {
    const off = SwayActivation(active: false, showReleaseWarning: false);
    if (!enabled) return off;

    final release = isReleaseMode ?? debugReleaseModeOverride ?? kReleaseMode;
    if (release) {
      if (!enableInRelease || debugOnly) return off;
      return const SwayActivation(active: true, showReleaseWarning: true);
    }
    if (debugOnly && !(isDebugMode ?? kDebugMode)) return off;
    return const SwayActivation(active: true, showReleaseWarning: false);
  }

  /// Prints the release banner once per process.
  static void printReleaseWarningOnce() {
    if (_bannerPrinted) return;
    _bannerPrinted = true;
    debugPrint('''
╔════════════════════════════════════════════════════╗
║  ⚠️  SWAY IS ACTIVE IN A RELEASE BUILD              ║
║  You explicitly set enableInRelease: true.          ║
║  Anyone with this build can switch the app locale   ║
║  and force RTL/LTR. Disable before shipping.        ║
╚════════════════════════════════════════════════════╝''');
  }

  /// Resets the once-only banner flag (tests).
  @visibleForTesting
  static void resetForTest() {
    _bannerPrinted = false;
    debugReleaseModeOverride = null;
  }
}
