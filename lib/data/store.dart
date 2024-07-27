import 'dart:io';

import 'package:engine/api/api.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/range.dart';
import 'package:engine/data/states.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Store {
  static final Map<String, List<StoreItem>> _indexData = {};
  static final Map<String, List<StoreItem>> _indexCache = {};
  final StoreType type;

  Store._(this.type);

  static List<StoreItem> _indexComposed(String collection) {
    List<StoreItem> indexComposed = [];
    List<StoreItem> data = _indexData[collection]??[];
    List<StoreItem> cache = _indexCache[collection]??[];
    for (StoreItem data in data) {
      StoreItem? cached = cache.firstWhereOrNull((element) => element.id == data.id);
      indexComposed.add(cached == null ? data : StoreItem.join(data, cached));
    }
    for (StoreItem cache in cache) {
      if (indexComposed.firstWhereOrNull((element) => element.id == cache.id) == null) {
        indexComposed.add(cache);
      }
    }

    return indexComposed;
  }

  static Store get(StoreType type) {
    if (kIsWeb) {
      debugPrintStack(stackTrace: StackTrace.current, label: "No Web Store");
    }
    if (!_indexData.containsKey(type.collection)) {
      _indexData[type.collection] = [];
    }
    if (!_indexCache.containsKey(type.collection)) {
      _indexCache[type.collection] = [];
    }
    return Store._(type);
  }

  static Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    _indexData.clear();
    _indexCache.clear();
    for (Map<String, List<StoreItem>> index in [_indexData, _indexCache]) {
      Directory directory = await _getDirectory(index == _indexCache);
      for (FileSystemEntity dir in directory.listSync()) {
        FileStat stat = dir.statSync();
        if (stat.type == FileSystemEntityType.directory) {
          String collection = dir.path.split("/").last;
          if (!index.containsKey(collection)) {
            Directory collectionDir = await _getDirectory(index == _indexCache);
            if (!collectionDir.existsSync()) {
              collectionDir.createSync(recursive: true);
            }
            Iterable<File> files = collectionDir.listSync().whereType<File>();

            List<StoreItem> caches = [];
            for (File file in files) {
              if (file.path.endsWith(".json")) {
                try {
                  caches.add(index == _indexCache
                      ? StoreItem.cache(collection, Json.decode(file.readAsStringSync()))
                      : StoreItem.data(collection, Json.decode(file.readAsStringSync())));
                } catch (_) {
                  file.deleteSync();
                }
              }
              index[collection] = caches;
            }
          }
        }
      }
    }
  }

  StoreItem? getData(String id) =>
      kIsWeb ? null : _indexData[type.collection]!.firstWhereOrNull((element) => element.id == id);

  StoreItem? getCache(String id) =>
      kIsWeb ? null : _indexComposed(type.collection).firstWhereOrNull((element) => element.id == id);

  Future<Json?> getJsonCache(String id) async {
    if (kIsWeb) {
      return null;
    }
    File cacheFile = await _getFile(id, type.collection, true);
    File dataFile = await _getFile(id, type.collection, false);

    Json? cache = cacheFile.existsSync() ? Json.decode(cacheFile.readAsStringSync()) : null;
    Json? data = dataFile.existsSync() ? Json.decode(dataFile.readAsStringSync()) : null;

    if (cache == null && data == null) {
      return null;
    }
    if (cache == null && data != null) {
      return data;
    }
    if (cache != null && data == null) {
      return cache;
    }
    return cache!..addAll(data!);
  }

  Future<Json?> getJsonData(String id) async {
    if (kIsWeb) {
      return null;
    }
    File dataFile = await _getFile(id, type.collection, false);
    return dataFile.existsSync() ? Json.decode(dataFile.readAsStringSync()) : null;
  }

  Future<void> putData(Json data) async {
    if (kIsWeb) {
      return;
    }
    StoreItem? index = getData(data.id!);
    List<StoreItem> allData = _indexData[type.collection]!;
    if (index != null) {
      allData.remove(index);
    }
    Json data_ = await index?.data ?? Json();
    data_.addAll(data);
    if (data_.id != null) {
      allData.add(StoreItem.data(type.collection, data_));
      (await _getFile(data.id!, type.collection, false)).writeAsStringSync(data_.encode(), flush: true);
    }
  }

  Future<void> putCache(Json item) async {
    if (kIsWeb) {
      return;
    }
    (await _getFile(item.id!, type.collection, true)).writeAsStringSync(item.encode(), flush: true);

    StoreItem? cache = getCache(item.id!);
    StoreItem? data = getData(item.id!);

    List<StoreItem> indexCache = _indexCache[type.collection]!;

    Json cache_ = await cache?.data ?? Json();
    if (data != null) {
      Json? dataData = await data.data;
      if (dataData != null) {
        item.addAll(dataData);
        cache_.addAll(dataData);
      }
    }

    if (cache != null) {
      indexCache.remove(cache);
    }
    if (cache_.id != null) {
      indexCache.add(StoreItem.cache(type.collection, cache_));
    }
  }

  Future<Json?> update(Json data) async {
    Json? data_ = await getData(data.id!)?.data;
    if (data_ != null) {
      data_.addAll(data);
    } else {
      data_ = data;
    }
    await putData(data_);
    return data_;
  }

  Future<void> deleteData(String id) async {
    if (kIsWeb) {
      return;
    }
    StoreItem? item = getData(id);
    if (item != null) {
      _indexData[type.collection]?.remove(item);
      (await _getFile(id, type.collection, false)).deleteSync();
    }
  }

  List<StoreItem> get allCache => _indexCache[type.collection]!;

  List<StoreItem> get allData => _indexData[type.collection]!;

  List<StoreItem> where({
    States? state,
    DateTimeRangeNullable? range,
    String? parent,
    bool Function(StoreItem item)? filter,
    StoreSortType? sort,
  }) {
    if (kIsWeb) {
      return [];
    }
    List<StoreItem> items = _indexComposed(type.collection).where(
      (item) {
        return (filter == null || filter(item)) &&
            (state == null || state == item.state) &&
            (parent == "all" || parent == item.parent) &&
            (range == null || range.between(item.date));
      },
    ).toList();

    if (sort != null) {
      items.sort(sort.sort);
    }

    return items;
  }

  List<StoreItem> whereData({
    States? state,
    DateTimeRangeNullable? range,
    String? parent,
    bool Function(StoreItem item)? filter,
    int Function(StoreItem a, StoreItem b)? sort,
  }) {
    if (kIsWeb) {
      return [];
    }
    List<StoreItem> items = _indexData[type.collection]!.where(
      (item) {
        return (filter == null || filter(item)) &&
            (state == null || state == item.state) &&
            (parent == "all" || parent == item.parent) &&
            (range == null || range.between(item.date));
      },
    ).toList();

    if (sort != null) {
      items.sort(sort);
    }

    return items;
  }

  Future<List<Json>> search(bool Function(Json item) filter) async {
    if (kIsWeb) {
      return [];
    }
    List<Json> result = [];
    for (StoreItem item in _indexData[type.collection]!) {
      Json? data = await item.data;
      if (data != null && filter(data)) {
        result.add(data);
      }
    }
    return result;
  }

  Future<List<Json>> get data => kIsWeb ? Future.value([]) : asData(_indexData[type.collection]!);

  static Future<Directory> _getDirectory(bool cached) async {
    Directory cache = await (cached ? getApplicationCacheDirectory() : getApplicationSupportDirectory());
    Directory directory = Directory("${cache.path}/data/${Users.id}");
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return directory;
  }

  static Future<File> _getFile(String id, String collection, bool cached) async {
    File file = File("${(await _getDirectory(cached)).path}/$collection/$id.json");
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }

  static const Uuid uuid = Uuid();

  static String getId() => "${uuid.v1().replaceAll("-", "").toUpperCase()}@LOCAL";

  static Future<List<Json>> asData(List<StoreItem> items) async {
    if (kIsWeb) {
      return [];
    }
    List<Json> items_ = [];
    for (StoreItem item in items) {
      Json? data = await item.data;
      if (data != null) {
        items_.add(data);
      }
    }
    return items_;
  }

  Future<Json?> populate(
    Json? rez, {
    States? state,
    DateTimeRangeNullable? range,
    String? parent,
    bool Function(StoreItem item)? filter,
    required StoreSortType sort,
  }) async {
    if (rez == null) {
      rez = Json({
        "result": await asData(where(
          range: range,
          parent: parent,
          state: States.active,
          sort: parent == "all" ? StoreSortType.byUpdate : StoreSortType.byIndex,
        ))
      });
      return rez;
    }
    List<Json> result = rez.result;
    for (StoreItem item in whereData(parent: parent, range: range, state: state)) {
      Json? data = await item.data;
      if (data != null) {
        Json? exist = result.firstWhereOrNull((element) => element.id == item.id);
        if (exist != null) {
          exist.addAll(data);
        } else {
          result.add(data);
        }
      }
    }
    result.sort(sort.sort);
    rez.result = result;
    return rez;
  }

  static Future<void> clearCache() async {
    if (kIsWeb) {
      return;
    }
    Directory directory = await getApplicationCacheDirectory();
    directory.deleteSync(recursive: true);
    for (String key in _indexCache.keys.toList()) {
      _indexCache.remove(key);
    }
  }
}

