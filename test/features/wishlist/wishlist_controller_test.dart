import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/wishlist/domain/wishlist.dart';
import 'package:shopsphere/features/wishlist/presentation/wishlist_controller.dart';

const product = Product(
  id: 9,
  title: 'Lamp',
  description: '',
  price: 20,
  discountPercentage: 0,
  rating: 4,
  stock: 2,
  thumbnail: '',
  images: [],
  reviews: [],
);

class FakeWishlistRepository implements WishlistRepository {
  List<Product> stored = [];

  @override
  Future<List<Product>> load() async => stored;

  @override
  Future<void> save(List<Product> products) async => stored = [...products];
}

void main() {
  test('wishlist toggles and persists products across reloads', () async {
    final repository = FakeWishlistRepository();
    final controller = WishlistController(
      LoadWishlist(repository),
      SaveWishlist(repository),
    );
    await controller.initialize();

    await controller.toggle(product);
    expect(controller.contains(product.id), isTrue);
    final restored = WishlistController(
      LoadWishlist(repository),
      SaveWishlist(repository),
    );
    await restored.initialize();
    expect(restored.products.single.title, 'Lamp');

    await restored.toggle(product);
    expect(restored.products, isEmpty);
    expect(repository.stored, isEmpty);
  });
}
