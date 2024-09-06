import 'dart:async';

import 'package:engine/api/utils/json.dart';
import 'package:engine/socket/websocket.dart';

class Channel {
  final String? type;
  final String id;

  Channel(this.type, this.id);

  Channel.simple(this.id) : type = null;

  @override
  String toString() {
    return "${type == null ? '' : '$type/'}$id";
  }
}

mixin ChannelFollowable {
  final List<StreamController<Json>> follows = [];

  Future<Stream<Json>> follow(Channel channel) async {
    StreamController<Json> streamController = await MasterSocket.follow(channel);
    follows.add(streamController);
    return streamController.stream;
  }

  void unfollowAll() {
    for (StreamController<Json> follow in follows) {
      MasterSocket.unfollow(follow);
    }
  }
}
