class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message);
  @override
  String toString() => 'NetworkException: $message';
}

class StorageException extends AppException {
  const StorageException(super.message);
  @override
  String toString() => 'StorageException: $message';
}

class GameLogicException extends AppException {
  const GameLogicException(super.message);
  @override
  String toString() => 'GameLogicException: $message';
}
