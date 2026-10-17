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
              error.requestOptions.extra['protected'] == true) {
            await tokenStore.clear();
            onSessionExpired?.call();
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
}
