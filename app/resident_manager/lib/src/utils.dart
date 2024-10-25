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

DateTime fromEpoch(Duration dt) {
  return epoch.add(dt);
}

DateTime snowflakeTime(int id) {
  return fromEpoch(Duration(milliseconds: id >> (8 * 3)));
}

extension DateFormat on DateTime {
  String formatDate() {
    return "$day/$month/$year";
  }

  static DateTime? fromFormattedDate(String s) {
    try {
      final parts = s.split("/");
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }
}

class FieldLabel extends StatelessWidget {
  final String _label;
  final bool _required;

  const FieldLabel(String label, {super.key, bool required = false})
      : _label = label,
        _required = required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _label,
        style: const TextStyle(color: Colors.black),
        children: _required ? const [TextSpan(text: " *", style: TextStyle(color: Colors.red))] : [],
      ),
    );
  }
}

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
  if (roomInt < 0 || roomInt > 32767) {
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