class StoreItem implements Indexable {
  late final String collection;
  @override
  late final String? id;
  @override
  late final DateTime? date;
  @override
  late final DateTime? update;
  @override
  late final int? index;
  @override
  late String? parent;
  @override
  late final States? state;
  late final StoreItemType type;

  StoreItem._(
    this.collection,
    this.type,
    Json data,
  ) {
    id = data.id!;
    date = data.date;
    update = data.update;
    index = data['index'];
    parent = data['parent'];
    state = data.state;
  }

  StoreItem.data(String collection, Json data) : this._(collection, StoreItemType.data, data);

  StoreItem.cache(String collection, Json data) : this._(collection, StoreItemType.cache, data);

  StoreItem.join(StoreItem store, StoreItem cached) {
    collection = store.collection;
    type = StoreItemType.composed;
    id = store.id;
    date = cached.date ?? store.date;
    update = cached.update ?? store.update;
    index = cached.index ?? store.index;
    parent = cached.parent ?? store.parent;
    state = cached.state ?? store.state;
  }

  Future<Json?> get data async {
    File dataFile = await Store._getFile(id!, collection, false);
    File cacheFile = await Store._getFile(id!, collection, true);
    switch (type) {
      case StoreItemType.data:
        return dataFile.existsSync() ? Json.decode(dataFile.readAsStringSync()) : null;
      case StoreItemType.cache:
        return dataFile.existsSync() ? Json.decode(dataFile.readAsStringSync()) : null;
      case StoreItemType.composed:
        Json? data = dataFile.existsSync() ? Json.decode(dataFile.readAsStringSync()) : null;
        Json cache = cacheFile.existsSync() ? Json.decode(cacheFile.readAsStringSync()) : Json();
        if (data != null) {
          cache.addAll(data);
        }
        return cache;
    }
  }
}

