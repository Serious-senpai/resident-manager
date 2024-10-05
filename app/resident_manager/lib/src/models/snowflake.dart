import "../utils.dart";

mixin Snowflake {
  /// The model's unique ID.
  abstract final int id;

  /// The creation time of the given snowflake.
  DateTime get createdAt => snowflakeTime(id);
}
