import "dart:convert";

import "../state.dart";

class Room {
  final int room;
  final double area;
  final int motorbike;
  final int car;

  Room({
    required this.room,
    required this.area,
    required this.motorbike,
    required this.car,
  });

  Room.fromJson(dynamic data)
      : room = data["room"],
        area = data["area"],
        motorbike = data["motorbike"],
        car = data["car"];

  int get floor => room ~/ 100;

  static Future<List<Room>> query({
    required ApplicationState state,
    required int offset,
    int? room,
    int? floor,
  }) async {
    final result = <Room>[];
    final authorization = state.authorization;
    if (authorization == null) {
      return result;
    }

    final params = {"offset": offset.toString()};
    if (room != null) {
      params["room"] = room.toString();
    }
    if (floor != null) {
      params["floor"] = floor.toString();
    }

    final response = await state.get("/api/v1/admin/rooms", queryParameters: params);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      result.addAll(data.map(Room.fromJson));
    }

    return result;
  }

  /// Count the number of rooms.
  static Future<int?> count({required ApplicationState state}) async {
    final response = await state.get("/api/v1/admin/rooms/count");
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
