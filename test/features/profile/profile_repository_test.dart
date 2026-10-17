import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/profile/data/profile_repository_impl.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProfileRepositoryImpl repository;
  setUpAll(() => registerFallbackValue(Options()));
  setUp(() {
    dio = MockDio();
    repository = ProfileRepositoryImpl(dio);
  });

  test('profile request is protected and parses contact fields', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        data: {
          'id': 1,
          'firstName': 'Emily',
          'lastName': 'Johnson',
          'email': 'emily@example.test',
          'phone': '555-0101',
          'image': 'https://example.test/avatar.png',
        },
      ),
    );
    final result = await repository.me();
    expect((result as Success<AuthUser>).value.phone, '555-0101');
    final options =
        verify(
              () => dio.get<Map<String, dynamic>>(
                '/auth/me',
                options: captureAny(named: 'options'),
              ),
            ).captured.single
            as Options;
    expect(options.extra?['protected'], isTrue);
  });

  test('expired profile request yields unauthorized failure', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 401,
        ),
      ),
    );
    final result = await repository.me();
    expect((result as Failed<AuthUser>).failure.kind, FailureKind.unauthorized);
  });
}
