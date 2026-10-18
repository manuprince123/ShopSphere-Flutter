import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../products/data/product_model.dart';
import '../domain/cart.dart';

abstract interface class CartLocalDataSource {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

class PreferencesCartLocalDataSource implements CartLocalDataSource {
  const PreferencesCartLocalDataSource(this.preferences);

  final SharedPreferences preferences;
  static const key = 'shopsphere_cart_v1';

  @override
  Future<List<CartItem>> load() async {
    final raw = preferences.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).map((entry) {
      final json = entry as Map<String, dynamic>;
      return CartItem(
        ProductModel.fromJson(json['product'] as Map<String, dynamic>),
        json['quantity'] as int,
      );
    }).toList();
  }

  @override
  Future<void> save(List<CartItem> items) => preferences.setString(
    key,
    jsonEncode(
      items
          .map(
            (item) => {
              'product': ProductModel.fromProduct(item.product).toJson(),
              'quantity': item.quantity,
            },
          )
          .toList(),
    ),
  );
}
