import 'package:engine/api/api.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/utils/natives.dart';
import 'package:flutter/foundation.dart';

class Device {
  static const String _key = "device";

  static Future<String?> get uuid async {
    if (UsersStore.user == null) {
      return null;
    }
    String? deviceId;

    Json? device = await getDeviceInfos();
    String? uuid = await SettingsStore.get(_key);

    if (uuid != null && !uuid.contains("/")) {
      uuid = null;
    }

    if (uuid != null && device == null) {
      return uuid.split("/")[0];
    } else if (device == null) {
      return null;
    }

    if (uuid != null) {
      String deviceHash = device.md5;
      deviceId = uuid.split("/")[0];
      if (uuid.split("/")[1] != deviceHash) {
        Json? rez = await Api.post("/profile", Json({'action': 'device', 'device': device, 'update': deviceId}));
        if (rez?['ok'] ?? false) {
          await SettingsStore.set(_key, "$deviceId/$deviceHash");
        }
      }
      deviceId = uuid.split("/")[0];
    }
    if (deviceId == null) {
      Json? rez = await Api.post("/profile", Json({'action': 'device', 'device': device}));
      if (rez != null) {
        deviceId = rez['uuid'];
        if (deviceId != null) {
          String deviceHash = device.md5;
          await SettingsStore.set(_key, "$deviceId/$deviceHash");
        }
      }
    }

    return deviceId;
  }

  static Future<Json?> getDeviceInfos() async {
    if (kIsWeb) {
      return Json({'platform': 'web'});
    }
    try {
      Json infos = Json.decode((await MethodsCaller.native.invokeMethod<String?>("getDeviceId")) ?? "");
      infos['platform'] = defaultTargetPlatform.name;
      return infos;
    } catch (e) {
      return null;
    }
  }
}
