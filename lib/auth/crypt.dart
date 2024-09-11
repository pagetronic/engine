import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:engine/api/utils/json.dart';
import 'package:path_provider/path_provider.dart';

class Crypto {
  static final IV _iv = IV.fromUtf8("1tPglISafFdVnId");
  static final Encrypter _crypt = Encrypter(AES(Key.fromUtf8("9r5SY8fGjusEVHVD")));

  static Future<void> crypt(Json data) async {
    try {
      String dataString = data.encode();
      Encrypted encrypted = _crypt.encrypt(dataString, iv: _iv);
      File file = await _getFile();
      await file.writeAsBytes(encrypted.bytes, flush: true);
    } catch (_) {}
  }

  static Future<Json?> decrypt() async {
    File file = await _getFile();
    try {
      String decrypt = _crypt.decrypt(Encrypted(await file.readAsBytes()), iv: _iv);
      return Json.decode(decrypt);
    } catch (_) {
      return null;
    }
  }

  static Future<File> _getFile() async {
    Directory cache = await getApplicationSupportDirectory();
    File file = File("${cache.path}/.users");
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}
