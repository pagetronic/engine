import 'package:engine/api/utils/json.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const String key = "settings";
  static SharedPreferences? prefs;
  static const String base = "gaia.";

  static Future<Json> _getStore() async {
    prefs ??= await SharedPreferences.getInstance();
    return Json.decode(prefs!.getString(key) ?? "{}");
  }

  static Future<void> _save(Json store) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs!.setString(key, store.encode());
  }

  static Future<void> set(String key, dynamic value) async {
    Json? store = await _getStore();
    store[key] = value;
    await _save(store);
  }

  static Future<T> get<T>(String key, [T? def]) async {
    Json? store = await _getStore();
    return store[key] ?? def;
  }

  static Future<void> remove(String key) async {
    Json? store = await _getStore();
    store.remove(key);
    await _save(store);
  }

  static void init() {
    try {
      SharedPreferences.setPrefix(base);
    } catch (_) {}
  }
}

class TempDataStore {
  static final Map<String, dynamic> store = {};

  static void put(String key, dynamic value) {
    store[key] = value;
  }

  static void remove(String key) {
    if (store.containsKey(key)) {
      store.remove(key);
    }
  }

  static T get<T>(String key, T def) {
    if (store.containsKey(key)) {
      return store[key];
    }
    return def;
  }
}
