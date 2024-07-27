import 'dart:ui';

import 'package:engine/api/locale/locale_os.dart' if (dart.library.html) 'package:engine/api/locale/locale_web.dart'
    as client;

class LocaleUtils {
  static Locale? getLocale() {
    return client.TypedLocaleUtils().getLocale();
  }
}

abstract class AbstractLocaleUtils {
  Locale? getLocale();
}
