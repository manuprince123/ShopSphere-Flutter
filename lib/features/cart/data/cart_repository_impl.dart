import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../products/data/product_model.dart';
import '../domain/cart.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this.preferences, this.dio);
  final SharedPreferences preferences;
  final Dio dio;
  static const key = 'shopsphere_cart_v1';

  @override
  Future<List<CartItem>> load() async {
    try {
      final raw = preferences.getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List<dynamic>).map((entry) {
        final json = entry as Map<String, dynamic>;
        return CartItem(ProductModel.fromJson(json['product'] as Map<String, dynamic>),
            json['quantity'] as int);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    await preferences.setString(key, jsonEncode(items.map((item) => {
      'product': ProductModel.fromJson({
        'id': item.product.id, 'title': item.product.title,
        'description': item.product.description, 'price': item.product.price,
        'discountPercentage': item.product.discountPercentage,
        'rating': item.product.rating, 'stock': item.product.stock,
        'thumbnail': item.product.thumbnail, 'images': item.product.images,
        'brand': item.product.brand,
      }).toJson(),
      'quantity': item.quantity,
    }).toList()));
  }

  @override
  Future<Result<int>> placeOrder(int userId, List<CartItem> items) async {
    try {
      final response = await dio.post<Map<String, dynamic>>('/carts/add',
        options: Options(extra: {'protected': true}),
        data: {
          'userId': userId,
          'products': items.map((item) => {
            'id': item.product.id, 'quantity': item.quantity,
          }).toList(),
        });
      return Success(response.data!['id'] as int);
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }
}
