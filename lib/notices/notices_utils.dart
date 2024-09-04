import 'package:engine/api/utils/json.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Json getNotices(String? paging) {
    return Json();
  }

  static String getNativeNotices(String? paging) {
    return getNotices(paging).encode();
  }
}
