import 'package:engine/api/api.dart';
import 'package:engine/utils/device/device.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Future<Json?> getNotices({String? start, String? type, String? uuid, String? paging}) async {
    return Api.get("/notices",
        parameters: {
          'start': start,
          'type': type,
          'uuid': uuid,
        },
        paging: paging);
  }

  static Future<String?> getNativeNotices(Map<Object?, Object?> arguments) async {
    String? uuid = await Device.uuid;
    if (uuid == null) {
      return null;
    }
    return (await getNotices(
      type: 'os',
      uuid: uuid,
      start: arguments['start'] as String?,
      paging: arguments['paging'] as String?,
    ))
        ?.encode();
  }
}
