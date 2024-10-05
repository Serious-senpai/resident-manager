import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:fluttertoast/fluttertoast.dart";

import "config.dart";
import "translations.dart";

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
    if (Platform.environment.containsKey("FLUTTER_TEST")) {
      // Fluttertoast.showToast hang in flutter test? No issue URLs found yet.
      return false;
    }

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
  return fromEpoch(Duration(milliseconds: id >> 14));
}

extension DateFormat on DateTime {
  String formatDate() {
    return "$day/$month/$year";
  }

  static DateTime fromFormattedDate(String s) {
    final parts = s.split("/");
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
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

  final pattern = RegExp(r"^\d*$");
  if (!pattern.hasMatch(value)) {
    return AppLocale.InvalidRoomNumber.getString(context);
  }

  final roomInt = int.parse(value);
  if (roomInt < 0 || roomInt > 32767) {
    return AppLocale.InvalidRoomNumber.getString(context);
  }

  return null;
}
