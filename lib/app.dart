import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/state_views.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/cart/presentation/cart_controller.dart';
import 'features/products/presentation/catalog_controller.dart';
import 'features/shell/shop_shell.dart';

class ShopSphereApp extends StatelessWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sl<AuthController>()..bootstrap()),
      ChangeNotifierProvider.value(value: sl<CartController>()..initialize()),
      ChangeNotifierProvider(
        create: (_) => sl<CatalogController>()..initialize(),
      ),
    ],
    child: MaterialApp(
      title: 'ShopSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_rounded, size: 72, color: AppTheme.jade),
          SizedBox(height: 16),
          Text(
            'ShopSphere',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
