import 'package:flutter/services.dart';
import "package:yaml/yaml.dart";

class Settings {
  static const double maxWidth = 1000;
  static String? _userAgent;

  static String? _apiBase;
  static String? _baseUrl;

  static Future<String> get apiBase async {
    if (_apiBase == null) {
      await _load();
    }
    return _apiBase!;
  }

  static Future<String> get userAgent async {
    if (_userAgent == null) {
      await _load();
    }
    return _userAgent!;
  }

  static Future<String> get baseUrl async {
    if (_baseUrl == null) {
      await _load();
    }
    return _baseUrl!;
  }

  static Future<void> _load() async {
    final mapData = loadYaml(await rootBundle.loadString('assets/conf/settings.yaml'));
    _userAgent = mapData['userAgent'] ?? 'Agroneo 0.1 // Software for Earth growers -> agroneo.com';
    _apiBase = mapData['apiBase'] ?? "https://api.agroneo.com";
    _baseUrl = mapData['baseUrl'] ?? "https://agroneo.com";
  }
}
