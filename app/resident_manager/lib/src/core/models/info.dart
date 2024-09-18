/// Base class for objects holding personal information.
class PersonalInfo {
  final String name;
  final int room;
  final DateTime? birthday;
  final String? phone;
  final String? email;
  final String username;
  final String hashedPassword;

  const PersonalInfo({
    required this.name,
    required this.room,
    this.birthday,
    this.phone,
    this.email,
    required this.username,
    required this.hashedPassword,
  });
}
