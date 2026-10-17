import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shopsphere/features/auth/domain/auth.dart';
import 'package:shopsphere/features/auth/presentation/auth_controller.dart';
import 'package:shopsphere/features/auth/presentation/login_page.dart';
import 'package:shopsphere/features/profile/domain/profile_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  testWidgets('login validates both fields without sending a request', (tester) async {
    final repository = MockAuthRepository();
    final controller = AuthController(repository, Login(repository), MockProfileRepository());
    await tester.pumpWidget(ChangeNotifierProvider.value(value: controller,
      child: const MaterialApp(home: LoginPage())));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter at least 3 characters'), findsOneWidget);
    expect(find.text('Enter at least 6 characters'), findsOneWidget);
    verifyNever(() => repository.login(any(), any()));
  });

  testWidgets('login remains laid out at 1.3x text on a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MockAuthRepository();
    final controller = AuthController(repository, Login(repository), MockProfileRepository());
    await tester.pumpWidget(ChangeNotifierProvider.value(value: controller,
      child: const MaterialApp(home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: LoginPage(),
      ))));
    expect(tester.takeException(), isNull);
  });
}
