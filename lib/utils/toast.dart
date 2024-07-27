import 'package:flutter/material.dart';

class Messager {
  static void toast(BuildContext context, String message) {
    ScaffoldMessengerState? toaster = ScaffoldMessenger.maybeOf(context);
    if (toaster != null) {
      toaster.clearSnackBars();
      toaster.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
