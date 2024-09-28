import "dart:async";
import "dart:convert";

import "auth.dart";
import "info.dart";
import "snowflake.dart";
import "../state.dart";

class RegisterRequest extends PublicInfo {
  String? username;
  String? hashedPassword;

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

  RegisterRequest.fromJson(dynamic data) : super.fromJson(data) {
    username = data["username"] as String?;
    hashedPassword = data["hashed_password"] as String?;
  }

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
      for (final item in data) {
        result.add(RegisterRequest.fromJson(item));
      }
    }

    return result;
  }

  static Future<int> create({
    required ApplicationState state,
    required PersonalInfo info,
    required Authorization authorization,
  }) async {
    final headers = authorization.constructHeaders(await state.serverKey());
    headers["content-type"] = "application/json";

    final response = await state.post(
      "/api/v1/register",
      headers: headers,
      body: json.encode(info.personalInfoJson()),
      authorize: false,
    );

    if (response.statusCode == 401) {
      state.invalidateServerKey();
      return await create(state: state, info: info, authorization: authorization);
    }

    return response.statusCode;
  }

  static Future<bool> _approveOrReject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
    required String path,
  }) async {
    final headers = {"content-type": "application/json"};
    final data = <int>[];
    for (final object in objects) {
      data.add(object.id);
    }

    final response = await state.post(path, headers: headers, body: json.encode(data));
    return response.statusCode == 204;
  }

  static Future<bool> approve({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/reg-request/accept");
  }

  static Future<bool> reject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/v1/admin/reg-request/reject");
  }

  static Future<int?> count({required ApplicationState state}) async {
    final response = await state.get("/api/v1/admin/reg-request/count");
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
