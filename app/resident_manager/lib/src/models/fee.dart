import "snowflake.dart";
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
}
