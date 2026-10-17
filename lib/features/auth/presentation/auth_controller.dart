import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/auth.dart';

enum AuthStatus { checking, restoreFailure, signedOut, submitting, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(
    this.repository,
    this.loginUseCase,
    this.profileRepository, {
    this.onSessionCleared,
  });
  final AuthRepository repository;
  final Login loginUseCase;
  final ProfileRepository profileRepository;
  final Future<void> Function()? onSessionCleared;

  AuthStatus status = AuthStatus.checking;
  AuthUser? user;
  String? message;

  Future<void> bootstrap() async {
    status = AuthStatus.checking;
    notifyListeners();
    try {
      if (!await repository.hasSession()) {
        status = AuthStatus.signedOut;
      } else {
        final result = await profileRepository.me();
        if (result case Success<AuthUser>(:final value)) {
          user = value;
          status = AuthStatus.signedIn;
        } else {
          final failure = (result as Failed<AuthUser>).failure;
          if (failure.kind == FailureKind.unauthorized) {
            await repository.logout();
            await onSessionCleared?.call();
            status = AuthStatus.signedOut;
            message = failure.message;
          } else {
            status = AuthStatus.restoreFailure;
            message = failure.message;
          }
        }
      }
    } catch (_) {
      status = AuthStatus.restoreFailure;
      message = 'Could not restore your session. Please retry.';
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
    await onSessionCleared?.call();
    user = null;
    message = reason;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  void sessionExpired() {
    unawaited(onSessionCleared?.call() ?? Future<void>.value());
    user = null;
    message = 'Your session has expired. Please sign in again.';
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
