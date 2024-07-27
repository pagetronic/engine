import 'package:engine/api/socket/utils/socket.dart';
import 'package:engine/utils/fx.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TypedSocket implements SocketChannelTyped {
  @override
  Future<WebSocketChannel?> getSocket(String url) async {
    try {
      return WebSocketChannel.connect(Uri.parse(url));
    } catch (e) {
      Fx.log("Socket init error");
      return null;
    }
  }
}
