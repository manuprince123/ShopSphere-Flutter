import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/data/product_local_data_source.dart';
import 'package:shopsphere/features/products/data/product_remote_data_source.dart';
import 'package:shopsphere/features/products/data/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/product.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProductRepositoryImpl repository;
  final fixture = jsonDecode(
    File('test/fixtures/products.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dio = MockDio();
    repository = ProductRepositoryImpl(
      DioProductRemoteDataSource(dio),
      PreferencesProductLocalDataSource(await SharedPreferences.getInstance()),
    );
  });

  test('repository returns parsed products and total on success', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: fixture,
        requestOptions: RequestOptions(path: '/products'),
      ),
    );
    final result = await repository.getProducts(const ProductQuery());
    expect(result, isA<Success<ProductPage>>());
    expect(
      (result as Success<ProductPage>).value.products.single.title,
      'Everyday Backpack',
    );
    expect(result.value.total, 1);
  });

  test('repository maps a server error', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 500,
        ),
      ),
    );
    final result = await repository.getProducts(const ProductQuery());
    expect((result as Failed<ProductPage>).failure.kind, FailureKind.server);
  });

  test('repository maps an offline connection', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      ),
    );
    final result = await repository.getProducts(const ProductQuery());
    expect((result as Failed<ProductPage>).failure.kind, FailureKind.network);
  });

  test('offline request falls back to the cached product page', () async {
    var calls = 0;
    when(
      () => dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return Response(
          data: fixture,
          requestOptions: RequestOptions(path: '/products'),
        );
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      );
    });

    await repository.getProducts(const ProductQuery());
    final result = await repository.getProducts(const ProductQuery());
    final cached = (result as Success<ProductPage>).value;
    expect(cached.products.single.title, 'Everyday Backpack');
    expect(cached.isCached, isTrue);
  });

  test('single product 404 becomes not-found failure', () async {
    when(() => dio.get<Map<String, dynamic>>('/products/9999')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products/9999'),
        response: Response(
          requestOptions: RequestOptions(path: '/products/9999'),
          statusCode: 404,
        ),
      ),
    );
    final result = await repository.getProduct(9999);
    expect((result as Failed<Product>).failure.kind, FailureKind.notFound);
  });

  test('search uses the search endpoint and query', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/products/search',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: fixture,
        requestOptions: RequestOptions(path: '/products/search'),
      ),
    );
    await repository.getProducts(const ProductQuery(search: 'bag'));
    final captured =
        verify(
              () => dio.get<Map<String, dynamic>>(
                '/products/search',
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(captured['q'], 'bag');
    expect(captured['limit'], 20);
  });

  test('categories are parsed from the API response', () async {
    when(() => dio.get<List<dynamic>>('/products/categories')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/products/categories'),
        data: [
          {
            'slug': 'smartphones',
            'name': 'Smartphones',
            'url': 'https://dummyjson.com',
          },
        ],
      ),
    );
    final result = await repository.getCategories();
    expect(
      (result as Success<List<Category>>).value.single.slug,
      'smartphones',
    );
  });

  test('categories network failure is retryable', () async {
    when(() => dio.get<List<dynamic>>('/products/categories')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/products/categories'),
        type: DioExceptionType.connectionError,
      ),
    );
    final result = await repository.getCategories();
    expect(
      (result as Failed<List<Category>>).failure.kind,
      FailureKind.network,
    );
  });
}
