import '../../../core/error/failure.dart';
import 'product.dart';

abstract interface class ProductRepository {
  Future<Result<ProductPage>> getProducts(ProductQuery query);
  Future<Result<List<Category>>> getCategories();
  Future<Result<Product>> getProduct(int id);
}

class GetProducts {
  const GetProducts(this.repository);
  final ProductRepository repository;
  Future<Result<ProductPage>> call(ProductQuery query) =>
      repository.getProducts(query);
}

class GetProduct {
  const GetProduct(this.repository);
  final ProductRepository repository;
  Future<Result<Product>> call(int id) => repository.getProduct(id);
}

class GetCategories {
  const GetCategories(this.repository);
  final ProductRepository repository;
  Future<Result<List<Category>>> call() => repository.getCategories();
}
