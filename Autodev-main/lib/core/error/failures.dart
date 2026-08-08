/// Base class for all domain-level failures returned by repositories.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class DeployFailure extends Failure {
  const DeployFailure(super.message);
}

class ApiKeyMissingFailure extends Failure {
  const ApiKeyMissingFailure(super.message);
}

/// Exceptions thrown by the data layer (datasources), caught by repositories
/// and converted into [Failure]s.
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class ParsingException implements Exception {
  final String message;
  ParsingException(this.message);
}

class DeployException implements Exception {
  final String message;
  DeployException(this.message);
}

class ApiKeyMissingException implements Exception {
  final String message;
  ApiKeyMissingException(this.message);
}
