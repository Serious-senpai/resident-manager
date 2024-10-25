class _HasUsername {
  /// The username for authentication.
  final String username;

  _HasUsername({required this.username});
}

/// Represents authorization data, which consists of a username and a raw password.
class Authorization extends _HasUsername {
  /// The password for authentication.
  final String password;

  /// Constructs an [Authorization] object with the given [username] and [password].
  Authorization({
    required super.username,
    required this.password,
  });
}

/// Represents authorization data, which consists of a username and a hashed password.
///
/// The password is hashed on the server side.
class HashedAuthorization extends _HasUsername {
  /// The hashed password for authentication.
  final String hashedPassword;

  /// Constructs a [HashedAuthorization] object with the given [username] and [hashedPassword].
  HashedAuthorization({
    required super.username,
    required this.hashedPassword,
  });
}
