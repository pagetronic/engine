// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html';

import 'package:engine/api/html/html.dart';
import 'package:engine/api/utils/json.dart';

class TypedHtmlDocumentData implements AbstractTypedHtmlDocumentData {
  @override
  Json? getData(String key) {
    List<Element> jsonTags =
        document.querySelectorAll("[type=\"application/json\"][key=$key], [type='application/json'][key=$key]");
    try {
      Json? data = jsonTags.isNotEmpty ? Json.decode(jsonTags.first.innerText) : null;
      if (data != null) {
        jsonTags.first.remove();
      }
      return data;
    } catch (_) {}
    return null;
  }
}
