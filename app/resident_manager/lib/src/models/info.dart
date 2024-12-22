import "snowflake.dart";

import "../utils.dart";

/// Data model for objects holding personal information.
class PersonalInfo {
  /// The target's full name.
  final String name;

  /// The target's room number.
  final int room;

  /// The target's date of birth.
  final Date? birthday;

  /// The target's phone number.
  final String phone;

  /// The target's email address.
  final String? email;

  /// Constructs a [PersonalInfo] object with the given [name], [room], [birthday], [phone], and [email].
  const PersonalInfo({
    required this.name,
    required this.room,
    this.birthday,
    required this.phone,
    this.email,
  });

  /// Convert this object into a JSON-encodable map.
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "room": room,
      "birthday": birthday?.format("yyyy-mm-dd"),
      "phone": phone,
      "email": email,
    };
  }

  /// Generates a map containing personal information query parameters.
  ///
  /// This method returns a [Map] where the keys and values are both [String]s.
  /// The keys represent the parameter names, and the values represent the
  /// corresponding parameter values.
  ///
  /// Returns:
  ///   A map containing the personal information query parameters.
  Map<String, String> personalInfoQuery() {
    return {
      "name": name,
      "room": room.toString(),
      if (birthday != null) "birthday": birthday!.format("yyyy-mm-dd"),
      "phone": phone,
      if (email != null) "email": email!,
    };
  }
}

/// Data model for objects holding personal info along with a snowflake ID.
class PublicInfo extends PersonalInfo with Snowflake {
  @override
  final int id;

  /// The username information, this data is not always available.
  String? username;

  /// The hashed password information, this data is not always available.
  String? hashedPassword;

  /// Constructs a [PublicInfo] object with the given [id], [name], [room], [birthday], [phone], and [email].
  PublicInfo({
    required this.id,
    required super.name,
    required super.room,
    super.birthday,
    required super.phone,
    super.email,
    this.username,
    this.hashedPassword,
  });

  /// Constructs a [PublicInfo] object from a JSON object.
  PublicInfo.fromJson(dynamic data)
      : this(
          id: data["id"] as int,
          name: data["name"] as String,
          room: data["room"] as int,
          birthday: data["birthday"] == null ? null : Date.parse(data["birthday"] as String),
          phone: data["phone"] as String,
          email: data["email"] as String?,
          username: data["username"] as String?,
          hashedPassword: data["hashed_password"] as String?,
        );
}
