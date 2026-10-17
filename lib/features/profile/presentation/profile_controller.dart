import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../auth/domain/auth.dart';
import '../domain/profile_repository.dart';

enum ProfileStatus { loading, ready, failure }

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository);
  final ProfileRepository repository;
  ProfileStatus status = ProfileStatus.loading;
  AuthUser? user;
  Failure? failure;
  bool _disposed = false;

  Future<void> load() async {
    status = ProfileStatus.loading;
    failure = null;
    notifyListeners();
    final result = await repository.me();
    if (_disposed) return;
    if (result case Success<AuthUser>(:final value)) {
      user = value;
      status = ProfileStatus.ready;
    } else {
      failure = (result as Failed<AuthUser>).failure;
      status = ProfileStatus.failure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
