import "dart:convert";

import "results.dart";
import "../state.dart";

class _BaseRoom {
  final int room;

  _BaseRoom({required this.room});

  Future<Result<void>?> delete({
    required ApplicationState state,
  }) async {
    final response = await state.post(
      "/api/v1/admin/rooms/delete",
      body: json.encode([room]),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 204) {
      return null;
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    return Result(data["code"], null);
  }
}

class RoomData extends _BaseRoom {
  final double area;
  final int motorbike;
  final int car;

  RoomData({
    required super.room,
    required this.area,
    required this.motorbike,
    required this.car,
  });

  Map<String, dynamic> toJson() {
    return {
      "room": room,
      "area": area,
      "motorbike": motorbike,
      "car": car,
    };
  }

  static Future<Result<void>?> update({
    required ApplicationState state,
    required List<RoomData> rooms,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
    }

    final response = await state.post(
      "/api/v1/admin/rooms/update",
      body: json.encode(List<Map<String, dynamic>>.from(rooms.map((r) => r.toJson()))),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 204) {
      return null;
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    return Result(data["code"], null);
  }
}

class Room extends _BaseRoom {
  final double? area;
  final int? motorbike;
  final int? car;
  final int residents;

  Room({
    required super.room,
    required this.area,
    required this.motorbike,
    required this.car,
    required this.residents,
  });

  Room.fromJson(dynamic data)
      : this(
          room: data["room"],
          area: data["area"],
          motorbike: data["motorbike"],
          car: data["car"],
          residents: data["residents"],
        );

  int get floor => room ~/ 100;

  static Future<Result<List<Room>?>> query({
    required ApplicationState state,
    required int offset,
    int? room,
    int? floor,
  }) async {
    if (!state.loggedInAsAdmin) {
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
