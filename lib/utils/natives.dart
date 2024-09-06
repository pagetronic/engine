import 'package:engine/notices/notices_utils.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/services.dart';

class NativeCall {
  static FunctionMethodChannel? systemMethodChannel;

  static void system() {
    systemMethodChannel = FunctionMethodChannel("system");
  }
}

class FunctionMethodChannel extends MethodChannel {
  FunctionMethodChannel(super.name) {
    setMethodCallHandler(nativeMethodCallHandler);
    Fx.log("Load methodChannel : $name");
  }

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "getNotices":
        return await NoticesUtils.getNativeNotices(methodCall.arguments);

      default:
    }
  }
}
