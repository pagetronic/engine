import 'dart:async';

import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/socket/channels.dart';
import 'package:engine/socket/utils/socket.dart';
import 'package:engine/utils/fx.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:engine/socket/channels.dart';

class MasterSocket {
  static Future<WebSocketChannel?>? _socket = registerSocket();
  static final Map<String, ChannelStreamController> channels = {};
  static String? userId = Users.id;

  static Future<WebSocketChannel?>? getSocket() => _socket;

  static Future<WebSocketChannel?> init() async {
    try {
      if (_socket == null || (await _socket!)?.closeCode != null) {
        _socket = registerSocket();
        for (String channel in channels.keys) {
          (await _socket)?.sink.add(Json({"action": "follow", "channel": channel}).encode());
        }
      }
      return await _socket;
    } catch (e) {
      Fx.log("Socket init error");
      Future.delayed(const Duration(seconds: 5), init);
      return null;
    }
  }

  static Future<StreamController<Json>> follow(Channel channel) async {
    if (channels[channel.toString()] == null) {
      channels[channel.toString()] = ChannelStreamController(channel);
    }
    return channels[channel.toString()]!.startStream();
  }

  static Future<void> unfollow(StreamController<Json> controller) async {
    ChannelStreamController? channelStreamController = channels.values.firstWhereOrNull(
      (element) {
        for (StreamController<Json> controller_ in element.controllers) {
          if (controller_ == controller) {
            return true;
          }
        }
        return false;
      },
    );
    if (channelStreamController != null) {
      channelStreamController.endStream(controller);
      if (channelStreamController.controllers.isEmpty) {
        channels.remove(channelStreamController.channel.toString());
      }
    }
  }

  static Future<Json?> send(Json data) {
    Completer<Json?> completer = Completer<Json?>();
    Future.delayed(Duration.zero, () async {
      try {
        String act = getAct();
        data['act'] = act;
        WebSocketChannel? socket = await init();

        follow(Channel.simple(act)).then(
          (follower) {
            follower.stream.listen((resp) {
              completer.complete(resp);
              unfollow(follower);
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
        Future.delayed(const Duration(seconds: 5), init);
        Fx.log("Socket connection error");
        return;
      }

      socket.stream.handleError((_) {
        Future.delayed(const Duration(milliseconds: 300), () async {
          try {
            await socket.sink.close(500);
          } catch (_) {}
          _socket = null;
          Future.delayed(const Duration(seconds: 5), init);
        });
      }).listen(
        (dynamic data_) {
          if (data_.contains("PLEASE_LOGIN")) {
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
          Future.delayed(const Duration(seconds: 5), init);
        },
        onError: (e) {
          //Fx.log("Socket error");
          _socket = null;
          Future.delayed(const Duration(seconds: 5), init);
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

class ChannelStreamController {
  final List<StreamController<Json>> controllers = [];
  final Channel channel;

  ChannelStreamController(this.channel);

  void add(Json data) {
    for (StreamController<Json> controller in controllers) {
      controller.add(data);
    }
  }

  StreamController<Json> startStream() {
    StreamController<Json> controller = StreamController<Json>();
    if (controllers.isEmpty) {
      MasterSocket.getSocket()?.then(
        (socket) {
          socket?.sink.add(Json({"action": "follow", "channel": channel}).encode());
        },
      );
    }
    controllers.add(controller);

    return controller;
  }

  void endStream(StreamController<Json> controller) {
    controller.close();
    controllers.remove(controller);
    if (controllers.isEmpty) {
      MasterSocket.init().then(
        (socket) {
          socket?.sink.add(Json({"action": "unfollow", "channel": channel}).encode());
        },
      );
    }
  }
}
