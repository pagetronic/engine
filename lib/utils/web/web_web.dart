// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';

import 'package:engine/utils/web/web.dart';

class TypedWebData implements AbstractTypedWebData {
  @override
  void setTitle(String title) {
    document.title = title;
  }

  @override
  void setUrl(String url) {
    window.history.pushState({}, document.title, url);
  }

  @override
  String? getLocation() {
    return document.baseUri;
  }
}
