import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:t_ride_rider_app/consts/appConst.dart';
import 'package:t_ride_rider_app/data/local/secure_storage_service.dart';

/// Global theme controller.
///
/// Holds the current theme selection and persists the user preference. The
/// app supports two themes:
///   * Yellow theme (default)         -> [isDarkMode] == false
///   * White  theme (replaces dark)   -> [isDarkMode] == true
///
/// The flag name [isDarkMode] is preserved for backward-compat with the
/// existing storage key + toggle UI. When it flips we call
/// [Get.forceAppUpdate] so every widget that reads from [AppConst] (whose
/// color tokens are mode-aware getters) repaints with the new palette.
class ThemeController extends GetxController {
  ThemeController({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;

  /// Reactive flag — observe this from `Obx` to rebuild on theme change.
  /// `false` => Yellow theme, `true` => White theme.
  final RxBool isDarkMode = false.obs;

  /// Read the persisted preference and apply it. Call once before runApp().
  Future<void> loadInitial() async {
    final saved = await _storage.getDarkMode();
    isDarkMode.value = saved;
    AppConst.isDarkMode = saved;
    _applySystemUiOverlay();
  }

  /// Toggle and persist. Forces a full app rebuild so widgets reading from
  /// [AppConst] pick up the new colors.
  Future<void> toggle() async {
    final next = !isDarkMode.value;
    isDarkMode.value = next;
    AppConst.isDarkMode = next;
    // Both new themes use light-brightness Material defaults (black text on
    // light surfaces) — so we don't drive Material's themeMode anymore. We
    // just force a repaint so AppConst getters re-read.
    Get.forceAppUpdate();
    _applySystemUiOverlay();
    await _storage.saveDarkMode(next);
  }

  /// Status bar content stays white in both themes (branded black headers
  /// at the top of every page).
  void _applySystemUiOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: white icons
        statusBarBrightness: Brightness.dark, // iOS: white icons
      ),
    );
  }
}
