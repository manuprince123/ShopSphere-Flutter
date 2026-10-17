import '../../../core/error/failure.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.image,
  });
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String image;
  String get fullName => '$firstName $lastName'.trim();
}

abstract interface class AuthRepository {
  Future<bool> hasSession();
  Future<Result<AuthUser>> login(String username, String password);
  Future<void> logout();
}

class Login {
  const Login(this.repository);
  final AuthRepository repository;
  Future<Result<AuthUser>> call(String username, String password) {
    if (username.trim().length < 3 || password.length < 6) {
      return Future.value(
        const Failed(
          Failure(
            FailureKind.validation,
            'Enter a username (3+ characters) and password (6+ characters).',
          ),
        ),
      );
    }
    return repository.login(username.trim(), password);
  }
}
