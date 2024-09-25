import "dart:async";
import "dart:convert";

import "auth.dart";
import "info.dart";
import "snowflake.dart";
import "../state.dart";

class RegisterRequest extends PublicInfo {
  RegisterRequest({
    required super.id,
    required super.name,
    required super.room,
    super.birthday,
    super.phone,
    super.email,
  });

  RegisterRequest.fromJson(super.data) : super.fromJson();

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

    final response = await state.http.apiGet(
      "/api/admin/reg-request",
      queryParameters: params,
      headers: authorization.headers,
    );

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
    final headers = authorization.headers;
    headers["content-type"] = "application/json";

    final response = await state.http.apiPost(
      "/api/register",
      headers: headers,
      body: json.encode(info.personalInfoJson()),
    );

    return response.statusCode;
  }

  static Future<bool> _approveOrReject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
    required String path,
  }) async {
    final headers = state.authorization?.headers;
    if (headers == null) {
      return false;
    }

    headers["content-type"] = "application/json";
    final data = <int>[];
    for (final object in objects) {
      data.add(object.id);
    }

    final response = await state.http.apiPost(
      path,
      headers: headers,
      body: json.encode(data),
    );
    return response.statusCode == 204;
  }

  static Future<bool> approve({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/admin/reg-request/accept");
  }

  static Future<bool> reject({
    required ApplicationState state,
    required Iterable<Snowflake> objects,
  }) {
    return _approveOrReject(state: state, objects: objects, path: "/api/admin/reg-request/reject");
  }

  static Future<int?> count({required ApplicationState state}) async {
    final headers = state.authorization?.headers;
    if (headers == null) {
      return null;
    }

    final response = await state.http.apiGet("/api/admin/reg-request/count", headers: headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
