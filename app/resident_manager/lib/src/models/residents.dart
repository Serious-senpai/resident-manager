import "dart:convert";

import "info.dart";
import "../state.dart";

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
    super.username,
    super.hashedPassword,
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

  static Future<List<Resident>> query({
    required ApplicationState state,
    required int offset,
    int? id,
    String? name,
    int? room,
    String? username,
    String? orderBy,
    bool? ascending,
  }) async {
    final result = <Resident>[];
    final authorization = state.authorization;
    if (authorization == null) {
      return result;
    }

    final response = await state.get(
      "/api/v1/admin/residents",
      queryParameters: {
        "offset": offset.toString(),
        if (id != null) "id": id.toString(),
        if (name != null && name.isNotEmpty) "name": name,
        if (room != null) "room": room.toString(),
        if (username != null && username.isNotEmpty) "username": username,
        if (orderBy != null && orderBy.isNotEmpty) "order_by": orderBy,
        if (ascending != null) "ascending": ascending.toString(),
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      result.addAll(data.map(Resident.fromJson));
    }

    return result;
  }

  /// Count the number of residents.
  static Future<int?> count({
    required ApplicationState state,
    int? id,
    String? name,
    int? room,
    String? username,
  }) async {
    final response = await state.get(
      "/api/v1/admin/residents/count",
      queryParameters: {
        if (id != null) "id": id.toString(),
        if (name != null && name.isNotEmpty) "name": name,
        if (room != null) "room": room.toString(),
        if (username != null && username.isNotEmpty) "username": username,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
