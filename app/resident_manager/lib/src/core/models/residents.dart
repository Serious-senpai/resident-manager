import "info.dart";

/// Represents a resident.
class Resident extends PublicInfo {
  /// Constructs a [Resident] object with the given [id], [name], [room], [birthday], [phone], and [email].
  Resident({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
  });

  Resident.fromJson(super.data) : super.fromJson();

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "room": room,
        "birthday": birthday?.toIso8601String(),
        "phone": phone,
        "email": email,
      };
}
