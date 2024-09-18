abstract class ResidentManagerException implements Exception {
  abstract final String message;

  @override
  String toString() {
    return message;
  }
}

class AuthorizationError implements ResidentManagerException {
  @override
  final String message;

  AuthorizationError(this.message);
}
