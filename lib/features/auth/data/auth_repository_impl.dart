import '../../../core/error/failure.dart';
import '../../../core/error/failure_mapper.dart';
import '../domain/auth.dart';
import 'auth_remote_data_source.dart';
import 'token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this.remoteDataSource, this.tokenStore);
  final AuthRemoteDataSource remoteDataSource;
  final TokenStore tokenStore;

  @override
  Future<bool> hasSession() async =>
      (await tokenStore.readAccessToken())?.isNotEmpty == true;

  @override
  Future<Result<AuthUser>> login(String username, String password) async {
    try {
      final session = await remoteDataSource.login(username, password);
      await tokenStore.save(session.accessToken, session.refreshToken);
      return Success(session.user);
    } catch (error) {
      return Failed(mapFailure(error));
    }
  }

  @override
  Future<void> logout() => tokenStore.clear();
}
