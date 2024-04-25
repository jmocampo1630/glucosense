import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../enums/toast_type.dart';

void showToastWarning(String message,
    [ToastType type = ToastType.defaultType]) {
  Color backgroundColor;
  Color textColor;

  switch (type) {
    case ToastType.success:
      backgroundColor = Colors.green;
      textColor = Colors.white;
      break;
    case ToastType.error:
      backgroundColor = Colors.red;
      textColor = Colors.white;
      break;
    case ToastType.warning:
      backgroundColor = Colors.orange;
      textColor = Colors.black;
      break;
    default:
      backgroundColor = Colors.grey;
      textColor = Colors.black;
  }

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: backgroundColor,
    textColor: textColor,
    fontSize: 16.0,
  );
}
