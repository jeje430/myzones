enum AuthErrorType {
  userNotFound,
  wrongPassword,
  emailAlreadyRegistered,
}

class AuthException implements Exception {
  const AuthException(this.type, this.message);

  final AuthErrorType type;
  final String message;

  @override
  String toString() => message;
}
