import "dart:convert";

import "results.dart";
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

  static Future<Result<List<Room>?>> query({
    required ApplicationState state,
    required int offset,
    int? room,
    int? floor,
  }) async {
    final authorization = state.authorization;
    if (authorization == null) {
      return Result(-1, null);
    }

    final response = await state.get(
      "/api/v1/admin/rooms",
      queryParameters: {
        "offset": offset.toString(),
        if (room != null) "room": room.toString(),
        if (floor != null) "floor": floor.toString(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<Room>.from(data.map(Room.fromJson)));
    }

    return Result(result["code"], null);
  }

  /// Count the number of rooms.
  static Future<Result<int?>> count({
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
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Result(0, result["data"]);
    }

    return Result(result["code"], null);
  }
}
