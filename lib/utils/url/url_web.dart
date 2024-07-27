// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';

import 'package:engine/utils/url/url.dart';

class TypedUrlOpener implements AbstractTypedUrlOpener {
  @override
  Future<void> open(String url) async {
    window.location.href = url;
  }
}
