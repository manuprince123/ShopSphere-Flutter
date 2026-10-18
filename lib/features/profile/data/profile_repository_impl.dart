import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../../auth/domain/auth.dart';
import '../domain/profile_repository.dart';
import 'profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this.remoteDataSource);
  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<AuthUser>> me() async {
    try {
      return Success(await remoteDataSource.getProfile());
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }
}
