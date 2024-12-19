import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:fluttertoast/fluttertoast.dart";

import "config.dart";
import "translations.dart";

/// Screen width breakpoints from https://getbootstrap.com/docs/5.0/layout/breakpoints/
class ScreenWidth {
  static const SMALL = 576;
  static const MEDIUM = 768;
  static const LARGE = 992;
  static const EXTRA_LARGE = 1200;
  static const EXTRA_EXTRA_LARGE = 1400;
}

/// The purpose of this class is providing a reliable method to access the
/// state of the underlying [Future] in a [FutureBuilder]. Using the [AsyncSnapshot]
/// from [FutureBuilder] is unreliable. Quoting from the
/// [docs](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html):
///
/// > A side-effect of this is that providing a new but already-completed
/// future to a [FutureBuilder] will result in a single frame in the
/// [ConnectionState.waiting] state. This is because there is no way to
/// synchronously determine that a [Future] has already completed.
abstract class FutureHolder<T> {
  Future<T>? _future;

  /// Initialize a [FutureHolder] with the given [initialData].
  FutureHolder({T? initialData}) {
    lastData = initialData;
  }

  /// The underlying future.
  ///
  /// You can pass this to a [FutureBuilder] constructor.
  ///
  /// When called, an instance of the [Future] returned from [run] will be obtained.
  /// Calling [reload] will create another instance of [Future] from [run].
  Future<T> get future => _future ??= _runAndSet();

  bool _isLoading = false;

  /// Whether [future] has completed. This serves as a way to synchronously
  /// determine the [future]'s state.
  bool get isLoading => _isLoading;

  /// The last data returned by [future], or `null` if no data has been received yet.
  /// When [run] is executed multiple times, this data can be passed to [FutureBuilder]
  /// as its `initialData` parameter to avoid the flickering frame mentioned in the
  /// [docs](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html).
  ///
  /// By combining with the [isLoading] attribute, you can perform building the widget
  /// inside [FutureBuilder] more reliably.
  T? lastData;

  /// Reload [future] with another execution of [run].
  void reload() {
    _future = null;
  }

  Future<T> _runAndSet() async {
    _isLoading = true;
    try {
      final result = lastData = await run();
      return result;
    } finally {
      _isLoading = false;
    }
  }

  /// The underlying asynchronous execution.
  ///
  /// Subclasses should implement this method.
  Future<T> run();
}

class Date {
  final int year;
  final int month;
  final int day;

  const Date(this.year, this.month, this.day);

  Date.fromDateTime(DateTime datetime)
      : year = datetime.year,
        month = datetime.month,
        day = datetime.day;

  Date.now() : this.fromDateTime(DateTime.now());

  String format(String fmt) {
    fmt = fmt.replaceAll("yyyy", year.toString());
    fmt = fmt.replaceAll("mm", month.toString().padLeft(2, "0"));
    fmt = fmt.replaceAll("dd", day.toString().padLeft(2, "0"));
    return fmt;
  }

  DateTime toDateTime() => DateTime(year, month, day);

  @override
  String toString() => format("yyyy-mm-dd");

  /// Parse string in format `yyyy*mm*dd`.
  static Date? parse(String str) {
    try {
      return Date(
        int.parse(str.substring(0, 4)),
        int.parse(str.substring(5, 7)),
        int.parse(str.substring(8, 10)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse string in format `dd*mm*yyyy`.
  static Date? parseFriendly(String str) {
    try {
      return Date(
        int.parse(str.substring(6, 10)),
        int.parse(str.substring(3, 5)),
        int.parse(str.substring(0, 2)),
      );
    } catch (_) {
      return null;
    }
  }
}

Future<bool> showToastSafe({
  required String msg,
  Toast? toastLength,
  int timeInSecForIosWeb = 1,
  double? fontSize,
  String? fontAsset,
  ToastGravity? gravity,
  Color? backgroundColor,
  Color? textColor,
  bool webShowClose = false,
  dynamic webBgColor = "linear-gradient(to right, #00b09b, #96c93d)",
  dynamic webPosition = "right",
}) async {
  try {
    // Fluttertoast.showToast hang in flutter test? No issue URLs found yet.
    return await Fluttertoast.showToast(
          msg: msg,
          toastLength: toastLength,
          timeInSecForIosWeb: timeInSecForIosWeb,
          fontSize: fontSize,
          fontAsset: fontAsset,
          gravity: gravity,
          backgroundColor: backgroundColor,
          textColor: textColor,
          webShowClose: webShowClose,
          webBgColor: webBgColor,
          webPosition: webPosition,
        ) ??
        false;
  } catch (_) {
    return false;
  }
}

DateTime fromEpoch(Duration dt) => epoch.add(dt);

DateTime snowflakeTime(int id) => fromEpoch(Duration(milliseconds: id >> 16));

String formatDateTime(DateTime time) => "${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute}:${time.second}";

String? nameValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingName.getString(context);
    }

    return null;
  }

  if (value.length > 255) {
    return AppLocale.InvalidNameLength.getString(context);
  }

  return null;
}

String? roomValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRoomNumber.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,6}$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidRoomNumber.getString(context);
  }

  final roomInt = int.parse(value);
  if (roomInt > 32767) {
    return AppLocale.InvalidRoomNumber.getString(context);
  }

  return null;
}

