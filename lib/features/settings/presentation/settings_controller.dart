import 'package:flutter/material.dart';

import '../domain/app_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(
    this.loadSettings,
    this.saveThemePreference,
    this.saveLocalePreference,
  );

  final LoadAppSettings loadSettings;
  final SaveThemePreference saveThemePreference;
  final SaveLocalePreference saveLocalePreference;

  ThemeMode themeMode = ThemeMode.light;
  Locale locale = const Locale('en');

  Future<void> initialize() async {
    final settings = await loadSettings();
    themeMode = settings.theme == AppThemePreference.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    locale = settings.locale == AppLocalePreference.hindi
        ? const Locale('hi')
        : const Locale('en');
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await saveThemePreference(
      enabled ? AppThemePreference.dark : AppThemePreference.light,
    );
  }

  Future<void> setLocale(Locale value) async {
    locale = value.languageCode == 'hi'
        ? const Locale('hi')
        : const Locale('en');
    notifyListeners();
    await saveLocalePreference(
      locale.languageCode == 'hi'
          ? AppLocalePreference.hindi
          : AppLocalePreference.english,
    );
  }
}
