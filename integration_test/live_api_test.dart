import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shopsphere/app.dart';
import 'package:shopsphere/core/di/locator.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/core/widgets/state_views.dart';
import 'package:shopsphere/features/auth/data/token_store.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/cart/presentation/cart_controller.dart';
import 'package:shopsphere/features/products/presentation/catalog_controller.dart';
import 'package:shopsphere/features/products/presentation/catalog_page.dart';
import 'package:shopsphere/features/products/presentation/product_detail_page.dart';

// This separate test entry point uses the real app, storage, repositories and
// DummyJSON responses. Only test requests are redirected to the brief's error
// endpoints. None of this injection is included in lib/main.dart's release APK.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live API failures recover through the Android UI', (
    tester,
  ) async {
    await configureDependencies();
    await sl<AuthRepository>().logout();
    await sl<CartController>().clear();
    final dio = sl<ApiClient>().dio;
    var scenario = 'invalid-login';
    final requests = <Map<String, Object?>>[];
    final checks = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/login') {
            final credentials = options.data as Map<String, dynamic>;
            debugPrint(
              'QA login username matches: ${credentials['username'] == 'emilys'}; '
              'password matches scenario: ${credentials['password'] == (scenario == 'invalid-login' ? 'wrong-password' : 'emilyspass')}',
            );
          }
          if (options.path == '/products') {
            if (scenario == 'server') {
              options.path = '/http/500';
              options.queryParameters.clear();
            } else if (scenario == 'slow') {
              options.queryParameters['delay'] = 3000;
            } else if (scenario == 'timeout') {
              options.queryParameters['delay'] = 5000;
              options.receiveTimeout = const Duration(milliseconds: 500);
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          requests.add({
            'method': response.requestOptions.method,
            'path': response.requestOptions.uri.path,
            'query': response.requestOptions.uri.query,
            'status': response.statusCode,
          });
          handler.next(response);
        },
        onError: (error, handler) {
          requests.add({
            'method': error.requestOptions.method,
            'path': error.requestOptions.uri.path,
            'query': error.requestOptions.uri.query,
            'status': error.response?.statusCode,
            'type': error.type.name,
          });
          handler.next(error);
        },
      ),
    );
    binding.reportData = {'checks': checks, 'requests': requests};

    Future<void> waitFor(Finder finder) async {
      final elapsed = Stopwatch()..start();
      while (finder.evaluate().isEmpty && elapsed.elapsed.inSeconds < 35) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(finder, findsWidgets);
      await tester.pump(const Duration(milliseconds: 250));
    }

    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    await tester.pumpWidget(const ShopSphereApp());
    await waitFor(find.text('Good things await.'));
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await waitFor(find.text('Invalid username or password.'));
    expect(
      requests.any((r) => r['path'] == '/auth/login' && r['status'] == 400),
      isTrue,
    );
    checks.add('Invalid login: HTTP 400, inline error, no crash');
    await capture('01-invalid-login');

    scenario = 'valid-login';
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'emilys',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'emilyspass',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await waitFor(find.byType(CatalogPage));
    final catalog = tester
        .element(find.byType(CatalogPage))
        .read<CatalogController>();
    await waitFor(find.byType(ProductCard));

    scenario = 'server';
    final failedLoad = catalog.load();
    await tester.pump();
    await failedLoad;
    await waitFor(
      find.text('The store is having trouble right now. Please retry.'),
    );
    expect(catalog.failure?.kind, FailureKind.server);
    expect(
      requests.any((r) => r['path'] == '/http/500' && r['status'] == 500),
      isTrue,
    );
    checks.add('Server error: real /http/500 maps to friendly error and retry');
    await capture('02-server-error');
    scenario = '';
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await waitFor(find.byType(ProductCard));
    expect(catalog.status, CatalogStatus.ready);
    checks.add('Retry after server error: catalogue recovers');

    final context = tester.element(find.byType(CatalogPage));
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => const ProductDetailPage(productId: 9999),
        ),
      ),
    );
    await tester.pump();
    await waitFor(find.text('Product not found'));
    expect(
      requests.any((r) => r['path'] == '/products/9999' && r['status'] == 404),
      isTrue,
    );
    checks.add(
      'Missing product: real /products/9999 maps to not-found page with back action',
    );
    await capture('03-product-not-found');
    await tester.pageBack();
    await tester.pumpAndSettle();

    scenario = 'slow';
    final timer = Stopwatch()..start();
    final slowLoad = catalog.load();
    await tester.pump(const Duration(milliseconds: 700));
    expect(catalog.status, CatalogStatus.loading);
    expect(find.byType(LoadingCards), findsOneWidget);
    await capture('04-slow-network-loader');
    await slowLoad;
    await waitFor(find.byType(ProductCard));
    expect(timer.elapsedMilliseconds, greaterThanOrEqualTo(2900));
    checks.add(
      'delay=3000: skeleton remains visible, then real products load (${timer.elapsedMilliseconds} ms)',
    );

    scenario = 'timeout';
    final timedOutLoad = catalog.load();
    await tester.pump();
    await timedOutLoad;
    await waitFor(find.text('The request took too long. Please try again.'));
    expect(catalog.failure?.kind, FailureKind.timeout);
    checks.add(
      'delay=5000 with test-only 500 ms receive timeout: friendly timeout state',
    );
    await capture('05-timeout');
    scenario = '';
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await waitFor(find.byType(ProductCard));

    await sl<TokenStore>().save('invalid-test-token', 'invalid-test-refresh');
    await tester.tap(find.text('Profile').last);
    await waitFor(find.text('Your session has expired. Please sign in again.'));
    expect(await sl<TokenStore>().readAccessToken(), isNull);
    expect(await sl<TokenStore>().readRefreshToken(), isNull);
    expect(sl<CartController>().count, 0);
    expect(
      requests.any(
        (r) =>
            r['path'] == '/auth/refresh' &&
            (r['status'] as int?) != null &&
            (r['status'] as int) >= 400 &&
            (r['status'] as int) < 500,
      ),
      isTrue,
    );
    checks.add(
      'Invalid access + refresh token: protected request attempts refresh, then signs out, clears tokens/cart, and explains expiry',
    );
    await capture('06-session-expired');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
