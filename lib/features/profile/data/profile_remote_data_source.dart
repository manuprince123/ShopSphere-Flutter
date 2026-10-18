import 'package:dio/dio.dart';

import '../../auth/data/auth_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<AuthUserModel> getProfile();
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  const DioProfileRemoteDataSource(this.dio);

  final Dio dio;

  @override
  Future<AuthUserModel> getProfile() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(extra: {'protected': true}),
    );
    return AuthUserModel.fromJson(response.data!);
  }
}
