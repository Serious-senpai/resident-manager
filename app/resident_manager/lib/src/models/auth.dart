import "dart:convert";

import "package:pinenacl/x25519.dart";

import "../config.dart";

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

  /// Constructs authorization headers to send to the server side for authentication.
  ///
  /// The password is encrypted using the server's public key and our key pair from
  /// the Curve25519 algorithm.
  Map<String, String> constructHeaders() {
    final privateKey = PrivateKey.generate();
    final publicKey = privateKey.publicKey;

    final box = Box(myPrivateKey: privateKey, theirPublicKey: serverKey);

    return {
      "username": username,
      "encrypted": base64.encode(box.encrypt(utf8.encode(password))),
      "pkey": base64.encode(publicKey),
    };
  }
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
