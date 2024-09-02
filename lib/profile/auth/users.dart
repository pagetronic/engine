import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/api/network.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/data/store.dart';
import 'package:engine/profile/auth/crypt.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class Users {
  static bool get isAdmin => UsersStore.user?.isAdmin ?? false;

  static String get id {
    return UsersStore.user?.id ?? "anonymous";
  }

  static Future<void> updateXUser(Map<String, String> headers) async {
    String? headerUser = headers['x-user'] ?? headers['X-User'];
    if (kIsWeb) {
      if (id != headerUser) {
        await UsersStore.activateWeb(userId: headerUser);
      }
      return;
    }
    if (id != headerUser) {
      await UsersStore.activate(headerUser);
    }
  }

  static Future<String> sysId() async {
    String? sysId = await SettingsStore.get("sysId");
    if (sysId == null) {
      Uuid uuid = const Uuid();
      sysId = uuid.v1().replaceAll("-", "").toLowerCase();
      await SettingsStore.set("sysId", sysId);
    }
    return sysId;
  }

  static String? getSession() => UsersStore.user?.session;

  static Future<bool> putSession(String session) async {
    Json? user = await Api.get("/profile", session: kIsWeb ? null : session);
    if (user != null) {
      await UsersStore.add(session, user);
      return true;
    }
    return false;
  }
}

class UsersStore {
  static final List<User> users = [];
  static final ValueNotifier<User?> currentUser = ValueNotifier(null);

  static List<dynamic> get allUsers {
    List<dynamic> users_ = [];
    for (User user in users) {
      if (user.data['original'] != null) {
        List<Json> original = user.data['original'];
        users_.add(original[0]..remove("id"));
      }
      users_.add(user);
      if (user.data['children'] != null) {
        users_.addAll(user.data['children']);
      }
    }
    return users_;
  }

  static User? get user => currentUser.value;

  static Future<User> add(String session, Json data) async {
    users.removeWhere((element) => data.id == element.id);
    User user = User(kIsWeb ? "web" : session, data);
    users.add(user);

    await setCurrentUser(user);
    await save();
    return user;
  }

  static Future<void> init() async {
    if (kIsWeb) {
      await activateWeb(init: true);
      return;
    }

    Json? data = await Crypto.decrypt();
    if ((data?['users'] ?? []).isNotEmpty) {
      for (Json user in data!['users']) {
        users.add(User(user['session'], user['data']));
      }
    }
    await activate(data?['current']);
  }

  static Future<void> save() async {
    if (kIsWeb) {
      return;
    }
    Json data = Json({
      'users': [
        for (User user in users) {'session': user.session, 'data': user.data}
      ],
      'current': currentUser.value?.id
    });
    await Crypto.crypt(data);
  }

  static Future<void> activate(String? userId) async {
    if (userId == null) {
      await setCurrentUser(null);
      return;
    }
    User? user = users.firstWhereOrNull((element) => userId == element.id);
    if (user != null) {
      Json? userData = await Api.get("/profile", session: user.session);
      if (userData != null) {
        user.data.clear();
        user.data.addAll(userData);
        await setCurrentUser(null);
      } else {
        if (networkAvailable.value) {
          users.remove(user);
          user = null;
        }
      }
      await setCurrentUser(user);
    }
    await save();
  }

  static Future<void> logout() async {
    User? user = users.firstWhereOrNull((element) => currentUser.value?.id == element.id);
    if (user != null) {
      Api.get("/logout", session: user.session);
      users.remove(user);
    }
    await setCurrentUser(null);
    await save();
  }

  static Future<void> setCurrentUser(User? user) async {
    if (currentUser.value != user) {
      currentUser.value = user;
      await Store.init();
    }
  }

  static Future<void> activateWeb({String? userId, bool init = false}) async {
    if (userId == null && !init) {
      currentUser.value = null;
      return;
    }
    User? user = users.firstWhereOrNull((element) => element.id == userId);
    if (user == null) {
      Json? userData = await Api.get("/profile", noXUser: true);
      if (userData != null && userData.id != null) {
        user = User("web", userData);
        users.add(user);
      }
    }
    currentUser.value = user;
  }

  static Future<bool> switchUser(String? id, [String? session]) async {
    session ??= UsersStore.user?.session;
    User? user = kIsWeb ? users.firstOrNull : users.firstWhereOrNull((element) => element.session == session);
    if (user == null) {
      return false;
    }
    Json? rez = await Api.get("/switch${id != null ? '/$id' : ''}", noXUser: true, session: kIsWeb ? null : session);
    if (!(rez?.ok ?? false)) {
      return false;
    }
    Json? userData = await Api.get("/profile", noXUser: true, session: kIsWeb ? null : session);
    if (userData == null) {
      return false;
    }

    user.data.clear();
    user.data.addAll(userData);
    currentUser.value = null;
    currentUser.value = user;

    await Store.init();

    return true;
  }

  static void forceLogin(BuildContext context, void Function() ready) {
    if (currentUser.value == null) {
      Navigator.pushNamed(context, '/profile');
    } else {
      ready();
    }
  }

  static Future<void> reloadCurrent() async {
    User? user = currentUser.value;
    if (user != null) {
      Json? userData = await Api.get("/profile", noXUser: true);
      if (userData != null) {
        user.data.clear();
        user.data.addAll(userData);
      }
    }
    currentUser.value = user;
  }

  static Future<void> revokeSession() async {
    User? user = users.firstWhereOrNull((element) => currentUser.value?.id == element.id);
    await Api.get("/logout", session: user?.session);
    if (user != null) {
      users.remove(user);
    }
  }
}

class User {
  final Json data;
  final String session;

  User(this.session, this.data);

  bool get isAdmin => data['admin'] ?? false;

  String get id => data.id!;
}