String? phoneValidator(BuildContext context, {required String? value}) {
  if (value != null && value.isNotEmpty) {
    final pattern = RegExp(r"^\+?[\d\s]+$");
    if (value.length > 15 || !pattern.hasMatch(value)) {
      return AppLocale.InvalidPhoneNumber.getString(context);
    }
  }

  return null;
}

String? emailValidator(BuildContext context, {required String? value}) {
  if (value != null && value.isNotEmpty) {
    final pattern = RegExp(r"^[\w\.-]+@[\w\.-]+\.[\w\.]+[\w\.]?$");
    if (value.length > 255 || !pattern.hasMatch(value)) {
      return AppLocale.InvalidEmail.getString(context);
    }
  }

  return null;
}

String? usernameValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingUsername.getString(context);
    }

    return null;
  }

  if (value.length > 255) {
    return AppLocale.InvalidUsernameLength.getString(context);
  }

  return null;
}

String? passwordValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingPassword.getString(context);
    }

    return null;
  }

  if (value.length < 8 || value.length > 255) {
    return AppLocale.InvalidPasswordLength.getString(context);
  }

  return null;
}

String? roomAreaValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRoomArea.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,9}(?:\.\d*)?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidRoomArea.getString(context);
  }

  final roomAreaDouble = double.parse(value);
  if (roomAreaDouble > 21474835) {
    return AppLocale.InvalidRoomArea.getString(context);
  }

  return null;
}

String? motorbikesCountValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingMotorbikesCount.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,4}$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidMotorbikesCount.getString(context);
  }

  final motorbikesCountInt = int.parse(value);
  if (motorbikesCountInt > 255) {
    return AppLocale.InvalidMotorbikesCount.getString(context);
  }

  return null;
}

String? carsCountValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingCarsCount.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,4}$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidCarsCount.getString(context);
  }

  final carsCountInt = int.parse(value);
  if (carsCountInt > 255) {
    return AppLocale.InvalidCarsCount.getString(context);
  }

  return null;
}

String? feeLowerValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRequiredValue.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,8}(?:\.\d{1,2})?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidValue.getString(context);
  }

  return double.tryParse(value) == null ? AppLocale.InvalidValue.getString(context) : null;
}

String? feeUpperValidator(BuildContext context, {required double? lower, required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRequiredValue.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,8}(?:\.\d{1,2})?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidValue.getString(context);
  }

  final val = double.tryParse(value);
  if (val == null || (lower != null && val < lower)) {
    return AppLocale.InvalidValue.getString(context);
  }

  return null;
}

String? feePerAreaValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRequiredValue.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,8}(?:\.\d{1,2})?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidValue.getString(context);
  }

  return double.tryParse(value) == null ? AppLocale.InvalidValue.getString(context) : null;
}

String? feePerMotorbikeValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRequiredValue.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,8}(?:\.\d{1,2})?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidValue.getString(context);
  }

  return double.tryParse(value) == null ? AppLocale.InvalidValue.getString(context) : null;
}

String? feePerCarValidator(BuildContext context, {required bool required, required String? value}) {
  if (value == null || value.isEmpty) {
    if (required) {
      return AppLocale.MissingRequiredValue.getString(context);
    }

    return null;
  }

  final pattern = RegExp(r"^\d{1,8}(?:\.\d{1,2})?$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidValue.getString(context);
  }

  return double.tryParse(value) == null ? AppLocale.InvalidValue.getString(context) : null;
}