enum StoreItemType { cache, data, composed }

class StoreType {
  final String collection;

  const StoreType(this.collection);

  static const StoreType images = StoreType("images");
}

enum StoreSortType {
  byDate,
  byUpdate,
  byIndex;

  int sort(Indexable a, Indexable b) {
    switch (this) {
      case byDate:
        return _sortByDate(a, b);
      case byUpdate:
        return _sortByUpdate(a, b);
      case byIndex:
        return _sortByIndex(a, b);
    }
  }

  int _sortByDate(Indexable a, Indexable b) {
    try {
      if (a.date == null || b.date == null) {
        return b.id!.compareTo(a.id!) + 1000;
      }
      return a.date!.isAtSameMomentAs(b.date!) ? b.id!.compareTo(a.id!) : b.date!.compareTo(a.date!);
    } catch (e) {
      Fx.log(e);
    }
    return -1;
  }

  int _sortByUpdate(Indexable a, Indexable b) {
    try {
      if (a.update == null || b.update == null) {
        return b.id!.compareTo(a.id!) + 1000;
      }
      return a.update!.isAtSameMomentAs(b.update!) ? b.id!.compareTo(a.id!) : b.update!.compareTo(a.update!);
    } catch (e) {
      Fx.log(e);
    }
    return -1;
  }

  int _sortByIndex(Indexable a, Indexable b) {
    try {
      int aIndex = (a.index ?? -1);
      int bIndex = (b.index ?? -1);
      return aIndex == bIndex ? (a.id ?? "").compareTo((b.id ?? "")) : aIndex.compareTo(bIndex);
    } catch (e) {
      Fx.log(e);
    }
    return -1;
  }
}

abstract class Indexable {
  String? id;
  DateTime? date;
  DateTime? update;
  int? index;
  String? parent;
  States? state;
}

extension ListUtilsData<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
