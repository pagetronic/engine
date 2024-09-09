import 'package:engine/api/api.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/natives.dart';
import 'package:flutter/foundation.dart';

class Device {
  static String? _uuid;

  static Future<String?> get uuid async {
    if (_uuid != null || UsersStore.user == null) {
      return _uuid;
    }
    Json? rez = await Api.post("/profile", Json({'action': 'device', 'device': await getDeviceInfos()}));
    if (rez != null) {
      _uuid = rez['uuid'];
    }
    return _uuid;
  }

  static Future<Json?> getDeviceInfos() async {
    if (kIsWeb) {
      return Json({'platform': 'web'});
    }
    Json infos;
    try {
      infos = Json(await NativeCall.systemMethodChannel.invokeMethod("getDeviceId"));
    } catch (_) {
      infos = Json();
    }
    infos['platform'] = defaultTargetPlatform.name;
    return infos;
  }
}
