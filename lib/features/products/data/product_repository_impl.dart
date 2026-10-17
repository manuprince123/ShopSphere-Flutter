import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this.dio);
  final Dio dio;

  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) async {
    try {
      final path = query.search.isNotEmpty
          ? '/products/search'
          : query.category != null
          ? '/products/category/${Uri.encodeComponent(query.category!)}'
          : '/products';
      final params = <String, dynamic>{
        'limit': query.limit,
        'skip': query.skip,
      };
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
      return Success(
        ProductPage(
          (data['products'] as List<dynamic>)
              .map(
                (item) => ProductModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
          data['total'] as int,
        ),
      );
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final response = await dio.get<List<dynamic>>('/products/categories');
      return Success(
        response.data!.map((item) {
          final json = item as Map<String, dynamic>;
          return Category(json['slug'] as String, json['name'] as String);
        }).toList(),
      );
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }

  @override
  Future<Result<Product>> getProduct(int id) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/products/$id');
      return Success(ProductModel.fromJson(response.data!));
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }
}
