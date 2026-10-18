import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/profile/domain/profile_repository.dart';
import 'package:shopsphere/features/profile/presentation/profile_controller.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

const user = AuthUser(
  id: 1,
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@example.test',
  phone: '123',
  image: '',
);

void main() {
  test('profile transitions from loading to ready', () async {
    final repository = MockProfileRepository();
    final completer = Completer<Result<AuthUser>>();
    when(() => repository.me()).thenAnswer((_) => completer.future);
    final controller = ProfileController(GetProfile(repository));
    final states = <ProfileStatus>[];
    controller.addListener(() => states.add(controller.status));
    final pending = controller.load();
    completer.complete(const Success(user));
    await pending;
    expect(states, [ProfileStatus.loading, ProfileStatus.ready]);
    expect(controller.user?.phone, '123');
  });

  test('profile surfaces a retryable failure', () async {
    final repository = MockProfileRepository();
    when(() => repository.me()).thenAnswer(
      (_) async => const Failed(Failure(FailureKind.server, 'Try again')),
    );
    final controller = ProfileController(GetProfile(repository));
    await controller.load();
    expect(controller.status, ProfileStatus.failure);
    expect(controller.failure?.kind, FailureKind.server);
  });
}
