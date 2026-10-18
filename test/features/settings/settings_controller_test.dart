import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/l10n/app_localizations.dart';
import 'package:shopsphere/features/settings/domain/app_settings.dart';
import 'package:shopsphere/features/settings/presentation/settings_controller.dart';

class FakeSettingsRepository implements AppSettingsRepository {
  AppSettings settings = const AppSettings(
    theme: AppThemePreference.dark,
    locale: AppLocalePreference.hindi,
  );

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> saveLocale(AppLocalePreference locale) async {
    settings = AppSettings(theme: settings.theme, locale: locale);
  }

  @override
  Future<void> saveTheme(AppThemePreference theme) async {
    settings = AppSettings(theme: theme, locale: settings.locale);
  }
}

void main() {
  test('Hindi catalogue labels are available', () {
    const localizations = AppLocalizations(Locale('hi'));
    expect(localizations.t('explore'), 'खोजें');
    expect(localizations.t('saved'), 'सहेजे गए');
  });

  test('theme and Hindi locale load and persist predictably', () async {
    final repository = FakeSettingsRepository();
    final controller = SettingsController(
      LoadAppSettings(repository),
      SaveThemePreference(repository),
      SaveLocalePreference(repository),
    );

    await controller.initialize();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.locale.languageCode, 'hi');

    await controller.setDarkMode(false);
    await controller.setLocale(const Locale('en'));
    expect(repository.settings.theme, AppThemePreference.light);
    expect(repository.settings.locale, AppLocalePreference.english);
  });
}
