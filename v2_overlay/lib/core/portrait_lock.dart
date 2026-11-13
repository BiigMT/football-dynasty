import 'package:flutter/services.dart';

/// Applies the game's portrait-only orientation policy at startup.
abstract final class PortraitLock {
  static Future<void> apply({bool allowUpsideDown = false}) {
    return SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      if (allowUpsideDown) DeviceOrientation.portraitDown,
    ]);
  }
}
