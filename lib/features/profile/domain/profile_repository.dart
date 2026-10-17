import '../../../core/error/failure.dart';
import '../../auth/domain/auth.dart';

abstract interface class ProfileRepository {
  Future<Result<AuthUser>> me();
}
