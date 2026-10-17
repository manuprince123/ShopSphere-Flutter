import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/products/domain/product_repository.dart';
import 'package:shopsphere/features/products/presentation/catalog_controller.dart';

const sample = Product(id: 1, title: 'Lamp', description: '', price: 10,
  discountPercentage: 0, rating: 4, stock: 1, thumbnail: '', images: [], reviews: []);

class FakeProducts implements ProductRepository {
  final queue = <Completer<Result<ProductPage>>>[];
  @override
  Future<Result<ProductPage>> getProducts(ProductQuery query) {
    final completer = Completer<Result<ProductPage>>();
    queue.add(completer);
    return completer.future;
  }
  @override
  Future<Result<List<Category>>> getCategories() async => const Success([]);
  @override
  Future<Result<Product>> getProduct(int id) async => const Success(sample);
}

void main() {
  test('catalog emits loading then ready for a successful page', () async {
    final repo = FakeProducts();
    final controller = CatalogController(repo, GetProducts(repo));
    final states = <CatalogStatus>[];
    controller.addListener(() => states.add(controller.status));
    final pending = controller.load();
    repo.queue.single.complete(const Success(ProductPage([sample], 1)));
    await pending;
    expect(states, [CatalogStatus.loading, CatalogStatus.ready]);
    expect(controller.products.single.title, 'Lamp');
  });

  test('empty page has a dedicated empty state', () async {
    final repo = FakeProducts();
    final controller = CatalogController(repo, GetProducts(repo));
    final pending = controller.load();
    repo.queue.single.complete(const Success(ProductPage([], 0)));
    await pending;
    expect(controller.status, CatalogStatus.empty);
  });

  test('server failure keeps a retryable failure state', () async {
    final repo = FakeProducts();
    final controller = CatalogController(repo, GetProducts(repo));
    final pending = controller.load();
    repo.queue.single.complete(const Failed(
      Failure(FailureKind.server, 'Retry later')));
    await pending;
    expect(controller.status, CatalogStatus.failure);
    expect(controller.failure?.kind, FailureKind.server);
  });
}
