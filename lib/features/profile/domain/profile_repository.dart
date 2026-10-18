import '../../../core/error/failure.dart';
import '../../auth/domain/auth.dart';

abstract interface class ProfileRepository {
  Future<Result<AuthUser>> me();
}

class GetProfile {
  const GetProfile(this.repository);
  final ProfileRepository repository;
  Future<Result<AuthUser>> call() => repository.me();
}
