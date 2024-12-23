import "dart:convert";

import "fee.dart";
import "payment.dart";
import "results.dart";
import "../state.dart";

class PaymentStatus {
  final Fee fee;
  final double lowerBound;
  final double upperBound;
  final Payment? payment;
  final int room;

  PaymentStatus({
    required this.fee,
    required this.lowerBound,
    required this.upperBound,
    required this.payment,
    required this.room,
  });

  PaymentStatus.fromJson(dynamic data)
      : this(
          fee: Fee.fromJson(data["fee"]),
          lowerBound: data["lower_bound"] as double,
          upperBound: data["upper_bound"] as double,
          payment: data["payment"] == null ? null : Payment.fromJson(data["payment"]),
          room: data["room"] as int,
        );

  static Future<Result<int?>> count({
    required ApplicationState state,
    required bool? paid,
    required DateTime createdAfter,
    required DateTime createdBefore,
  }) async {
    final response = await state.get(
      "/api/v1/residents/fees/count",
      queryParameters: {
        if (paid != null) "paid": paid.toString(),
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (result["code"] == 0) {
      return Result(0, result["data"]);
    }

    return Result(result["code"], null);
  }

  static Future<Result<int?>> adminCount({
    required ApplicationState state,
    required int? room,
    required bool? paid,
    required DateTime createdAfter,
    required DateTime createdBefore,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
    }

    final response = await state.get(
      "/api/v1/admin/fees/payments/count",
      queryParameters: {
        if (room != null) "room": room.toString(),
        if (paid != null) "paid": paid.toString(),
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (result["code"] == 0) {
      return Result(0, result["data"]);
    }

    return Result(result["code"], null);
  }

  static Future<Result<List<PaymentStatus>?>> query({
    required ApplicationState state,
    required int offset,
    required bool? paid,
    required DateTime createdAfter,
    required DateTime createdBefore,
  }) async {
    final response = await state.get(
      "/api/v1/residents/fees",
      queryParameters: {
        "offset": offset.toString(),
        if (paid != null) "paid": paid.toString(),
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (result["code"] == 0) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<PaymentStatus>.from(data.map(PaymentStatus.fromJson)));
    }

    return Result(result["code"], null);
  }

  static Future<Result<List<PaymentStatus>?>> adminQuery({
    required ApplicationState state,
    required int? room,
    required bool? paid,
    required int offset,
    required DateTime createdAfter,
    required DateTime createdBefore,
  }) async {
    if (!state.loggedInAsAdmin) {
      return Result(-1, null);
    }

    final response = await state.get(
      "/api/v1/admin/fees/payments",
      queryParameters: {
        if (room != null) "room": room.toString(),
        if (paid != null) "paid": paid.toString(),
        "offset": offset.toString(),
        "created_after": createdAfter.toUtc().toIso8601String(),
        "created_before": createdBefore.toUtc().toIso8601String(),
      },
    );
    final result = json.decode(utf8.decode(response.bodyBytes));

    if (result["code"] == 0) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<PaymentStatus>.from(data.map(PaymentStatus.fromJson)));
    }

    return Result(result["code"], null);
  }
}
