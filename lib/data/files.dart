import 'dart:io';

import 'package:engine/api/utils/json.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FilesCache {
  static Future<Json?> getFileCache(String url) async {
    if (kIsWeb || !(await SystemCache.enable())) {
      return null;
    }

    Json? fileCache = await FileInfos.get(url);
    if (fileCache == null || fileCache['path'] == null) {
      return null;
    }
    fileCache['access'] = DateTime.now();
    FileInfos.put(url, fileCache);

    File file = File(fileCache['path']);
    if (!file.existsSync()) {
      return null;
    }
    return fileCache;
  }

  static Future<void> putFileCache(String url, Uint8List data,
      {bool failsafe = false, String? eTag, DateTime? date, DateTime? expire, DateTime? max, String? base}) async {
    if (kIsWeb || !(await SystemCache.enable())) {
      return;
    }
    File path = await SystemCache.putFile(url, data, base);
    Json file = Json();
    file['url'] = url;
    file['etag'] = eTag;
    file['date'] = date;
    file['expire'] = expire;
    file['max'] = max;
    file['path'] = path.path;
    file['access'] = DateTime.now();
    file['failsafe'] = failsafe;
    await FileInfos.put(url, file);
  }

  static Future<void> purge({int seconds = 20}) async {
    if (kIsWeb || !(await SystemCache.enable())) {
      return;
    }

    Future.delayed(Duration(seconds: seconds), () async {
      Directory cache = await getApplicationCacheDirectory();
      if (!cache.existsSync()) {
        return;
      }
      int count = 0;
      Directory data = Directory("${cache.path}/files/data");
      if (!data.existsSync()) {
        return;
      }
      List<String> toConserve = [];
      for (FileSystemEntity file in data.listSync(recursive: true)) {
        if (file.statSync().type == FileSystemEntityType.file) {
          File dataFile = File(file.path);
          try {
            Json fileCache = Json.decode(dataFile.readAsStringSync());
            File cacheFile = File(fileCache['path']);
            if (!cacheFile.existsSync()) {
              dataFile.deleteSync();
              count++;
            } else if (fileCache['failsafe'] != true &&
                (fileCache['access'] == null ||
                    fileCache.getDate('access').isBefore(DateTime.now().subtract(const Duration(days: 30))))) {
              dataFile.deleteSync();
              cacheFile.deleteSync();
              count++;
              await Future.delayed(const Duration(seconds: 100));
            } else {
              toConserve.add(fileCache['path']);
            }
          } catch (_) {
            dataFile.deleteSync();
            count++;
            await Future.delayed(const Duration(seconds: 100));
          }
        }
      }
      Directory cacheDir = await SystemCache.getCacheDirectory();
      if (cacheDir.existsSync()) {
        for (FileSystemEntity file in cacheDir.listSync(recursive: true)) {
          if (file.statSync().type == FileSystemEntityType.file) {
            if (!toConserve.contains(file.path)) {
              await file.delete();
              count++;
              await Future.delayed(const Duration(seconds: 100));
            }
          }
        }
      }
      for (Directory cacheDir in [cacheDir, data]) {
        if (cacheDir.existsSync()) {
          List<FileSystemEntity> files = cacheDir.listSync(recursive: true);
          files.removeWhere((element) => element.statSync().type != FileSystemEntityType.directory);
          files.sort((a, b) => b.path.split("/").length - a.path.split("/").length);
          for (FileSystemEntity file in files) {
            if (file.statSync().type == FileSystemEntityType.directory) {
              Directory directory = Directory(file.path);
              if (directory.listSync(recursive: false).isEmpty) {
                directory.deleteSync(recursive: false);
                await Future.delayed(const Duration(seconds: 100));
              }
            }
          }
        }
      }
      if (count > 0) {
        Fx.log("$count files cache purged");
      } else {
        Fx.log("No file cache purged");
      }
    });
  }

  static Future<void> deleteFileCache(String url) async {
    if (kIsWeb || !(await SystemCache.enable())) {
      return;
    }

    Json? fileCache = await FileInfos.get(url);
    if (fileCache == null || fileCache['path'] == null) {
      return;
    }

    File file = File(fileCache['path']);
    file.deleteSync();
  }
}

class FileInfos {
  static Future<Json?> get(String url) async {
    File file = await _getFileData(url);
    if (!file.existsSync()) {
      return null;
    }
    try {
      return Json.decode(file.readAsStringSync());
    } catch (_) {
      file.deleteSync();
      return null;
    }
  }

  static Future<void> put(String url, Json fileCache) async {
    File file = await _getFileData(url);
    try {
      file.writeAsStringSync(fileCache.encode(), flush: true);
    } catch (e) {
      Fx.log(e);
    }
  }

  static Future<File> _getFileData(String url) async {
    Directory path = await getApplicationCacheDirectory();
    if (!path.existsSync()) {
      path.createSync(recursive: true);
    }
    File data = File("${path.path}/files/data/${SystemCache.sanitize(url)}.blob");
    if (!data.existsSync()) {
      data.createSync(recursive: true);
    }
    return data;
  }
}

class SystemCache {
  static Future<File> putFile(String url, Uint8List data, [String? base]) async {
    File file = await getCacheFile(url, base);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsBytesSync(data);
    return file;
  }

  static Future<File> getCacheFile(String name, [String? base]) async {
    Directory path = await getCacheDirectory();
    if (!path.existsSync()) {
      path.createSync(recursive: true);
    }
    return File("${path.path}${base == null ? '' : '/$base'}/${sanitize(name)}.tmp");
  }

  static Future<Directory> getCacheDirectory() async {
    Directory cache = await getApplicationCacheDirectory();
    Directory path = Directory("${cache.path}/files/infos");
    if (!path.existsSync()) {
      path.createSync(recursive: true);
    }
    return path;
  }

  static Future<int> getSize() async {
    int getSize(FileSystemEntity file) {
      if (file is File) {
        return file.lengthSync();
      } else if (file is Directory) {
        int sum = 0;
        List<FileSystemEntity> children = file.listSync();
        for (FileSystemEntity child in children) {
          sum += getSize(child);
        }
        if (children.isNotEmpty) {
          sum += file.statSync().size;
        }
        return sum;
      }
      return 0;
    }

    return getSize(await getApplicationCacheDirectory());
  }

  static String sanitize(String input) {
    return input
        .replaceAll(RegExp(r'https?://', caseSensitive: false), '')
        .replaceAll(RegExp(r'([^0-9a-z\\/])', caseSensitive: false), '_');
  }

  static Future<void> disable() => SettingsStore.set("cache", false);

  static Future<bool> enable() => SettingsStore.get("cache", true);
}
