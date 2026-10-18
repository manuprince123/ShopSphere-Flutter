import 'package:flutter/foundation.dart';

import '../../products/domain/product.dart';
import '../domain/wishlist.dart';

class WishlistController extends ChangeNotifier {
  WishlistController(this.loadWishlist, this.saveWishlist);

  final LoadWishlist loadWishlist;
  final SaveWishlist saveWishlist;

  List<Product> products = [];
  bool loaded = false;

  bool contains(int productId) =>
      products.any((product) => product.id == productId);

  Future<void> initialize() async {
    products = await loadWishlist();
    loaded = true;
    notifyListeners();
  }

  Future<void> toggle(Product product) async {
    final next = [...products];
    final index = next.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      next.add(product);
    } else {
      next.removeAt(index);
    }
    products = next;
    notifyListeners();
    await saveWishlist(products);
  }

  Future<void> clear() async {
    products = [];
    notifyListeners();
    await saveWishlist(products);
  }
}
