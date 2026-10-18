import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/data/auth_repository_impl.dart';
import 'package:shopsphere/features/auth/data/auth_remote_data_source.dart';
import 'package:shopsphere/features/auth/data/token_store.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';

class MockDio extends Mock implements Dio {}

class MockTokenStore extends Mock implements TokenStore {}

void main() {
  late MockDio dio;
  late MockTokenStore store;
  late AuthRepositoryImpl repository;
  setUp(() {
    dio = MockDio();
    store = MockTokenStore();
    repository = AuthRepositoryImpl(DioAuthRemoteDataSource(dio), store);
  });

  test('login stores both tokens and parses the signed-in user', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {
          'id': 1,
          'firstName': 'Emily',
          'lastName': 'Smith',
          'email': 'emily@example.test',
          'phone': '123',
          'image': '',
          'accessToken': 'access',
          'refreshToken': 'refresh',
        },
      ),
    );
    when(() => store.save('access', 'refresh')).thenAnswer((_) async {});
    final result = await repository.login('emilys', 'emilyspass');
    expect((result as Success<AuthUser>).value.fullName, 'Emily Smith');
    verify(() => store.save('access', 'refresh')).called(1);
  });

  test('invalid credentials become a validation failure', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 400,
        ),
      ),
    );
    final result = await repository.login('emilys', 'wrongpass');
    expect((result as Failed<AuthUser>).failure.kind, FailureKind.validation);
    verifyNever(() => store.save(any(), any()));
  });

  test('network failure does not save a token', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.connectionError,
      ),
    );
    final result = await repository.login('emilys', 'emilyspass');
    expect((result as Failed<AuthUser>).failure.kind, FailureKind.network);
    verifyNever(() => store.save(any(), any()));
  });

  test('session is present only when access token is nonempty', () async {
    when(() => store.readAccessToken()).thenAnswer((_) async => '');
    expect(await repository.hasSession(), isFalse);
    when(() => store.readAccessToken()).thenAnswer((_) async => 'access');
    expect(await repository.hasSession(), isTrue);
  });
}
