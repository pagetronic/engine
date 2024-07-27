import 'package:engine/api/html/html_os.dart' if (dart.library.html) 'package:engine/api/html/html_web.dart' as client;
import 'package:engine/api/utils/json.dart';

class HtmlDocumentData {
  static Json? getData(String key) {
    return client.TypedHtmlDocumentData().getData(key);
  }
}

abstract class AbstractTypedHtmlDocumentData {
  Json? getData(String key);
}
