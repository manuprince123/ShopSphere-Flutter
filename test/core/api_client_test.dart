import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/network/api_client.dart';
import 'package:shopsphere/features/auth/data/token_store.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    cleared = true;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> save(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

class StubHttpClientAdapter implements HttpClientAdapter {
  StubHttpClientAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test('401 refreshes tokens and retries the protected request once', () async {
    final store = MemoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'valid-refresh',
    );
    final client = ApiClient(store);
    var profileCalls = 0;
    client.dio.httpClientAdapter = StubHttpClientAdapter((options) {
      if (options.path == '/auth/refresh') {
        expect(options.data['refreshToken'], 'valid-refresh');
        return jsonResponse(200, {
          'accessToken': 'fresh-access',
          'refreshToken': 'fresh-refresh',
        });
      }
      if (options.path == '/auth/me') {
        profileCalls++;
        if (profileCalls == 1) {
          expect(options.headers['Authorization'], 'Bearer expired-access');
          return jsonResponse(401, {'message': 'Token expired'});
        }
        expect(options.headers['Authorization'], 'Bearer fresh-access');
        return jsonResponse(200, {'id': 1});
      }
      return jsonResponse(404, {});
    });

    final response = await client.dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(extra: {'protected': true}),
    );

    expect(response.data?['id'], 1);
    expect(profileCalls, 2);
    expect(store.accessToken, 'fresh-access');
    expect(store.refreshToken, 'fresh-refresh');
    expect(store.cleared, isFalse);
  });

  test('403 from refresh clears the session and announces expiry', () async {
    final store = MemoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'bad-refresh',
    );
    var expired = false;
    final client = ApiClient(store, onSessionExpired: () => expired = true);
    client.dio.httpClientAdapter = StubHttpClientAdapter((options) {
      if (options.path == '/auth/refresh') {
        return jsonResponse(403, {'message': 'Invalid refresh token'});
      }
      return jsonResponse(401, {'message': 'Token expired'});
    });

    await expectLater(
      client.dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(extra: {'protected': true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(store.cleared, isTrue);
    expect(expired, isTrue);
  });
}
