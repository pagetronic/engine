import 'package:engine/notices/notices.dart';
import 'package:flutter/services.dart';

class MethodsCaller {
  static const MethodChannel native = MethodChannel("native");
  static const MethodChannel flutter = MethodChannel("flutter");

  static void init() {
    flutter.setMethodCallHandler(
      (methodCall) async {
        switch (methodCall.method) {
          case "getNotices":
            return await NoticesUtils.getNativeNotices(methodCall.arguments);
          case "readNotices":
            await NoticesUtils.read(methodCall.arguments);

          default:
        }
      },
    );
  }
}
