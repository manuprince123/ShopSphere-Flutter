import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/products/data/product_repository_impl.dart';
import 'package:shopsphere/features/products/domain/product.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProductRepositoryImpl repository;
  final fixture = jsonDecode(File('test/fixtures/products.json').readAsStringSync()) as Map<String, dynamic>;

  setUp(() {
    dio = MockDio();
    repository = ProductRepositoryImpl(dio);
  });

  test('repository returns parsed products and total on success', () async {
    when(() => dio.get<Map<String, dynamic>>('/products',
      queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async =>
        Response(data: fixture, requestOptions: RequestOptions(path: '/products')));
    final result = await repository.getProducts(const ProductQuery());
    expect(result, isA<Success<ProductPage>>());
    expect((result as Success<ProductPage>).value.products.single.title, 'Everyday Backpack');
    expect(result.value.total, 1);
  });

  test('repository maps a server error', () async {
    when(() => dio.get<Map<String, dynamic>>('/products',
      queryParameters: any(named: 'queryParameters'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(requestOptions: RequestOptions(path: '/products'), statusCode: 500)));
    final result = await repository.getProducts(const ProductQuery());
    expect((result as Failed<ProductPage>).failure.kind, FailureKind.server);
  });

  test('repository maps an offline connection', () async {
    when(() => dio.get<Map<String, dynamic>>('/products',
      queryParameters: any(named: 'queryParameters'))).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError));
    final result = await repository.getProducts(const ProductQuery());
    expect((result as Failed<ProductPage>).failure.kind, FailureKind.network);
  });

  test('single product 404 becomes not-found failure', () async {
    when(() => dio.get<Map<String, dynamic>>('/products/9999')).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/products/9999'),
      response: Response(requestOptions: RequestOptions(path: '/products/9999'), statusCode: 404)));
    final result = await repository.getProduct(9999);
    expect((result as Failed<Product>).failure.kind, FailureKind.notFound);
  });

  test('search uses the search endpoint and query', () async {
    when(() => dio.get<Map<String, dynamic>>('/products/search',
      queryParameters: any(named: 'queryParameters'))).thenAnswer((_) async =>
        Response(data: fixture, requestOptions: RequestOptions(path: '/products/search')));
    await repository.getProducts(const ProductQuery(search: 'bag'));
    final captured = verify(() => dio.get<Map<String, dynamic>>('/products/search',
      queryParameters: captureAny(named: 'queryParameters'))).captured.single as Map<String, dynamic>;
    expect(captured['q'], 'bag');
    expect(captured['limit'], 20);
  });
}
