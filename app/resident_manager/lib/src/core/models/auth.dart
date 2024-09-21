class Authorization {
  final String username;
  final String password;

  Authorization({
    required this.username,
    required this.password,
  });
}

class HashedAuthorization {
  final String username;
  final String hashedPassword;

  HashedAuthorization({
    required this.username,
    required this.hashedPassword,
  });
}
