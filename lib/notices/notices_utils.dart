import 'package:engine/api/api.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/device/device.dart';

class NoticesUtils {
  static bool webPushCapable() {
    return false;
  }

  static Future<Json?> getNotices({String? start, String? device, String? paging, String? session}) async {
    return Api.get("/notices",
        parameters: {
          'start': start,
          'device': device,
        },
        session: session,
        paging: paging);
  }

  static Future<String?> getNativeNotices(Map<Object?, Object?> arguments) async {
    if (UsersStore.realUser == null) {
      return null;
    }
    String? uuid = await Device.uuid;
    if (uuid == null) {
      return null;
    }
    return (await getNotices(
            session: UsersStore.realUser?.session,
            device: uuid,
            start: arguments['start'] as String?,
            paging: arguments['paging'] as String?))
        ?.encode();
  }
}
