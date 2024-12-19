import "dart:convert";

import "results.dart";
import "snowflake.dart";
import "../state.dart";
import "../utils.dart";

class Fee with Snowflake {
  @override
  final int id;

  final String name;
  final double lower;
  final double upper;
  final double perArea;
  final double perMotorbike;
  final double perCar;
  final Date deadline;
  final String description;
  final int flags;

  Fee({
    required this.id,
    required this.name,
    required this.lower,
    required this.upper,
    required this.perArea,
    required this.perMotorbike,
    required this.perCar,
    required this.deadline,
    required this.description,
    required this.flags,
  });

  Fee.fromJson(dynamic data)
      : this(
          id: data["id"] as int,
          name: data["name"] as String,
          lower: data["lower"] as double,
          upper: data["upper"] as double,
          perArea: data["per_area"] as double,
          perMotorbike: data["per_motorbike"] as double,
          perCar: data["per_car"] as double,
          deadline: Date.parse(data["deadline"] as String)!,
          description: data["description"] as String,
          flags: data["flags"] as int,
        );

  /// Queries the server for fees
  ///
  /// If [state] hasn't been authorized as an administratoor yet, the result will always be empty.
  static Future<Result<List<Fee>?>> query({
    required ApplicationState state,
    required int offset,
    required DateTime createdAfter,
    required DateTime createdBefore,
    String? name,
    required int orderBy,
    required bool ascending,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
    }

    orderBy = ascending ? orderBy.abs() : -orderBy.abs();
    final response = await state.get(
      "/api/v1/admin/fees",
      queryParameters: {
        "offset": offset.toString(),
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
        if (name != null && name.isNotEmpty) "name": name,
        "order_by": orderBy.toString(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<Fee>.from(data.map(Fee.fromJson)));
    }

    return Result(result["code"], null);
  }

  /// Count the number of fees.
  static Future<Result<int?>> count({
    required ApplicationState state,
    required DateTime createdAfter,
    required DateTime createdBefore,
    String? name,
  }) async {
    final response = await state.get(
      "/api/v1/admin/fees/count",
      queryParameters: {
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
        if (name != null && name.isNotEmpty) "name": name,
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return Result(0, result["data"]);
    }

    return Result(result["code"], null);
  }

  static Future<Result<Fee?>> create({
    required ApplicationState state,
    required String name,
    required double lower,
    required double upper,
    required double perArea,
    required double perMotorbike,
    required double perCar,
    required Date deadline,
    required String description,
    required int flags,
  }) async {
    final response = await state.post(
      "/api/v1/admin/fees/create",
      queryParameters: {
        "name": name,
        "lower": lower.toString(),
        "upper": upper.toString(),
        "per_area": perArea.toString(),
        "per_motorbike": perMotorbike.toString(),
        "per_car": perCar.toString(),
        "deadline": deadline.toDateTime().toIso8601String(),
        "description": description,
        "flags": flags.toString(),
      },
      headers: {
        "content-type": "application/json",
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));
    if (result["code"] == 0) {
      return Result(0, Fee.fromJson(result["data"]));
    }

    return Result(result["code"], null);
  }
}
