import 'package:engine/api/socket/socket_master.dart';
import 'package:engine/api/utils/json.dart';

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

  static Future<String> reply(String id, String question, List<String> messages, String suggest, int min, int max) async {
    Json action = Json();
    action['action'] = "ai";
    action['type'] = "reply";
    action['thread'] = id;
    action['question'] = question;
    action['messages'] = messages;
    action['suggest'] = suggest;
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
