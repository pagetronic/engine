import 'package:engine/api/api.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Future<Json?> getNotices(String? start, String? paging) async {
    return Api.get("/notices", parameters: {if (start != null) 'start': start}, paging: paging);
  }

  static Future<String?> getNativeNotices(Map<Object?, Object?> arguments) async {
    return (await getNotices(arguments['start'] as String, arguments['paging'] as String?))?.encode();
  }
}
