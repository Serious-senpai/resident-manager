import "dart:async";
import "dart:convert";

import "auth.dart";
import "info.dart";
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
  static Future<List<RegisterRequest>> query({
    required ApplicationState state,
    required int offset,
    int? id,
    String? name,
    int? room,
    String? username,
    String? orderBy,
    bool? ascending,
  }) async {
    final result = <RegisterRequest>[];
    final authorization = state.authorization;
    if (authorization == null) {
      return result;
    }

    final response = await state.get(
      "/api/v1/admin/reg-request",
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
      result.addAll(data.map(RegisterRequest.fromJson));
    }

    return result;
  }

  /// Request the server to create a new registration request.
  ///
  /// Returns the status code of the HTTP request.
  static Future<int> create({
    required ApplicationState state,
    required PersonalInfo info,
    required Authorization authorization,
  }) async {
    final headers = authorization.constructHeaders();
    headers["content-type"] = "application/json";

    final response = await state.post(
      "/api/v1/register",
      queryParameters: info.personalInfoQuery(),
      headers: headers,
      authorize: false,
    );

    return response.statusCode;
  }

  static Future<bool> _approveOrReject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
    required String path,
  }) async {
    final headers = {"content-type": "application/json"};
    final data = List<Map<String, int>>.from(objects.map((o) => {"id": o.id}));

    final response = await state.post(path, headers: headers, body: json.encode(data));
    return response.statusCode == 204;
  }

  /// Approve a list of registration requests.
  static Future<bool> approve({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/reg-request/accept");
  }

  /// Reject a list of registration requests.
  static Future<bool> reject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/reg-request/reject");
  }

  /// Count the number of registration requests.
  static Future<int?> count({
    required ApplicationState state,
    int? id,
    String? name,
    int? room,
    String? username,
  }) async {
    final response = await state.get(
      "/api/v1/admin/reg-request/count",
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
