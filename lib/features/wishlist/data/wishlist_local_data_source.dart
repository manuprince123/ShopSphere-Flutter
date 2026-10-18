import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../products/data/product_model.dart';
import '../../products/domain/product.dart';

abstract interface class WishlistLocalDataSource {
  Future<List<Product>> load();
  Future<void> save(List<Product> products);
}

class PreferencesWishlistLocalDataSource implements WishlistLocalDataSource {
  const PreferencesWishlistLocalDataSource(this.preferences);

  final SharedPreferences preferences;
  static const _key = 'shopsphere_wishlist_v1';

  @override
  Future<List<Product>> load() async {
    final raw = preferences.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<Product> products) => preferences.setString(
    _key,
    jsonEncode(
      products
          .map((product) => ProductModel.fromProduct(product).toJson())
          .toList(),
    ),
  );
}
