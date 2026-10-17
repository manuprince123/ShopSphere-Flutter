import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/core/error/failure.dart';
import 'package:shopsphere/core/error/failure_mapper.dart';

void main() {
  final request = RequestOptions(path: '/test');
  DioException status(int code) => DioException(requestOptions: request,
    response: Response(requestOptions: request, statusCode: code));

  test('maps a 400 login response to friendly validation feedback', () {
    expect(mapFailure(status(400)).kind, FailureKind.validation);
    expect(mapFailure(status(400)).message, 'Invalid username or password.');
  });
  test('maps 401 to session expiry', () {
    expect(mapFailure(status(401)).kind, FailureKind.unauthorized);
  });
  test('maps missing products to not found', () {
    expect(mapFailure(status(404)).kind, FailureKind.notFound);
  });
  test('maps server errors to a retryable message', () {
    expect(mapFailure(status(500)).kind, FailureKind.server);
  });
  test('maps a connection timeout distinctly', () {
    expect(mapFailure(DioException(requestOptions: request,
      type: DioExceptionType.connectionTimeout)).kind, FailureKind.timeout);
  });
  test('maps a socket exception to offline feedback', () {
    expect(mapFailure(DioException(requestOptions: request,
      error: const SocketException('offline'))).kind, FailureKind.network);
  });
  test('maps invalid payloads to a parsing error', () {
    expect(mapFailure(const FormatException('invalid')).kind, FailureKind.unknown);
  });
}
