import "dart:convert";

import "package:pinenacl/x25519.dart";

class Authorization {
  final String username;
  final String password;

  Authorization({
    required this.username,
    required this.password,
  });

  Map<String, String> constructHeaders(PublicKey serverKey) {
    final privateKey = PrivateKey.generate();
    final publicKey = privateKey.publicKey;

    final box = Box(myPrivateKey: privateKey, theirPublicKey: serverKey);

    return {
      "username": username,
      "encrypted": base64.encode(box.encrypt(utf8.encode(password))),
      "public_key": base64.encode(publicKey),
    };
  }
}

class HashedAuthorization {
  final String username;
  final String hashedPassword;

  HashedAuthorization({
    required this.username,
    required this.hashedPassword,
  });
}
