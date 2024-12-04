import "dart:async";
import "dart:convert";

import "auth.dart";
import "info.dart";
import "results.dart";
import "snowflake.dart";
import "../state.dart";

/// Represents a registration request.
class RegisterRequest extends PublicInfo {
  /// Constructs a [RegisterRequest] object with the given [id], [name], [room], [birthday], [phone], [email], [username],
  /// and [hashedPassword].
  RegisterRequest({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
    super.username,
    super.hashedPassword,
  });

  /// Constructs a [RegisterRequest] object from a JSON object.
  RegisterRequest.fromJson(super.data) : super.fromJson();

  /// Queries the server for registration requests.
  ///
  /// If [state] hasn't been authorized as an administratoor yet, the result will always be empty.
  static Future<Result<List<RegisterRequest>?>> query({
    required ApplicationState state,
    required int offset,
    DateTime? createdAfter,
    DateTime? createdBefore,
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
      "/api/v1/admin/registration-requests",
      queryParameters: {
        "offset": offset.toString(),
        if (createdAfter != null) "created_after": createdAfter.toIso8601String(),
        if (createdBefore != null) "created_before": createdBefore.toIso8601String(),
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
      return Result(0, List<RegisterRequest>.from(data.map(RegisterRequest.fromJson)));
    }

    return Result(result["code"], null);
  }

  /// Request the server to create a new registration request.
  static Future<Result<void>> create({
    required ApplicationState state,
    required PersonalInfo info,
    required Authorization authorization,
  }) async {
    final headers = {
      "username": authorization.username,
      "password": authorization.password,
      "content-type": "application/json",
    };

    final response = await state.post(
      "/api/v1/register",
      queryParameters: info.personalInfoQuery(),
      headers: headers,
      authorize: false,
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    return Result(data["code"], null);
  }

  static Future<Result<void>?> _approveOrReject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
    required String path,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
    }

    final response = await state.post(
      path,
      body: json.encode(List<Map<String, int>>.from(objects.map((o) => {"id": o.id}))),
      headers: {"content-type": "application/json"},
    );

    if (response.statusCode == 204) {
      return null;
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    return Result(data["code"], null);
  }

  /// Approve a list of registration requests.
  static Future<Result<void>?> approve({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/registration-requests/accept");
  }

  /// Reject a list of registration requests.
  static Future<Result<void>?> reject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/registration-requests/reject");
  }

  /// Count the number of registration requests.
  static Future<Result<int?>> count({
    required ApplicationState state,
    int? id,
    String? name,
    int? room,
    String? username,
  }) async {
    final response = await state.get(
      "/api/v1/admin/registration-requests/count",
      queryParameters: {
        if (id != null) "id": id.toString(),
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
