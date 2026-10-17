import '../../../core/error/failure.dart';
import '../../products/domain/product.dart';

class CartItem {
  const CartItem(this.product, this.quantity);
  final Product product;
  final int quantity;
  CartItem withQuantity(int value) => CartItem(product, value);
}

class CartTotals {
  const CartTotals(this.subtotal, this.discount, this.grandTotal);
  final double subtotal;
  final double discount;
  final double grandTotal;
}

class CalculateCartTotals {
  const CalculateCartTotals();
  CartTotals call(List<CartItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.product.price * item.quantity);
    final grandTotal = items.fold<double>(0, (sum, item) => sum + item.product.salePrice * item.quantity);
    return CartTotals(subtotal, subtotal - grandTotal, grandTotal);
  }
}

abstract interface class CartRepository {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
  Future<Result<int>> placeOrder(int userId, List<CartItem> items);
}
