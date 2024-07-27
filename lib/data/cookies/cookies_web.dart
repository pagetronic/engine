// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';

import 'package:engine/data/cookies/cookies.dart';

class CookieSystem extends CookieSystemAbstract {
  @override
  void clear() {
    if (document.cookie != null) {
      for (String cookie in document.cookie!.split(";")) {
        int eqPos = cookie.indexOf("=");
        String name = eqPos > -1 ? cookie.substring(0, eqPos) : cookie;
        document.cookie = "$name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; domain=agroneo.com; path=/;";
      }
    }
  }
}
