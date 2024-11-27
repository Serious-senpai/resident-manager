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
    required DateTime createdFrom,
    required DateTime createdTo,
  }) async {
    final response = await state.get(
      "/api/v1/residents/fee",
      queryParameters: {
        "offset": offset.toString(),
        "created_from": createdFrom.toUtc().toIso8601String(),
        "created_to": createdTo.toUtc().toIso8601String(),
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
