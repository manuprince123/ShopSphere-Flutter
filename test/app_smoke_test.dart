import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/app.dart';
import 'package:shopsphere/core/di/locator.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/auth/presentation/auth_controller.dart';
import 'package:shopsphere/features/cart/domain/cart.dart';
import 'package:shopsphere/features/cart/presentation/cart_controller.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/products/domain/product_repository.dart';
import 'package:shopsphere/features/products/presentation/catalog_controller.dart';
import 'package:shopsphere/features/products/presentation/product_controller.dart';
import 'package:shopsphere/features/products/presentation/product_detail_page.dart';
import 'package:shopsphere/features/profile/domain/profile_repository.dart';
import 'package:shopsphere/features/profile/presentation/profile_controller.dart';
import 'package:shopsphere/features/settings/domain/app_settings.dart';
import 'package:shopsphere/features/settings/presentation/settings_controller.dart';
import 'package:shopsphere/features/wishlist/domain/wishlist.dart';
import 'package:shopsphere/features/wishlist/presentation/wishlist_controller.dart';

const demoUser = AuthUser(
  id: 1,
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@example.test',
  phone: '555-0101',
  image: '',
);
const demoProduct = Product(
  id: 42,
  title: 'Everyday Backpack',
  description: 'A lightweight bag for everyday use.',
  price: 80,
  discountPercentage: 25,
  rating: 4.5,
  stock: 5,
  thumbnail: 'https://example.test/bag.png',
  images: [],
  reviews: [
    Review(
      rating: 5,
      comment: 'Excellent bag',
      reviewerName: 'Ava',
      date: null,
    ),
  ],
  brand: 'North',
);
const outOfStockProduct = Product(
  id: 117,
  title: 'Sportbike Motorcycle',
  description: 'A product that is currently unavailable.',
  price: 7499.99,
  discountPercentage: 0,
  rating: 4.2,
  stock: 0,
  thumbnail: 'https://example.test/sportbike.png',
  images: [],
  reviews: [],
  brand: 'Kawasaki',
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<Result<AuthUser>> login(String username, String password) async =>
      const Success(demoUser);
  @override
  Future<void> logout() async {}
}

class FakeProfileRepository implements ProfileRepository {
  @override
  Future<Result<AuthUser>> me() async => const Success(demoUser);
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository({this.withProduct = false, this.product = demoProduct});
  final bool withProduct;
  final Product product;
  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) async =>
      withProduct
      ? Success(ProductPage([product], 1))
      : const Success(ProductPage([], 0));
  @override
  Future<Result<List<Category>>> getCategories() async => const Success([]);
  @override
  Future<Result<Product>> getProduct(int id) async => withProduct
      ? Success(product)
      : const Failed(Failure(FailureKind.notFound, 'Product not found.'));
}

class FakeCartRepository implements CartRepository {
  List<CartItem> stored = [];
  @override
  Future<List<CartItem>> load() async => stored;
  @override
  Future<void> save(List<CartItem> items) async => stored = [...items];
  @override
  Future<Result<int>> placeOrder(int userId, List<CartItem> items) async =>
      const Success(1);
}

class FakeWishlistRepository implements WishlistRepository {
  List<Product> stored = [];
  @override
  Future<List<Product>> load() async => stored;
  @override
  Future<void> save(List<Product> products) async => stored = [...products];
}

class FakeSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings(
    theme: AppThemePreference.light,
    locale: AppLocalePreference.english,
  );
  @override
  Future<void> saveLocale(AppLocalePreference locale) async {}
  @override
  Future<void> saveTheme(AppThemePreference theme) async {}
}

