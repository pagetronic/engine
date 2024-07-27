import 'dart:convert';
import 'dart:typed_data';

import 'package:engine/data/states.dart';
import 'package:engine/data/store.dart';
import 'package:engine/utils/colors.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Json implements Indexable {
  final Map<String, dynamic> data = {};

  Json([Map<dynamic, dynamic>? map]) {
    if (map != null) {
      for (dynamic key in map.keys) {
        data[key] = map[key];
      }
    }
  }

  Json.decode(String data) {
    if (data.isNotEmpty) {
      this.data.addAll(jsonDecode(data));
    }
  }

  @override
  String? get id => data['id'];

  bool get ok => data['ok'] ?? false;

  bool get isEmpty => data.isEmpty;

  String? get src => this['src'] ?? this['asset']?['src'];

  Uint8List? get bytes {
    String? bytesString = this['bytes'] ?? this['file']?['bytes'];
    if (bytesString != null) {
      return base64.decode(bytesString);
    }
    return null;
  }

  List<Json> get result {
    List<Json> result = [];
    if ((this['result'] ?? []).isNotEmpty) {
      result.addAll(this['result']);
    }
    return result;
  }

  set result(List<Json> result) => this['result'] = result;

  @override
  States? get state {
    for (States state in States.values) {
      if (state.state == this['state']) {
        return state;
      }
    }
    return null;
  }

  @override
  set state(States? state) {
    data['state'] = state?.state;
  }

  set id(String? id) {
    data['id'] = id;
  }

  String encode() => jsonEncode(data);

  dynamic operator [](String key) {
    if (!data.containsKey(key)) {
      return null;
    }
    if (data[key] is Map) {
      data[key] = Json(data[key]);
    } else if (data[key] is List<dynamic>) {
      final List<dynamic> list = data[key];
      if (list.isNotEmpty && list[0] is Map) {
        final List<Json> result = [];
        for (dynamic item in data[key]) {
          result.add(Json(item));
        }
        data[key] = result;
      }
    }
    return data[key];
  }

  void operator []=(String key, dynamic value) {
    if (value is DateTime) {
      data[key] = value.toJson();
    } else if (value is Color) {
      data[key] = value.toHex();
    } else {
      data[key] = value;
    }
  }

  @override
  DateTime? get date => data['date'] != null ? DateTime.parse(data['date']) : null;

  DateTime get dateNotNull => data['date'] != null ? DateTime.parse(data['date']) : DateTime.utc(0);

  @override
  set date(DateTime? date) => data['date'] = date?.toJson();

  @override
  DateTime? get update => data['update'] != null ? DateTime.parse(data['update']) : null;

  DateTime get updateNotNull => data['update'] != null ? DateTime.parse(data['update']) : DateTime.utc(0);

  @override
  set update(DateTime? update) => data['update'] = update?.toJson();

  DateTime getDate(String key) {
    return data[key] != null ? DateTime.parse(data[key]) : DateTime.utc(0);
  }

  Color? get color {
    if (data['color'] == null) {
      return null;
    }
    return HexColor.fromHex(data['color']);
  }

  set color(Color? color) {
    if (color == null) {
      this['color'] = null;
    } else {
      this['color'] = color.toHex();
    }
  }

  Json clone() => Json(data);

  void addAll(Json item) {
    data.addAll(item.data);
  }

  bool containsKey(String key) {
    return data.containsKey(key);
  }

  dynamic remove(String key) {
    return data.remove(key);
  }

  void clear() {
    data.clear();
  }

  /*needed for jsonDecode*/
  factory Json.fromJson(Map<String, dynamic> json) => Json(json);

  /*needed for jsonEncode*/
  Map<String, dynamic> toJson() => data;

  @override
  int? get index => this['index'];

  @override
  String? get parent => this['parent'];

  @override
  set index(int? index) {
    this['index'] = index;
  }

  @override
  set parent(String? parent) {
    this['parent'] = parent;
  }
}

extension JsonDateTime on DateTime {
  String toJson() {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS+0000").format(toUtc());
  }
}

class ValueNotifierJson extends ValueNotifier<Json?> {
  ValueNotifierJson([super._value]);

  @override
  set value(Json? newValue) {
    if ((super.value?.encode() ?? "") == (newValue?.encode() ?? "")) {
      return;
    }
    super.value = newValue;
    notifyListeners();
  }

  void operator []=(String key, dynamic value) {
    Json json = (this.value ?? Json()).clone();
    if (value is DateTime) {
      json[key] = value.toJson();
    } else if (value is Color) {
      json[key] = value.toHex();
    } else {
      json[key] = value;
    }
    this.value = json;
  }
}
