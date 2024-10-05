import "dart:convert";

import "package:pinenacl/x25519.dart";

final epoch = DateTime.utc(2024, 1, 1);
const int DB_PAGINATION_QUERY = 50;
final serverKey = PublicKey(base64.decode("FUgK7Fi7O7eSDi5Ekd/hbmjIN3k/WcLevFTgZqmn9Bo="));
const DEFAULT_ADMIN_USERNAME = "admin";
const DEFAULT_ADMIN_PASSWORD = "NgaiLongGey";
