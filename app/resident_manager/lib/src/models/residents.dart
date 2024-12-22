import "dart:convert";

import "info.dart";
import "results.dart";
import "snowflake.dart";
import "../state.dart";

/// Represents a resident.
class Resident extends PublicInfo {
  /// Constructs a [Resident] object with the given [id], [name], [room], [birthday], [phone], and [email].
  Resident({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    required super.phone,
    super.email,
    super.username,
    super.hashedPassword,
  });

  /// Creates a `Resident` instance from a JSON object.
  ///
  /// The constructor takes a JSON object and initializes the `Resident`
  /// instance by calling the `fromJson` method of the superclass.
  ///
  /// - Parameter data: A JSON object containing the resident data.
  Resident.fromJson(super.data) : super.fromJson();

  /// Converts the Resident object to a JSON map.
  ///
  /// This method serializes the Resident object into a map of key-value pairs,
  /// where the keys are strings and the values are dynamic. This is useful for
  /// encoding the object to be sent over a network or to be stored in a database.
  ///
  /// Returns a `Map<String, dynamic>` representing the JSON serialization of the Resident object.
  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "room": room,
        "birthday": birthday?.format("yyyy-mm-dd"),
        "phone": phone,
        "email": email,
      };

  /// Updates a resident's information.
  ///
  /// Returns a [Result] containing the updated [Resident] if the update is successful,
  /// or `null` if the update fails.
  Future<Result<Resident?>> update({
    required ApplicationState state,
    required PersonalInfo info,
  }) async {
    final response = await state.post(
      state.loggedInAsAdmin ? "/api/v1/admin/residents/update" : "/api/v1/residents/update",
      queryParameters: {"id": id.toString()},
      headers: {"content-type": "application/json"},
      body: json.encode(info.toJson()),
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Result(0, Resident.fromJson(result["data"]));
    }

    return Result(result["code"], null);
  }

  Future<Result?> updateAuthorization({
    required ApplicationState state,
    required String newUsername,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await state.post(
      "/api/v1/residents/update-authorization",
      headers: {"content-type": "application/json"},
      body: json.encode(
        {
          "new_username": newUsername,
          "old_password": oldPassword,
          "new_password": newPassword,
        },
      ),
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Result(0, Resident.fromJson(result["data"]));
    }

    return Result(result["code"], null);
  }

  /// Deletes a resident.
  ///
  /// This method deletes a resident from the database.
  ///
  /// Returns a [Future] that completes with a boolean value indicating
  /// whether the deletion was successful.
  static Future<bool> delete({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) async {
    final headers = {"content-type": "application/json"};
    final data = List<Map<String, int>>.from(objects.map((o) => {"id": o.id}));

    final response = await state.post("/api/v1/admin/residents/delete", headers: headers, body: json.encode(data));
    return response.statusCode == 204;
  }

  /// Queries the list of residents.
  ///
  /// Returns a [Result] containing a list of [Resident] objects or `null`.
  ///
  /// The query can be customized using the provided parameters.
  ///
  /// Returns:
  /// - A [Result] object containing a list of [Resident] objects if the query is successful.
  /// - A [Result] object containing null if the query fails.
  static Future<Result<List<Resident>?>> query({
    required ApplicationState state,
    required int offset,
    int? id,
    String? name,
    int? room,
    String? username,
    String? orderBy,
    bool? ascending,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
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
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<Resident>.from(data.map(Resident.fromJson)));
    }

    return Result(result["code"], null);
  }

  /// Count the number of residents.
  static Future<Result<int?>> count({
    required ApplicationState state,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? name,
    int? room,
    String? username,
  }) async {
    final response = await state.get(
      "/api/v1/admin/residents/count",
      queryParameters: {
        if (createdAfter != null) "created_after": createdAfter.toIso8601String(),
        if (createdBefore != null) "created_before": createdBefore.toIso8601String(),
        if (name != null && name.isNotEmpty) "name": name,
        if (room != null) "room": room.toString(),
        if (username != null && username.isNotEmpty) "username": username,
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Result(0, result["data"]);
    }

    return Result(result["code"], null);
  }
}
