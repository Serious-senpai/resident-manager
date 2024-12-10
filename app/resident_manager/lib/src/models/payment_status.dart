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

  PaymentStatus({
    required this.fee,
    required this.lowerBound,
    required this.upperBound,
    required this.payment,
  });

  PaymentStatus.fromJson(dynamic data)
      : this(
          fee: Fee.fromJson(data["fee"]),
          lowerBound: data["lower_bound"] as double,
          upperBound: data["upper_bound"] as double,
          payment: data["payment"] == null ? null : Payment.fromJson(data["payment"]),
        );

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

    if (response.statusCode == 200) {
      final data = result["data"] as List<dynamic>;
      return Result(0, List<PaymentStatus>.from(data.map(PaymentStatus.fromJson)));
    }

    return Result(result["code"], null);
  }
}
