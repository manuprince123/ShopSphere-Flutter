enum AppThemePreference { light, dark }

enum AppLocalePreference { english, hindi }

class AppSettings {
  const AppSettings({required this.theme, required this.locale});

  final AppThemePreference theme;
  final AppLocalePreference locale;
}

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();
  Future<void> saveTheme(AppThemePreference theme);
  Future<void> saveLocale(AppLocalePreference locale);
}

class LoadAppSettings {
  const LoadAppSettings(this.repository);
  final AppSettingsRepository repository;
  Future<AppSettings> call() => repository.load();
}

class SaveThemePreference {
  const SaveThemePreference(this.repository);
  final AppSettingsRepository repository;
  Future<void> call(AppThemePreference theme) => repository.saveTheme(theme);
}

class SaveLocalePreference {
  const SaveLocalePreference(this.repository);
  final AppSettingsRepository repository;
  Future<void> call(AppLocalePreference locale) =>
      repository.saveLocale(locale);
}
