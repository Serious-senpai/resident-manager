import "snowflake.dart";

/// Data model for objects holding personal information.
class PersonalInfo {
  /// The target's full name.
  final String name;

  /// The target's room number.
  final int room;

  /// The target's date of birth.
  final DateTime? birthday;

  /// The target's phone number.
  final String? phone;

  /// The target's email address.
  final String? email;

  /// Constructs a [PersonalInfo] object with the given [name], [room], [birthday], [phone], and [email].
  const PersonalInfo({
    required this.name,
    required this.room,
    this.birthday,
    this.phone,
    this.email,
  });

  /// Convert this object into a JSON-encodable map.
  Map<String, dynamic> personalInfoJson() {
    return {
      "name": name,
      "room": room,
      "birthday": birthday?.toIso8601String(),
      "phone": phone,
      "email": email,
    };
  }
}

/// Data model for objects holding personal info along with a snowflake ID.
class PublicInfo extends PersonalInfo with Snowflake {
  @override
  final int id;

  /// Constructs a [PublicInfo] object with the given [id], [name], [room], [birthday], [phone], and [email].
  PublicInfo({
    required this.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
  });

  /// Constructs a [PublicInfo] object from a JSON object.
  PublicInfo.fromJson(dynamic data)
      : this(
          id: data["id"] as int,
          name: data["name"] as String,
          room: data["room"] as int,
          birthday: data["birthday"] == null ? null : DateTime.parse(data["birthday"] as String),
          phone: data["phone"] as String?,
          email: data["email"] as String?,
        );
}
