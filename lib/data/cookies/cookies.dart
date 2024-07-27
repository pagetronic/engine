import 'package:engine/data/cookies/cookies_ignore.dart'
    if (dart.library.html) 'package:engine/data/cookies/cookies_web.dart' as kitchen;

class Cookies {
  static void clear() {
    kitchen.CookieSystem().clear();
  }
}

abstract class CookieSystemAbstract {
  void clear();
}
