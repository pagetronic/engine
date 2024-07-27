import 'package:engine/utils/url/url_os.dart' if (dart.library.html) 'package:engine/utils/url/url_web.dart' as client;

class UrlOpener {
  static Future<void> open(String url) {
    return client.TypedUrlOpener().open(url);
  }
}

abstract class AbstractTypedUrlOpener {
  Future<void> open(String key);
}
