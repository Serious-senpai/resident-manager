import "package:flutter/services.dart";
import "package:fluttertoast/fluttertoast.dart";

import "core/config.dart";

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
