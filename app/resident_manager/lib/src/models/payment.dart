import "snowflake.dart";

class Payment with Snowflake {
  @override
  final int id;

  final int room;
  final double amount;
  final int feeId;

  Payment({
    required this.id,
    required this.room,
    required this.amount,
    required this.feeId,
  });

  Payment.fromJson(dynamic data)
      : this(
          id: data["id"] as int,
          room: data["room"] as int,
          amount: data["amount"] as double,
          feeId: data["fee_id"] as int,
        );
}
