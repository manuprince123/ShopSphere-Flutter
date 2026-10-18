import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/cart.dart';
import 'cart_local_data_source.dart';
import 'cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl(this.localDataSource, this.remoteDataSource);
  final CartLocalDataSource localDataSource;
  final CartRemoteDataSource remoteDataSource;

  @override
  Future<List<CartItem>> load() async {
    try {
      return await localDataSource.load();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<CartItem> items) async {
    await localDataSource.save(items);
  }

  @override
  Future<Result<int>> placeOrder(int userId, List<CartItem> items) async {
    try {
      return Success(await remoteDataSource.placeOrder(userId, items));
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }
}
