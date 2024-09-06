import 'dart:async';
import 'dart:typed_data';

import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/socket/utils/socket.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class BlobStore {
  static Future<Json?> uploadXFile(XFile file) async {
    return await upload(await file.readAsBytes(), file.mimeType, await file.length(), file.name);
  }

  static Future<Json?> upload(Uint8List bytes, String? mimeType, int size, String name) async {
    String apiBase = await Settings.apiBase;
    Completer<Json?> completer = Completer();
    SocketChannel.getSocket('${apiBase.replaceFirst("http", "ws")}/up').then(
      (channel) async {
        if (channel == null) {
          return null;
        }

        channel.sink.add(Json({"type": mimeType, "size": size, "name": name}).encode());

        channel.sink.add(bytes);

        String stream = await channel.stream.last;
        await channel.sink.close();

        completer.complete(Json.decode(stream));
      },
    ).onError(
      (error, stackTrace) {
        completer.complete(null);
      },
    );
    return completer.future;
  }
}
