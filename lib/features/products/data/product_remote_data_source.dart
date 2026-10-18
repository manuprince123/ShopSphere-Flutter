import 'package:dio/dio.dart';

import '../domain/product.dart';
import 'product_model.dart';

abstract interface class ProductRemoteDataSource {
  Future<ProductPage> getProducts(ProductQuery query);
  Future<List<Category>> getCategories();
  Future<Product> getProduct(int id);
}

class DioProductRemoteDataSource implements ProductRemoteDataSource {
  const DioProductRemoteDataSource(this.dio);

  final Dio dio;

  @override
  Future<ProductPage> getProducts(ProductQuery query) async {
    final path = query.search.isNotEmpty
        ? '/products/search'
        : query.category != null
        ? '/products/category/${Uri.encodeComponent(query.category!)}'
        : '/products';
    final params = <String, dynamic>{'limit': query.limit, 'skip': query.skip};
    if (query.search.isNotEmpty) params['q'] = query.search;
    switch (query.sort) {
      case ProductSort.featured:
        break;
      case ProductSort.priceLow:
        params.addAll({'sortBy': 'price', 'order': 'asc'});
        break;
      case ProductSort.priceHigh:
        params.addAll({'sortBy': 'price', 'order': 'desc'});
        break;
      case ProductSort.rating:
        params.addAll({'sortBy': 'rating', 'order': 'desc'});
        break;
      case ProductSort.title:
        params.addAll({'sortBy': 'title', 'order': 'asc'});
        break;
    }
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: params,
    );
    final data = response.data!;
    return ProductPage(
      (data['products'] as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      data['total'] as int,
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    final response = await dio.get<List<dynamic>>('/products/categories');
    return response.data!.map((item) {
      final json = item as Map<String, dynamic>;
      return Category(json['slug'] as String, json['name'] as String);
    }).toList();
  }

  @override
  Future<Product> getProduct(int id) async {
    final response = await dio.get<Map<String, dynamic>>('/products/$id');
    return ProductModel.fromJson(response.data!);
  }
}
