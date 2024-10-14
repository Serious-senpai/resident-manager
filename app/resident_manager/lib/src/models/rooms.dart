import "dart:convert";

import "../state.dart";

class RoomData {
  final int room;
  final double area;
  final int motorbike;
  final int car;

  RoomData({
    required this.room,
    required this.area,
    required this.motorbike,
    required this.car,
  });
}

class Room {
  final int room;
  final double? area;
  final int? motorbike;
  final int? car;
  final int residents;

  Room({
    required this.room,
    required this.area,
    required this.motorbike,
    required this.car,
    required this.residents,
  });

  Room.fromJson(dynamic data)
      : room = data["room"],
        area = data["area"],
        motorbike = data["motorbike"],
        car = data["car"],
        residents = data["residents"];

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

    final response = await state.get(
      "/api/v1/admin/rooms",
      queryParameters: {
        "offset": offset.toString(),
        if (room != null) "room": room.toString(),
        if (floor != null) "floor": floor.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes)) as List;
      result.addAll(data.map(Room.fromJson));
    }

    return result;
  }

  /// Count the number of rooms.
  static Future<int?> count({
    required ApplicationState state,
    int? room,
    int? floor,
  }) async {
    final response = await state.get(
      "/api/v1/admin/rooms/count",
      queryParameters: {
        if (room != null) "room": room.toString(),
        if (floor != null) "floor": floor.toString(),
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }

    return null;
  }
}
