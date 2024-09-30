import "dart:async";
import "dart:convert";

import "auth.dart";
import "info.dart";
import "snowflake.dart";
import "../state.dart";

/// Represents a registration request.
class RegisterRequest extends PublicInfo {
  /// The username for the registration request, this data is only available from the admin endpoint.
  String? username;

  /// The hashed password for the registration request, this data is only available from the admin endpoint.
  String? hashedPassword;

  /// Constructs a [RegisterRequest] object with the given [id], [name], [room], [birthday], [phone], [email], [username],
  /// and [hashedPassword].
  RegisterRequest({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
    this.username,
    this.hashedPassword,
  });

  /// Constructs a [RegisterRequest] object from a JSON object.
  RegisterRequest.fromJson(dynamic data) : super.fromJson(data) {
    username = data["username"] as String?;
    hashedPassword = data["hashed_password"] as String?;
  }

  /// Queries the server for registration requests.
  ///
  /// If [state] hasn't been authorized as an administratoor yet, the result will always be empty.
  static Future<List<RegisterRequest>> query({
    required ApplicationState state,
    required int offset,
    String? name,
    int? room,
  }) async {
    final result = <RegisterRequest>[];
    final authorization = state.authorization;
    if (authorization == null) {
      return result;
    }

    final params = {"offset": offset.toString()};
    if (name != null && name.isNotEmpty) {
      params["name"] = name;
    }
    if (room != null) {
      params["room"] = room.toString();
    }

    final response = await state.get("/api/v1/admin/reg-request", queryParameters: params);
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
      headers: headers,
      body: json.encode(info.personalInfoJson()),
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
    final data = objects.map((o) => o.id);

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
  static Future<int?> count({required ApplicationState state}) async {
    final response = await state.get("/api/v1/admin/reg-request/count");
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
