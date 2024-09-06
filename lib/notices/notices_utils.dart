import 'package:engine/api/api.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Future<Json?> getNotices({String? start, String? type, String? paging}) async {
    return Api.get("/notices",
        parameters: {
          'start': start,
          'type': type,
        },
        paging: paging);
  }

  static Future<String?> getNativeNotices(Map<Object?, Object?> arguments) async {
    return (await getNotices(
      type: 'os',
      start: arguments['start'] as String?,
      paging: arguments['paging'] as String?,
    ))
        ?.encode();
  }
}
