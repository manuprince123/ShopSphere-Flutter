import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/domain/product.dart';
import 'package:shopsphere/features/products/domain/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const item = Product(id: 5, title: 'Phone', description: '', price: 100,
  discountPercentage: 0, rating: 4, stock: 1, thumbnail: '', images: [], reviews: []);

void main() {
  test('get products passes a search query to its repository', () async {
    final repository = MockProductRepository();
    const query = ProductQuery(search: 'phone', skip: 20);
    when(() => repository.getProducts(query))
      .thenAnswer((_) async => const Success(ProductPage([item], 1)));
    final result = await GetProducts(repository)(query);
    expect((result as Success<ProductPage>).value.products.single.title, 'Phone');
    verify(() => repository.getProducts(query)).called(1);
  });

  test('get product delegates the requested id', () async {
    final repository = MockProductRepository();
    when(() => repository.getProduct(5)).thenAnswer((_) async => const Success(item));
    final result = await GetProduct(repository)(5);
    expect((result as Success<Product>).value.id, 5);
    verify(() => repository.getProduct(5)).called(1);
  });
}
