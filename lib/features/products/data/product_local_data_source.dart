import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/product.dart';
import 'product_model.dart';

abstract interface class ProductLocalDataSource {
  Future<void> cacheProducts(ProductQuery query, ProductPage page);
  Future<ProductPage?> readProducts(ProductQuery query);
  Future<void> cacheCategories(List<Category> categories);
  Future<List<Category>?> readCategories();
  Future<void> cacheProduct(Product product);
  Future<Product?> readProduct(int id);
}

class PreferencesProductLocalDataSource implements ProductLocalDataSource {
  const PreferencesProductLocalDataSource(this.preferences);

  final SharedPreferences preferences;
  static const _categoriesKey = 'shopsphere_categories_v1';

  String _productsKey(ProductQuery query) =>
      'shopsphere_products_v1_${query.search}_${query.category ?? 'all'}_'
      '${query.sort.name}_${query.skip}_${query.limit}';

  String _productKey(int id) => 'shopsphere_product_v1_$id';

  @override
  Future<void> cacheProducts(ProductQuery query, ProductPage page) async {
    await preferences.setString(
      _productsKey(query),
      jsonEncode({
        'products': page.products
            .map((product) => ProductModel.fromProduct(product).toJson())
            .toList(),
        'total': page.total,
      }),
    );
  }

  @override
  Future<ProductPage?> readProducts(ProductQuery query) async {
    final raw = preferences.getString(_productsKey(query));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ProductPage(
      (json['products'] as List<dynamic>)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      json['total'] as int,
      isCached: true,
    );
  }

  @override
  Future<void> cacheCategories(List<Category> categories) async {
    await preferences.setString(
      _categoriesKey,
      jsonEncode(
        categories
            .map((category) => {'slug': category.slug, 'name': category.name})
            .toList(),
      ),
    );
  }

  @override
  Future<List<Category>?> readCategories() async {
    final raw = preferences.getString(_categoriesKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List<dynamic>)
        .map(
          (item) => Category(
            (item as Map<String, dynamic>)['slug'] as String,
            item['name'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<void> cacheProduct(Product product) => preferences.setString(
    _productKey(product.id),
    jsonEncode(ProductModel.fromProduct(product).toJson()),
  );

  @override
  Future<Product?> readProduct(int id) async {
    final raw = preferences.getString(_productKey(id));
    if (raw == null) return null;
    return ProductModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
