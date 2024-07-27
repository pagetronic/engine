import 'dart:async';
import 'dart:convert';

import 'package:engine/api/socket/utils/socket.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/fx.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MasterSocket {
  static Future<WebSocketChannel?>? _socket = registerSocket();
  static final Map<String, StreamController<Json>> channels = {};
  static String? userId = Users.id;

  static Future<WebSocketChannel?> init() async {
    try {
      if (_socket == null || (await _socket!)?.closeCode != null) {
        _socket = registerSocket();
      }
      return await _socket;
    } catch (e) {
      Fx.log("Socket init error");
      return null;
    }
  }

  static Future<Stream<Json>> follow(String channel) async {
    await unfollow(channel);
    if (channels[channel] == null) {
      channels[channel] = StreamController<Json>();
    }
    WebSocketChannel? socket = await init();
    socket?.sink.add(jsonEncode({"action": "follow", "channel": channel}));
    return channels[channel]!.stream;
  }

  static Future<void> unfollow(String channel) async {
    WebSocketChannel? socket = await init();
    socket?.sink.add(jsonEncode({"action": "unfollow", "channel": channel}));
    channels.remove(channel)?.close();
  }

  static Future<Json?> send(Json data) {
    Completer<Json?> completer = Completer<Json?>();
    Future.delayed(Duration.zero, () async {
      try {
        String act = getAct();
        data['act'] = act;
        WebSocketChannel? socket = await init();

        follow(act).then(
          (follower) {
            follower.listen((resp) {
              completer.complete(resp);
              unfollow(act);
            });
          },
        );

        socket?.sink.add(data.encode());
      } catch (e) {
        Fx.log(e);
      }
    });
    return completer.future;
  }

  static String getAct() {
    return (const Uuid()).v1().replaceAll("-", "").toUpperCase();
  }

  static Future<WebSocketChannel?> registerSocket() async {
    UsersStore.currentUser.removeListener(reload);
    UsersStore.currentUser.addListener(reload);
    String apiBase = await Settings.apiBase;
    Future<WebSocketChannel?> socket = SocketChannel.getSocket('${apiBase.replaceFirst("http", "ws")}/socket');

    socket.onError((error, stackTrace) {
      Future.delayed(const Duration(seconds: 5), init);
      return socket;
    }).then((WebSocketChannel? socket) {
      if (socket == null) {
        Fx.log("Socket connection error");
        return;
      }

      socket.stream.listen(
        (dynamic data_) {
          if (data_ == "PLEASE_LOGIN") {
            UsersStore.revokeSession();
            return;
          }
          Json data = Json.decode(data_);
          if (data['channel'] == null || data['message'] == null || channels[data['channel']] == null) {
            return;
          }
          channels[data['channel']]!.add(data['message']);
        },
        cancelOnError: true,
        onDone: () {
          //Fx.log("Socket done");
          _socket = null;
          Future.delayed(const Duration(seconds: 10), init);
        },
        onError: (e) {
          //Fx.log("Socket error");
          _socket = null;
          Future.delayed(const Duration(seconds: 10), init);
        },
      );
    });
    try {
      await (await socket)?.ready;
    } catch (_) {}
    return await socket;
  }

  static void reload() async {
    if (userId == Users.id) {
      return;
    }
    userId = Users.id;
    if (_socket != null) {
      WebSocketChannel? socket = await _socket;
      if (socket != null && socket.closeCode != null) {
        socket.sink.close();
      }
      _socket = registerSocket();
      Fx.log("reload socket");
    }
  }
}