void main() {
  tearDown(() async => sl.reset());

  Future<void> advance(WidgetTester tester) async {
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  void registerFakes(FakeProductRepository products, FakeCartRepository cart) {
    final authRepository = FakeAuthRepository();
    final profile = FakeProfileRepository();
    sl.registerSingleton<AuthController>(
      AuthController(
        CheckSession(authRepository),
        Login(authRepository),
        GetProfile(profile),
        Logout(authRepository),
      ),
    );
    sl.registerSingleton<CartController>(
      CartController(
        LoadCart(cart),
        SaveCart(cart),
        PlaceOrder(cart),
        const CalculateCartTotals(),
      ),
    );
    final wishlist = FakeWishlistRepository();
    sl.registerSingleton<WishlistController>(
      WishlistController(LoadWishlist(wishlist), SaveWishlist(wishlist)),
    );
    final settings = FakeSettingsRepository();
    sl.registerSingleton<SettingsController>(
      SettingsController(
        LoadAppSettings(settings),
        SaveThemePreference(settings),
        SaveLocalePreference(settings),
      ),
    );
    sl.registerFactory<CatalogController>(
      () => CatalogController(GetProducts(products), GetCategories(products)),
    );
    sl.registerFactory<ProductController>(
      () => ProductController(GetProduct(products)),
    );
    sl.registerFactory<ProfileController>(
      () => ProfileController(GetProfile(profile)),
    );
  }

  testWidgets('user can sign in and navigate from catalogue to cart', (
    tester,
  ) async {
    final products = FakeProductRepository();
    registerFakes(products, FakeCartRepository());

    await tester.pumpWidget(const ShopSphereApp());
    await tester.pumpAndSettle();
    expect(find.text('Good things await.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Discover your next find'), findsOneWidget);

    await tester.tap(find.text('Cart').last);
    await tester.pumpAndSettle();
    expect(find.text('Your bag is empty'), findsOneWidget);
  });

  testWidgets('user can inspect, buy and view a product then open profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cart = FakeCartRepository();
    registerFakes(FakeProductRepository(withProduct: true), cart);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.3),
        ),
        child: ShopSphereApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.text('Sign in'));
    await advance(tester);

    expect(find.text('Everyday Backpack'), findsOneWidget);
    await tester.tap(find.text('Everyday Backpack'));
    await advance(tester);
    expect(find.text('Everyday Backpack'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Add to cart'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ProductDetailPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Add to cart'));
    await advance(tester);
    expect(cart.stored.single.quantity, 1);

    await tester.pageBack();
    await advance(tester);
    await tester.tap(find.text('Cart'));
    await advance(tester);
    expect(find.text('Grand total'), findsOneWidget);
    await tester.tap(find.text('Place order'));
    await advance(tester);
    expect(find.text('Order placed!'), findsOneWidget);
    expect(cart.stored, isEmpty);

    await tester.pageBack();
    await advance(tester);
    await tester.tap(find.text('Profile'));
    await advance(tester);
    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('555-0101'), findsOneWidget);
  });

  testWidgets('out-of-stock product disables add to cart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    registerFakes(
      FakeProductRepository(withProduct: true, product: outOfStockProduct),
      FakeCartRepository(),
    );

    await tester.pumpWidget(const ShopSphereApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.text('Sign in'));
    await advance(tester);
    await tester.tap(find.text('Sportbike Motorcycle'));
    await advance(tester);

    expect(find.byType(Hero), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Add to cart'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ProductDetailPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Out of stock'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add to cart'),
    );
    expect(button.onPressed, isNull);
  });

  for (final size in [const Size(800, 1100), const Size(1200, 700)]) {
    testWidgets(
      'catalogue adapts to ${size.width}×${size.height} at 1.3× text',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        registerFakes(
          FakeProductRepository(withProduct: true),
          FakeCartRepository(),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: const ShopSphereApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'emilys');
        await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
        await tester.tap(find.text('Sign in'));
        await advance(tester);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Everyday Backpack'), findsOneWidget);
        if (size.width > 1024) {
          expect(find.text('Select a product to see details'), findsOneWidget);
          await tester.tap(find.text('Everyday Backpack'));
          await advance(tester);
          await tester.scrollUntilVisible(
            find.text('About this item'),
            200,
            scrollable: find
                .descendant(
                  of: find.byType(ProductDetailContent),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(find.text('About this item'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
