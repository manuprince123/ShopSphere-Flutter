import '../../products/domain/product.dart';

abstract interface class WishlistRepository {
  Future<List<Product>> load();
  Future<void> save(List<Product> products);
}

class LoadWishlist {
  const LoadWishlist(this.repository);
  final WishlistRepository repository;
  Future<List<Product>> call() => repository.load();
}

class SaveWishlist {
  const SaveWishlist(this.repository);
  final WishlistRepository repository;
  Future<void> call(List<Product> products) => repository.save(products);
}
