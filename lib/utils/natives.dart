import 'package:engine/notices/notices_utils.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/services.dart';

class NativeCall {
  static final FunctionMethodChannel systemMethodChannel = _system();

  static FunctionMethodChannel _system() {
    return FunctionMethodChannel("system");
  }

  static void init() {
    Fx.log(systemMethodChannel.name);
  }
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
