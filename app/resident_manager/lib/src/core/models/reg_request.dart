import "dart:convert";

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
}
