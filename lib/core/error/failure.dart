enum FailureKind {
  network,
  timeout,
  unauthorized,
  notFound,
  server,
  validation,
  unknown,
}

class Failure {
  const Failure(this.kind, this.message);

  final FailureKind kind;
  final String message;

  @override
  String toString() => 'Failure($kind, $message)';
}

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
