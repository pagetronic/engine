import 'dart:io';

import 'package:engine/api/socket/socket_master.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:flutter/foundation.dart';

class StatsUtils {
  static Future<void> pushStats(String lng, String? url) async {
    if (url != null && !Users.isAdmin) {
      MasterSocket.send(Json({
        'action': 'stats',
        'data': {
          'lng': lng,
          'location': url,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }
      }));
    }
  }
}
