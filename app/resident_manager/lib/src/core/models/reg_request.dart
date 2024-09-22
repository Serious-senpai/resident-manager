import "dart:async";
import "dart:convert";

import "package:resident_manager/src/core/models/auth.dart";

import "info.dart";
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

  static Future<List<RegisterRequest>> query({required ApplicationState state, required int offset}) async {
    final result = <RegisterRequest>[];
    final authorization = state.authorization;
    if (authorization == null) {
      return result;
    }

    final response = await state.http.apiGet(
      "/api/admin/reg-request",
      queryParameters: {"offset": offset.toString()},
      headers: authorization.headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
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
}
