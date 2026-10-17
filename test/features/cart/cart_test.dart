import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/cart/domain/cart.dart';
import 'package:shopsphere/features/cart/presentation/cart_controller.dart';
import 'package:shopsphere/features/products/domain/product.dart';

const bag = Product(id: 42, title: 'Bag', description: '', price: 80,
  discountPercentage: 25, rating: 4.5, stock: 5,
  thumbnail: '', images: [], reviews: []);

class FakeCartRepository implements CartRepository {
  List<CartItem> stored = [];
  Result<int> orderResult = const Success(17);
  @override
  Future<List<CartItem>> load() async => stored;
  @override
  Future<void> save(List<CartItem> items) async => stored = [...items];
  @override
  Future<Result<int>> placeOrder(int userId, List<CartItem> items) async => orderResult;
}

void main() {
  test('cart totals calculate subtotal, discount and grand total', () {
    final totals = const CalculateCartTotals()([const CartItem(bag, 2)]);
    expect(totals.subtotal, 160);
    expect(totals.discount, 40);
    expect(totals.grandTotal, 120);
  });
  test('empty cart totals are zero', () {
    expect(const CalculateCartTotals()([]).grandTotal, 0);
  });
  test('adding, updating and removing persists every change', () async {
    final repo = FakeCartRepository();
    final cart = CartController(repo, const CalculateCartTotals());
    await cart.initialize();
    await cart.add(bag, 2);
    expect(cart.count, 2);
    expect(repo.stored.single.quantity, 2);
    await cart.update(42, 4);
    expect(cart.count, 4);
    await cart.update(42, 0);
    expect(repo.stored, isEmpty);
  });
  test('quantity cannot exceed stock', () async {
    final cart = CartController(FakeCartRepository(), const CalculateCartTotals());
    await cart.add(bag, 20);
    expect(cart.count, 5);
  });
  test('successful checkout clears and persists the cart', () async {
    final repo = FakeCartRepository();
    final cart = CartController(repo, const CalculateCartTotals());
    await cart.add(bag, 1);
    expect(await cart.placeOrder(1), isTrue);
    expect(cart.checkoutStatus, CheckoutStatus.success);
    expect(cart.orderId, 17);
    expect(repo.stored, isEmpty);
  });
  test('failed checkout retains cart for retry', () async {
    final repo = FakeCartRepository()..orderResult = const Failed(
      Failure(FailureKind.server, 'Retry'));
    final cart = CartController(repo, const CalculateCartTotals());
    await cart.add(bag, 1);
    expect(await cart.placeOrder(1), isFalse);
    expect(cart.items, hasLength(1));
    expect(cart.checkoutStatus, CheckoutStatus.failure);
  });
  test('clearing a session removes persisted cart items', () async {
    final repo = FakeCartRepository();
    final cart = CartController(repo, const CalculateCartTotals());
    await cart.add(bag, 1);
    await cart.clear();
    expect(cart.count, 0);
    expect(repo.stored, isEmpty);
  });
}
