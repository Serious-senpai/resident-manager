import "../../utils.dart";

mixin Snowflake {
  abstract final int id;

  DateTime get createdAt => snowflakeTime(id);
}
