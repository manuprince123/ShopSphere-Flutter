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
import 'package:shopsphere/features/profile/domain/profile_repository.dart';
import 'package:shopsphere/features/profile/presentation/profile_controller.dart';

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
  FakeProductRepository({this.withProduct = false});
  final bool withProduct;
  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) async =>
      withProduct
      ? const Success(ProductPage([demoProduct], 1))
      : const Success(ProductPage([], 0));
  @override
  Future<Result<List<Category>>> getCategories() async => const Success([]);
  @override
  Future<Result<Product>> getProduct(int id) async => withProduct
      ? const Success(demoProduct)
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
      AuthController(authRepository, Login(authRepository), profile),
    );
    sl.registerSingleton<CartController>(
      CartController(cart, const CalculateCartTotals()),
    );
    sl.registerFactory<CatalogController>(
      () => CatalogController(products, GetProducts(products)),
    );
    sl.registerFactory<ProductController>(
      () => ProductController(GetProduct(products)),
    );
    sl.registerFactory<ProfileController>(() => ProfileController(profile));
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

    await tester.pumpWidget(const ShopSphereApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'emilys');
    await tester.enterText(find.byType(TextFormField).last, 'emilyspass');
    await tester.tap(find.text('Sign in'));
    await advance(tester);

    expect(find.text('Everyday Backpack'), findsOneWidget);
    await tester.tap(find.text('Everyday Backpack'));
    await advance(tester);
    expect(find.text('Customer reviews'), findsOneWidget);
    await tester.ensureVisible(find.text('Add to cart'));
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
}
