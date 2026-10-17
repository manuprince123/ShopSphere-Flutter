import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/auth.dart';
import 'token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.dio, this.tokenStore);
  final Dio dio;
  final TokenStore tokenStore;

  @override
  Future<bool> hasSession() async =>
      (await tokenStore.readAccessToken())?.isNotEmpty == true;

  @override
  Future<Result<AuthUser>> login(String username, String password) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password, 'expiresInMins': 30},
      );
      final data = response.data!;
      await tokenStore.save(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return Success(
        AuthUser(
          id: data['id'] as int,
          firstName: data['firstName'] as String? ?? '',
          lastName: data['lastName'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          image: data['image'] as String? ?? '',
        ),
      );
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }

  @override
  Future<void> logout() => tokenStore.clear();
}
