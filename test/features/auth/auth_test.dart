import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/auth/presentation/auth_controller.dart';
import 'package:shopsphere/features/profile/domain/profile_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

const user = AuthUser(id: 1, firstName: 'Emily', lastName: 'Smith',
  email: 'emily@example.test', phone: '123', image: '');

void main() {
  late MockAuthRepository auth;
  late MockProfileRepository profile;
  setUp(() { auth = MockAuthRepository(); profile = MockProfileRepository(); });

  test('login use case validates before calling repository', () async {
    final result = await Login(auth)('a', 'b');
    expect((result as Failed<AuthUser>).failure.kind, FailureKind.validation);
    verifyNever(() => auth.login(any(), any()));
  });

  test('login use case trims username and returns repository result', () async {
    when(() => auth.login('emilys', 'emilyspass'))
      .thenAnswer((_) async => const Success(user));
    final result = await Login(auth)(' emilys ', 'emilyspass');
    expect((result as Success<AuthUser>).value.id, 1);
    verify(() => auth.login('emilys', 'emilyspass')).called(1);
  });

  test('bootstrap restores a valid session through the profile endpoint', () async {
    when(() => auth.hasSession()).thenAnswer((_) async => true);
    when(() => profile.me()).thenAnswer((_) async => const Success(user));
    final controller = AuthController(auth, Login(auth), profile);
    await controller.bootstrap();
    expect(controller.status, AuthStatus.signedIn);
    expect(controller.user?.fullName, 'Emily Smith');
  });

  test('bootstrap clears an expired session', () async {
    when(() => auth.hasSession()).thenAnswer((_) async => true);
    when(() => profile.me()).thenAnswer((_) async => const Failed(
      Failure(FailureKind.unauthorized, 'Expired')));
    when(() => auth.logout()).thenAnswer((_) async {});
    final controller = AuthController(auth, Login(auth), profile);
    await controller.bootstrap();
    expect(controller.status, AuthStatus.signedOut);
    verify(() => auth.logout()).called(1);
  });

  test('bootstrap keeps tokens on a transient network failure', () async {
    when(() => auth.hasSession()).thenAnswer((_) async => true);
    when(() => profile.me()).thenAnswer((_) async => const Failed(
      Failure(FailureKind.network, 'Offline')));
    final controller = AuthController(auth, Login(auth), profile);
    await controller.bootstrap();
    expect(controller.status, AuthStatus.restoreFailure);
    verifyNever(() => auth.logout());
  });

  test('sign in emits submitting then signed in', () async {
    final completer = Completer<Result<AuthUser>>();
    when(() => auth.login('emilys', 'emilyspass')).thenAnswer((_) => completer.future);
    final controller = AuthController(auth, Login(auth), profile);
    final states = <AuthStatus>[];
    controller.addListener(() => states.add(controller.status));
    final pending = controller.signIn('emilys', 'emilyspass');
    completer.complete(const Success(user));
    expect(await pending, isTrue);
    expect(states, [AuthStatus.submitting, AuthStatus.signedIn]);
  });
}
