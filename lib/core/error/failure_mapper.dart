import 'dart:io';

import 'package:dio/dio.dart';

import 'failure.dart';

Failure mapFailure(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const Failure(FailureKind.timeout, 'The request took too long. Please try again.');
    }
    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionError) {
      return const Failure(FailureKind.network, 'You appear to be offline. Check your connection and retry.');
    }
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) {
      return const Failure(FailureKind.unauthorized, 'Your session has expired. Please sign in again.');
    }
    if (status == 404) {
      return const Failure(FailureKind.notFound, 'Product not found.');
    }
    if (status == 400) {
      return const Failure(FailureKind.validation, 'Invalid username or password.');
    }
    if (status != null && status >= 500) {
      return const Failure(FailureKind.server, 'The store is having trouble right now. Please retry.');
    }
  }
  if (error is FormatException || error is TypeError) {
    return const Failure(FailureKind.unknown, 'We could not read the server response. Please retry.');
  }
  return const Failure(FailureKind.unknown, 'Something went wrong. Please retry.');
}
