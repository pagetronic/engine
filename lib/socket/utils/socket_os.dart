import 'package:engine/api/utils/settings.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/socket/utils/socket.dart';
import 'package:engine/utils/fx.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TypedSocket implements SocketChannelTyped {
  @override
  Future<WebSocketChannel?> getSocket(String url) async {
    String? session = Users.getSession();
    try {
      return IOWebSocketChannel.connect(
        connectTimeout: const Duration(seconds: 30),
        Uri.parse(url),
        headers: {
          'User-Agent': Settings.userAgent,
          if (session != null) 'Authorization': session,
        },
      );
    } catch (e) {
      Fx.log("Socket init error");
      return null;
    }
  }
}
