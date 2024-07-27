import 'package:engine/utils/web/web_os.dart' if (dart.library.html) 'package:engine/utils/web/web_web.dart' as client;

class WebData {
  static void setTitle(String title) {
    return client.TypedWebData().setTitle(title);
  }

  static void setUrl(String url) {
    return client.TypedWebData().setUrl(url);
  }

  static String? getLocation() {
    return client.TypedWebData().getLocation();
  }
}

abstract class AbstractTypedWebData {
  void setTitle(String title);

  void setUrl(String url);

  String? getLocation();
}
