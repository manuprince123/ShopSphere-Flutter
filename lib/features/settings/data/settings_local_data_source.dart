import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

abstract interface class SettingsLocalDataSource {
  Future<AppSettings> load();
  Future<void> saveTheme(AppThemePreference theme);
  Future<void> saveLocale(AppLocalePreference locale);
}

class PreferencesSettingsLocalDataSource implements SettingsLocalDataSource {
  const PreferencesSettingsLocalDataSource(this.preferences);

  final SharedPreferences preferences;
  static const _themeKey = 'shopsphere_theme_v1';
  static const _localeKey = 'shopsphere_locale_v1';

  @override
  Future<AppSettings> load() async => AppSettings(
    theme: preferences.getString(_themeKey) == AppThemePreference.dark.name
        ? AppThemePreference.dark
        : AppThemePreference.light,
    locale: preferences.getString(_localeKey) == AppLocalePreference.hindi.name
        ? AppLocalePreference.hindi
        : AppLocalePreference.english,
  );

  @override
  Future<void> saveTheme(AppThemePreference theme) =>
      preferences.setString(_themeKey, theme.name);

  @override
  Future<void> saveLocale(AppLocalePreference locale) =>
      preferences.setString(_localeKey, locale.name);
}
