import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _keyAuthToken = 'auth_token';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyAppLocale = 'app_locale_language_code';
  static const String _keyDarkMode = 'app_dark_mode';

  Future<void> saveAuthToken(String token) {
    return _storage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() {
    return _storage.read(key: _keyAuthToken);
  }

  Future<void> clearAuthToken() {
    return _storage.delete(key: _keyAuthToken);
  }

  Future<void> setOnboardingCompleted() {
    return _storage.write(key: _keyOnboardingCompleted, value: 'true');
  }

  Future<bool> isOnboardingCompleted() async {
    final value = await _storage.read(key: _keyOnboardingCompleted);
    return value == 'true';
  }

  /// BCP-47 language code, e.g. `en` or `ar`.
  Future<void> saveAppLocaleLanguageCode(String code) {
    return _storage.write(key: _keyAppLocale, value: code);
  }

  Future<String?> getAppLocaleLanguageCode() {
    return _storage.read(key: _keyAppLocale);
  }

  Future<void> saveDarkMode(bool enabled) {
    return _storage.write(key: _keyDarkMode, value: enabled ? 'true' : 'false');
  }

  Future<bool> getDarkMode() async {
    final value = await _storage.read(key: _keyDarkMode);
    return value == 'true';
  }
}

