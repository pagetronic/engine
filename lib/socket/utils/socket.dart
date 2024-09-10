import 'package:engine/socket/utils/socket_os.dart' if (dart.library.html) 'package:engine/socket/utils/socket_web.dart'
    as socket;
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketChannel {
  static Future<WebSocketChannel?> getSocket(String url) {
    return socket.TypedSocket().getSocket(url);
  }
}

abstract class SocketChannelTyped {
  Future<WebSocketChannel?> getSocket(String url);
}
