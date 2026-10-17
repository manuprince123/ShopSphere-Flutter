import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

enum ProductStatus { loading, ready, failure }

class ProductController extends ChangeNotifier {
  ProductController(this.getProduct);
  final GetProduct getProduct;
  ProductStatus status = ProductStatus.loading;
  Product? product;
  Failure? failure;
  bool _disposed = false;

  Future<void> load(int id) async {
    status = ProductStatus.loading;
    failure = null;
    notifyListeners();
    final result = await getProduct(id);
    if (_disposed) return;
    if (result case Success<Product>(:final value)) {
      product = value;
      status = ProductStatus.ready;
    } else {
      failure = (result as Failed<Product>).failure;
      status = ProductStatus.failure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
