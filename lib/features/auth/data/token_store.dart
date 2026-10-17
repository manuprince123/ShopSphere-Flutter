import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> save(String accessToken, String refreshToken);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this.storage);
  final FlutterSecureStorage storage;

  @override
  Future<String?> readAccessToken() => storage.read(key: 'access_token');
  @override
  Future<String?> readRefreshToken() => storage.read(key: 'refresh_token');
  @override
  Future<void> save(String accessToken, String refreshToken) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }

  @override
  Future<void> clear() => storage.deleteAll();
}
