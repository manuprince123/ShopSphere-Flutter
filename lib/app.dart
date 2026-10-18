import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/state_views.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/cart/presentation/cart_controller.dart';
import 'features/products/presentation/catalog_controller.dart';
import 'features/settings/presentation/settings_controller.dart';
import 'features/shell/shop_shell.dart';
import 'features/wishlist/presentation/wishlist_controller.dart';

class ShopSphereApp extends StatelessWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sl<AuthController>()..bootstrap()),
      ChangeNotifierProvider.value(value: sl<CartController>()..initialize()),
      ChangeNotifierProvider.value(
        value: sl<WishlistController>()..initialize(),
      ),
      ChangeNotifierProvider.value(value: sl<SettingsController>()),
      ChangeNotifierProvider(
        create: (_) => sl<CatalogController>()..initialize(),
      ),
    ],
    child: Consumer<SettingsController>(
      builder: (context, settings, _) => MaterialApp(
        onGenerateTitle: (context) => context.l10n.t('appName'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Consumer<AuthController>(
          builder: (context, auth, _) {
            if (auth.status == AuthStatus.checking) return const SplashPage();
            if (auth.status == AuthStatus.restoreFailure) {
              return Scaffold(
                body: ErrorView(
                  message: auth.message ?? 'Could not restore your session.',
                  onRetry: auth.bootstrap,
                ),
              );
            }
            if (auth.status == AuthStatus.signedOut ||
                auth.status == AuthStatus.submitting) {
              return const LoginPage();
            }
            return const ShopShell();
          },
        ),
      ),
    ),
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_rounded,
            size: 72,
            color: AppTheme.jade,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.t('appName'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
