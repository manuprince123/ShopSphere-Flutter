import '../../products/domain/product.dart';
import '../domain/wishlist.dart';
import 'wishlist_local_data_source.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  const WishlistRepositoryImpl(this.localDataSource);

  final WishlistLocalDataSource localDataSource;

  @override
  Future<List<Product>> load() async {
    try {
      return await localDataSource.load();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<Product> products) => localDataSource.save(products);
}
