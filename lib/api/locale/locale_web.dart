// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';
import 'dart:ui';

import 'locale.dart';

class TypedLocaleUtils implements AbstractLocaleUtils {
  @override
  Locale? getLocale() {
    Element? html = document.querySelector("html[lang]");
    if (html != null && html.hasAttribute("lang")) {
      return Locale(html.getAttribute("lang")!);
    }
    return null;
  }
}
