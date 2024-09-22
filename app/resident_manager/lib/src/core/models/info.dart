import "snowflake.dart";

/// Data model for objects holding personal information.
class PersonalInfo {
  final String name;
  final int room;
  final DateTime? birthday;
  final String? phone;
  final String? email;

  const PersonalInfo({
    required this.name,
    required this.room,
    this.birthday,
    this.phone,
    this.email,
  });

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

  PublicInfo({
    required this.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
  });

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
