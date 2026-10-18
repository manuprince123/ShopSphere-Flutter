import '../domain/app_settings.dart';
import 'settings_local_data_source.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  const AppSettingsRepositoryImpl(this.localDataSource);

  final SettingsLocalDataSource localDataSource;

  @override
  Future<AppSettings> load() => localDataSource.load();

  @override
  Future<void> saveLocale(AppLocalePreference locale) =>
      localDataSource.saveLocale(locale);

  @override
  Future<void> saveTheme(AppThemePreference theme) =>
      localDataSource.saveTheme(theme);
}
