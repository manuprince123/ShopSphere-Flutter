import 'package:dio/dio.dart';

import '../domain/cart.dart';

abstract interface class CartRemoteDataSource {
  Future<int> placeOrder(int userId, List<CartItem> items);
}

class DioCartRemoteDataSource implements CartRemoteDataSource {
  const DioCartRemoteDataSource(this.dio);

  final Dio dio;

  @override
  Future<int> placeOrder(int userId, List<CartItem> items) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/carts/add',
      options: Options(extra: {'protected': true}),
      data: {
        'userId': userId,
        'products': items
            .map((item) => {'id': item.product.id, 'quantity': item.quantity})
            .toList(),
      },
    );
    return response.data!['id'] as int;
  }
}
