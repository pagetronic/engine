import 'package:engine/api/api.dart';
import 'package:engine/utils/device/device.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Future<Json?> getNotices({String? start, String? device, String? paging}) async {
    return Api.get("/notices",
        parameters: {
          'start': start,
          'device': device,
        },
        paging: paging);
  }

  static Future<String?> getNativeNotices(Map<Object?, Object?> arguments) async {
    String? uuid = await Device.uuid;
    if (uuid == null) {
      return null;
    }
    return (await getNotices(
            device: uuid, start: arguments['start'] as String?, paging: arguments['paging'] as String?))
        ?.encode();
  }
}
