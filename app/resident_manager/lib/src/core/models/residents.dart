import "info.dart";

class Resident extends PublicInfo {
  Resident({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
  });
}
