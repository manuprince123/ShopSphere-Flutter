import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../products/domain/product.dart';
import '../domain/cart.dart';

enum CheckoutStatus { idle, processing, success, failure }

class CartController extends ChangeNotifier {
  CartController(this.repository, this.calculateTotals);
  final CartRepository repository;
  final CalculateCartTotals calculateTotals;

  List<CartItem> items = [];
  bool loaded = false;
  CheckoutStatus checkoutStatus = CheckoutStatus.idle;
  Failure? checkoutFailure;
  int? orderId;

  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  CartTotals get totals => calculateTotals(items);

  Future<void> initialize() async {
    items = await repository.load();
    loaded = true;
    notifyListeners();
  }

  Future<void> add(Product product, int quantity) async {
    if (product.stock <= 0 || quantity <= 0) return;
    final index = items.indexWhere((item) => item.product.id == product.id);
    final next = [...items];
    if (index < 0) {
      next.add(CartItem(product, quantity.clamp(1, product.stock).toInt()));
    } else {
      next[index] = next[index].withQuantity(
          (next[index].quantity + quantity).clamp(1, product.stock).toInt());
    }
    items = next;
    notifyListeners();
    await repository.save(items);
  }

  Future<void> update(int productId, int quantity) async {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    final next = [...items];
    if (quantity <= 0) {
      next.removeAt(index);
    } else {
      next[index] = next[index].withQuantity(
          quantity.clamp(1, next[index].product.stock).toInt());
    }
    items = next;
    notifyListeners();
    await repository.save(items);
  }

  Future<bool> placeOrder(int userId) async {
    if (items.isEmpty || checkoutStatus == CheckoutStatus.processing) return false;
    checkoutStatus = CheckoutStatus.processing;
    checkoutFailure = null;
    notifyListeners();
    final result = await repository.placeOrder(userId, items);
    if (result case Success<int>(:final value)) {
      orderId = value;
      items = [];
      await repository.save(items);
      checkoutStatus = CheckoutStatus.success;
      notifyListeners();
      return true;
    }
    checkoutFailure = (result as Failed<int>).failure;
    checkoutStatus = CheckoutStatus.failure;
    notifyListeners();
    return false;
  }

  Future<void> clear() async {
    items = [];
    checkoutFailure = null;
    checkoutStatus = CheckoutStatus.idle;
    orderId = null;
    notifyListeners();
    await repository.save(items);
  }

  void resetCheckout() {
    checkoutStatus = CheckoutStatus.idle;
    notifyListeners();
  }
}
