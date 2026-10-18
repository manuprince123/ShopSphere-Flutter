import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/cart/data/cart_local_data_source.dart';
import 'package:shopsphere/features/cart/data/cart_remote_data_source.dart';
import 'package:shopsphere/features/cart/data/cart_repository_impl.dart';
import 'package:shopsphere/features/cart/domain/cart.dart';
import 'package:shopsphere/features/products/domain/product.dart';

class MockDio extends Mock implements Dio {}

const product = Product(
  id: 7,
  title: 'Watch',
  description: 'A watch',
  price: 99,
  discountPercentage: 10,
  rating: 4,
  stock: 10,
  thumbnail: 'https://example.test/watch.png',
  images: [],
  reviews: [],
);

void main() {
  late MockDio dio;
  late CartRepositoryImpl repository;
  setUpAll(() => registerFallbackValue(Options()));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dio = MockDio();
    repository = CartRepositoryImpl(
      PreferencesCartLocalDataSource(await SharedPreferences.getInstance()),
      DioCartRemoteDataSource(dio),
    );
  });

  test('cart survives a repository reload', () async {
    await repository.save([const CartItem(product, 3)]);
    final restored = await repository.load();
    expect(restored.single.product.title, 'Watch');
    expect(restored.single.quantity, 3);
  });

  test('checkout sends user and product quantities to the API', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/carts/add',
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/carts/add'),
        data: {'id': 15},
      ),
    );
    final result = await repository.placeOrder(1, [const CartItem(product, 2)]);
    expect((result as Success<int>).value, 15);
    final payload =
        verify(
              () => dio.post<Map<String, dynamic>>(
                '/carts/add',
                options: any(named: 'options'),
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(payload['userId'], 1);
    expect((payload['products'] as List).single['quantity'], 2);
  });

  test(
    'checkout server failure is returned without clearing storage',
    () async {
      await repository.save([const CartItem(product, 1)]);
      when(
        () => dio.post<Map<String, dynamic>>(
          '/carts/add',
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/carts/add'),
          response: Response(
            requestOptions: RequestOptions(path: '/carts/add'),
            statusCode: 500,
          ),
        ),
      );
      final result = await repository.placeOrder(1, [
        const CartItem(product, 1),
      ]);
      expect((result as Failed<int>).failure.kind, FailureKind.server);
      expect(await repository.load(), hasLength(1));
    },
  );
}
