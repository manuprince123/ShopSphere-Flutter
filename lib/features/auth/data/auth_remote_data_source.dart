import 'package:dio/dio.dart';

import 'auth_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSessionModel> login(String username, String password);
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this.dio);

  final Dio dio;

  @override
  Future<AuthSessionModel> login(String username, String password) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password, 'expiresInMins': 30},
    );
    return AuthSessionModel.fromJson(response.data!);
  }
}
