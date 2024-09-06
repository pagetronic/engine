import 'package:engine/api/utils/json.dart';
import 'package:engine/socket/websocket.dart';

class AIUtils {
  static Future<List<Json>> question(Json post, List<Json> questions) async {
    Json action = Json();
    action['action'] = "ai";
    action['type'] = "question";
    List<String> context = [];
    for (Json bread in post['breadcrumb']) {
      context.add(bread['title']);
    }
    action['context'] = context.join(" > ");
    action['text'] = post['text'];
    action['questions'] = questions;
    Json? rez = await MasterSocket.send(action);

    return rez?['questions'] ?? [];
  }

  static Future<String> replyThread(String threadId) async {
    Json action = Json();
    action['action'] = "ai";
    action['type'] = "reply";
    action['thread'] = threadId;
    Json? rez = await MasterSocket.send(action);
    return rez?['text'] ?? "";
  }

  static Future<String> rewrite(String text, int min, int max) async {
    Json action = Json();
    action['action'] = "ai";
    action['type'] = "rewrite";
    action['text'] = text;
    Json? rez = await MasterSocket.send(action);
    return rez?['text'] ?? "";
  }
}
