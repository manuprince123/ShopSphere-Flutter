import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_local_data_source.dart';
import 'product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this.remoteDataSource, this.localDataSource);
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) async {
    try {
      final page = await remoteDataSource.getProducts(query);
      await Future.wait([
        localDataSource.cacheProducts(query, page),
        ...page.products.map(localDataSource.cacheProduct),
      ]);
      return Success(page);
    } catch (error) {
      final failure = mapFailure(error);
      if (failure.kind == FailureKind.network) {
        final cached = await localDataSource.readProducts(query);
        if (cached != null) return Success(cached);
      }
      return Failed(failure);
    }
  }

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final categories = await remoteDataSource.getCategories();
      await localDataSource.cacheCategories(categories);
      return Success(categories);
    } catch (error) {
      final failure = mapFailure(error);
      if (failure.kind == FailureKind.network) {
        final cached = await localDataSource.readCategories();
        if (cached != null) return Success(cached);
      }
      return Failed(failure);
    }
  }

  @override
  Future<Result<Product>> getProduct(int id) async {
    try {
      final product = await remoteDataSource.getProduct(id);
      await localDataSource.cacheProduct(product);
      return Success(product);
    } catch (error) {
      final failure = mapFailure(error);
      if (failure.kind == FailureKind.network) {
        final cached = await localDataSource.readProduct(id);
        if (cached != null) return Success(cached);
      }
      return Failed(failure);
    }
  }
}
