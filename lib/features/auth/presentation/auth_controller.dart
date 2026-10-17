import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/auth.dart';

enum AuthStatus { checking, signedOut, submitting, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this.repository, this.loginUseCase, this.profileRepository);
  final AuthRepository repository;
  final Login loginUseCase;
  final ProfileRepository profileRepository;

  AuthStatus status = AuthStatus.checking;
  AuthUser? user;
  String? message;

  Future<void> bootstrap() async {
    try {
      if (!await repository.hasSession()) {
        status = AuthStatus.signedOut;
      } else {
        final result = await profileRepository.me();
        if (result case Success<AuthUser>(:final value)) {
          user = value;
          status = AuthStatus.signedIn;
        } else {
          await repository.logout();
          status = AuthStatus.signedOut;
          message = 'Your session has expired. Please sign in again.';
        }
      }
    } catch (_) {
      status = AuthStatus.signedOut;
      message = 'Could not restore your session. Please sign in.';
    }
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    status = AuthStatus.submitting;
    message = null;
    notifyListeners();
    final result = await loginUseCase(username, password);
    if (result case Success<AuthUser>(:final value)) {
      user = value;
      status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    }
    message = (result as Failed<AuthUser>).failure.message;
    status = AuthStatus.signedOut;
    notifyListeners();
    return false;
  }

  Future<void> signOut({String? reason}) async {
    await repository.logout();
    user = null;
    message = reason;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  void sessionExpired() {
    user = null;
    message = 'Your session has expired. Please sign in again.';
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
