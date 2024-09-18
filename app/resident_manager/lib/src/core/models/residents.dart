import "info.dart";
import "../config.dart";

class Resident extends PersonalInfo {
  final int id;

  Resident({
    required this.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
    required super.username,
    required super.hashedPassword,
  });

  static Resident fromJson(dynamic data) {
    return Resident(
      id: data["id"],
      name: data["name"],
      room: data["room"],
      birthday: data["birthday"] != null ? epoch.add(Duration(milliseconds: data["birthday"])) : null,
      phone: data["phone"],
      email: data["email"],
      username: data["username"],
      hashedPassword: data["hashedPassword"],
    );
  }
}
