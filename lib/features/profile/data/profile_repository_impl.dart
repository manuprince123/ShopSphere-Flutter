import 'package:dio/dio.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../auth/domain/auth.dart';
import '../domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this.dio);
  final Dio dio;

  @override
  Future<Result<AuthUser>> me() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(extra: {'protected': true}),
      );
      final data = response.data!;
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
}
