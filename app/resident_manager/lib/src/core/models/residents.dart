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

    final params = {"offset": offset.toString()};
    if (id != null) {
      params["id"] = id.toString();
    }
    if (name != null && name.isNotEmpty) {
      params["name"] = name;
    }
    if (room != null) {
      params["room"] = room.toString();
    }
    if (username != null && username.isNotEmpty) {
      params["username"] = username;
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      params["order_by"] = orderBy;
    }
    if (ascending != null) {
      params["ascending"] = ascending.toString();
    }

    final response = await state.get("/api/v1/admin/residents", queryParameters: params);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      result.addAll(data.map(Resident.fromJson));
    }

    return result;
  }

  /// Count the number of residents.
  static Future<int?> count({required ApplicationState state}) async {
    final response = await state.get("/api/v1/admin/residents/count");
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
