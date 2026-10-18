import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/token_store.dart';

class ApiClient {
  ApiClient(this.tokenStore, {void Function()? onSessionExpired})
    : dio = Dio(
        BaseOptions(
          baseUrl: 'https://dummyjson.com',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 8),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['protected'] == true) {
            final token = await tokenStore.readAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['protected'] == true &&
              error.requestOptions.extra['retriedAfterRefresh'] != true) {
            String? refreshed;
            try {
              refreshed = await _refreshAccessToken();
            } on DioException catch (refreshError) {
              final status = refreshError.response?.statusCode;
              if (status != null && status >= 400 && status < 500) {
                await _expireSession(onSessionExpired);
              }
              handler.next(refreshError);
              return;
            }
            if (refreshed != null) {
              final request = error.requestOptions;
              request.extra['retriedAfterRefresh'] = true;
              request.headers['Authorization'] = 'Bearer $refreshed';
              try {
                handler.resolve(await dio.fetch<dynamic>(request));
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            } else {
              await _expireSession(onSessionExpired);
            }
          }
          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('HTTP ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              'HTTP ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              'HTTP ${error.response?.statusCode} ${error.requestOptions.uri}',
            );
            handler.next(error);
          },
        ),
      );
    }
  }

  final TokenStore tokenStore;
  final Dio dio;

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken, 'expiresInMins': 30},
    );
    final data = response.data!;
    final accessToken = data['accessToken'] as String;
    await tokenStore.save(
      accessToken,
      data['refreshToken'] as String? ?? refreshToken,
    );
    return accessToken;
  }

  Future<void> _expireSession(void Function()? onSessionExpired) async {
    await tokenStore.clear();
    onSessionExpired?.call();
  }
}
