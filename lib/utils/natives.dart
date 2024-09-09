import 'package:engine/notices/notices_utils.dart';
import 'package:flutter/services.dart';

class NativeCall {
  static FunctionMethodChannel systemMethodChannel = _system();

  static FunctionMethodChannel _system() {
    return FunctionMethodChannel("system");
  }

  static void init() {}
}

class FunctionMethodChannel extends MethodChannel {
  FunctionMethodChannel(super.name) {
    setMethodCallHandler(nativeMethodCallHandler);
  }

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "getNotices":
        return await NoticesUtils.getNativeNotices(methodCall.arguments);

      default:
    }
  }
}
