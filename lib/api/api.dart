import 'package:engine/api/http/http.dart';
import 'package:engine/api/network.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/range.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/data/states.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

export 'package:engine/api/utils/json.dart';

class Api {
  static Future<Json?> post(String url, Json data,
      {String? apiBase, String? session, bool anonymous = false, bool noXUser = false}) async {
    apiBase ??= await Settings.apiBase;

    url = "$apiBase$url";
    //Fx.log("PostApi: $url");
    try {
      http.Response response = await AdaptiveClient.getClient(anonymous).post(
        Uri.parse(url),
        headers: await _getHeaders(session: session, anonymous: anonymous),
        body: data.encode(),
      );
      if (!noXUser && session == null && !anonymous) {
        await Users.updateXUser(response.headers);
      }
      if (response.statusCode == 401) {
        return null;
      }
      return Json.decode(response.body);
    } catch (_) {
      return null;
    }
  }

  static Future<Json?> get(
    String url, {
    Map<String, String>? parameters,
    String? lng,
    String? paging,
    DateTimeRangeNullable? range,
    String? apiBase,
    String? session,
    bool anonymous = false,
    bool noXUser = false,
  }) async {
    //await Future.delayed(Duration(seconds: 1));
    apiBase ??= await Settings.apiBase;
    url = "$apiBase$url";

    if (parameters != null) {
      for (String name in parameters.keys) {
        url += "${url.contains("?") ? "&" : "?"}$name=${Uri.encodeComponent(parameters[name]!)}";
      }
    }
    if (lng != null) {
      url += "${url.contains("?") ? "&" : "?"}lng=$lng";
    }
    if (range != null) {
      url += "${url.contains("?") ? "&" : "?"}range=${range.query}";
    }
    if (paging != null) {
      url += "${url.contains("?") ? "&" : "?"}paging=$paging";
    }

    //Fx.log("GetApi: $url");
    try {
      http.Response response = await AdaptiveClient.getClient(anonymous).get(
        Uri.parse(url),
        headers: await _getHeaders(session: session, anonymous: anonymous),
      );
      if (session == null && !noXUser && !anonymous) {
        await Users.updateXUser(response.headers);
      }
      if (response.statusCode == 401) {
        return null;
      }
      Json rez = Json.decode(response.body);

      networkAvailable.value = true;

      if (rez['error'] != null) {
        Fx.log("Api error : ${rez['error']}");
        Fx.log(url);
        return null;
      }
      return rez;
    } catch (_) {
      networkAvailable.value = false;
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders({String? session, bool anonymous = false}) async {
    session ??= Users.getSession();
    Map<String, String> headers = {};
    headers['Content-Type'] = 'application/json';
    if (!kIsWeb && session != null && !anonymous) {
      headers['Authorization'] = session;
    }
    if (!kIsWeb) {
      headers['User-Agent'] = await Settings.userAgent;
    }
    return headers;
  }

  static Future<Json?> getExternal(String url, {anonymous = false}) async {
    try {
      Map<String, String> headers = {};
      if (!kIsWeb) {
        headers['User-Agent'] = await Settings.userAgent;
      }
      http.Response response = await AdaptiveClient.getClient(anonymous).get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 401) {
        return null;
      }
      return Json.decode(response.body);
    } catch (_) {}
    return null;
  }
}

class Result {
  final List<Json> result = [];
  String? next;
  String? prev;

  Result([Json? rez]) {
    if (rez == null) {
      return;
    }
    next = rez['paging']?['next'];
    prev = rez['paging']?['prev'];

    for (Json item in rez.result) {
      result.add(item);
    }
  }

  Result.populate(List<dynamic> result) {
    if (result.isNotEmpty) {
      for (var element in result) {
        this.result.add(element);
      }
    }
  }

  String? get paging => next ?? prev;

  void clear() {
    result.clear();
    next = null;
    prev = null;
  }

  filter({String? parent, DateTimeRangeNullable? range, States? state}) {}
}
