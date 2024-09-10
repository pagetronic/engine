import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:engine/api/utils/json.dart';
import 'package:engine/api/utils/settings.dart';
import 'package:engine/blobs/picker.dart';
import 'package:engine/data/files.dart';
import 'package:engine/utils/async.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:intl/intl.dart';

enum ImageFormat {
  png16x16(16, 16, 'png'),
  png20x20(20, 20, 'png'),
  png24(24, null, 'png'),
  png24x24(24, 24, 'png'),
  png32x32(32, 32, 'png'),
  png36x36(36, 36, 'png'),
  png40(40, null, 'png'),
  png48x48(48, 48, 'png'),
  png60x60(60, 60, 'png'),
  png64(64, null, 'png'),
  png96x96(96, 96, 'png'),
  png90x60(90, 60, 'png'),
  png100x100(100, 100, 'png'),
  png128x128(128, 128, 'png'),
  png164x164(164, 164, 'png'),
  png180x120(180, 120, 'png'),
  png348x232(348, 232, 'png');

  final double? width;
  final double? height;
  final String? extension;

  const ImageFormat(this.width, this.height, this.extension);

  String get marker => ""
      "${width != null || height != null ? "@" : ""}"
      "${width?.toInt() ?? ""}"
      "${height != null ? "x${height!.toInt()}" : ""}"
      "${extension != null ? ".$extension" : ""}";

  double? get size {
    if (width != null && height != null) {
      return width! > height! ? height : width;
    }
    return width ?? height;
  }
}

typedef ImageLoadingBuilder = Widget Function(BuildContext context, Widget? child);
typedef ImageErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

class ImageWidget {
  static Widget json(Json src,
      {ImageFormat? format, BoxFit? fit, ImageLoadingBuilder? loadingBuilder, ImageErrorBuilder? errorBuilder}) {
    Uint8List? bytes;
    if (src['file']?['bytes'] != null) {
      bytes = ImageMemoryCache.get(src.id!);
      if (bytes == null) {
        bytes = src.bytes;
        if (bytes != null) {
          ImageMemoryCache.add(src.id!, bytes);
        }
      }
    }
    return FutureOrBuilder(
      future: bytes ?? ImageNetworkCache.standard().readBytes(src.src! + (format?.marker ?? "")),
      builder: (context, snapshot) => builder(context, snapshot, format, fit, loadingBuilder, errorBuilder),
    );
  }

  static Widget src(String src,
      {ImageFormat? format, BoxFit? fit, ImageLoadingBuilder? loadingBuilder, ImageErrorBuilder? errorBuilder}) {
    return FutureOrBuilder(
      future: ImageNetworkCache.standard().readBytes(src + (format?.marker ?? "")),
      builder: (context, snapshot) => builder(context, snapshot, format, fit, loadingBuilder, errorBuilder),
    );
  }

  static Widget builder(BuildContext context, AsyncSnapshot<Uint8List?> snapshot, ImageFormat? format, BoxFit? fit,
      ImageLoadingBuilder? loadingBuilder, ImageErrorBuilder? errorBuilder) {
    if (snapshot.connectionState != ConnectionState.done) {
      return loadingBuilder != null
          ? loadingBuilder(context, null)
          : ImageLoading(width: format?.width, height: format?.height);
    }
    if (snapshot.data == null) {
      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        width: format?.width,
        height: format?.height,
        child: Center(
          child: errorBuilder != null
              ? errorBuilder(context, "error", snapshot.stackTrace)
              : Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.red,
                  size: format?.size != null ? max(32, format!.size! - 100) : null,
                ),
        ),
      );
    }
    Image image = Image.memory(
      snapshot.data!,
      width: format?.width,
      height: format?.height,
      fit: fit,
      errorBuilder: errorBuilder,
    );

    return loadingBuilder == null ? image : loadingBuilder(context, image);
  }
}

class ImageNetworkCache {
  final BaseClient httpClient;

  ImageNetworkCache({required this.httpClient});

  static ImageNetworkCache standard() {
    return ImageNetworkCache(httpClient: RetryClient(Client()));
  }

  FutureOr<Uint8List?> readBytes(String? url, {Map<String, String>? headers, String? base}) {
    if (url == null || url == "") {
      return null;
    }
    Uint8List? cache = ImageMemoryCache.get(url);
    if (cache != null) {
      return cache;
    }
    Completer<Uint8List?> completer = Completer();
    complete(Uint8List? bytes) {
      if (bytes != null) {
        ImageMemoryCache.add(url, bytes);
      }
      completer.complete(bytes);
    }

    Future.delayed(Duration.zero).then((value) async {
      if (kIsWeb) {
        Response response = await httpClient.get(Uri.parse(url));
        Uint8List bytes = response.bodyBytes;
        complete(bytes);
        return;
      }

      Json? fileData;
      try {
        fileData = await FilesCache.getFileCache(url);
      } catch (_) {
        FilesCache.deleteFileCache(url);
      }

      Map<String, String> queryHeaders = {};
      if (headers != null) {
        queryHeaders.addAll(headers);
      } else {
        queryHeaders['User-Agent'] = await Settings.userAgent;
      }

      if (fileData != null) {
        if (fileData["max"] != null && fileData.getDate("max").isAfter(DateTime.now())) {
          Uint8List bytes = await File(fileData['path']).readAsBytes();
          complete(bytes);
          return;
        }

        if (fileData["expire"] != null) {
          queryHeaders['If-Modified-Since'] =
              DateFormat('E, d MMM yyyy hh:mm:ss Z', 'en_US').format(fileData.getDate("expire"));
        }
        if (fileData["etag"] != null) {
          queryHeaders['If-None-Match'] = fileData["etag"]!;
        }
      }
      //Fx.log("GetImage: $url");
      try {
        Future<Response> query = httpClient.get(Uri.parse(url), headers: queryHeaders);

        Response response = await query;
        if (fileData != null && response.statusCode == 304) {
          Uint8List bytes = await File(fileData['path']).readAsBytes();
          complete(bytes);
          return;
        }
        if (response.statusCode != 200) {
          complete(null);
          return;
        }
        Uint8List bytes = response.bodyBytes;

        try {
          await FilesCache.putFileCache(
            url,
            bytes,
            eTag: response.headers['Etag'] ?? response.headers['etag'],
            date: _getDate(response.headers),
            expire: _getExpire(response.headers),
            max: _getMaxAge(response.headers),
            base: base ?? 'images',
          );
        } finally {}

        complete(bytes);
      } catch (e) {
        complete(null);
      }
    });
    return completer.future;
  }

  DateTime? _getExpire(Map<String, String> headers) {
    try {
      return headers['Expire'] == null && headers['expire'] == null
          ? null
          : DateFormat('E, d MMM yyyy hh:mm:ss Z', 'en_US').parse(headers['Expire'] ?? headers['expire']!);
    } catch (e) {
      return null;
    }
  }

  DateTime? _getMaxAge(Map<String, String> headers) {
    try {
      DateTime maxAge = DateTime.now();
      String? cacheControlString = headers['Cache-Control'] == null && headers['cache-control'] == null
          ? null
          : headers['Cache-Control'] ?? headers['cache-control']!;
      if (cacheControlString != null) {
        RegExp exp = RegExp(r'max-age=([0-9]+)');
        if (exp.hasMatch(cacheControlString)) {
          RegExpMatch? match = exp.firstMatch(cacheControlString);
          maxAge = maxAge.add(Duration(seconds: int.parse(match![1]!)));
          return maxAge;
        }
      }
    } finally {}
    return null;
  }

  DateTime? _getDate(Map<String, String> headers) {
    try {
      return headers['Date'] == null && headers['date'] == null
          ? null
          : DateFormat('E, d MMM yyyy hh:mm:ss Z', 'en_US').parse(headers['Date'] ?? headers['date']!);
    } catch (e) {
      return null;
    }
  }
}

class XFileImage {
  static Widget widget(XFile src, {double? width, double? height}) {
    return FutureBuilder(
        future: src.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ImageLoading(width: width, height: height);
          }
          if (snapshot.data == null) {
            return Icon(Icons.image_not_supported_outlined, color: Colors.red[900], size: width ?? height);
          }
          return Image.memory(snapshot.data!, width: width, height: height);
        });
  }
}

class ImageLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData icon;

  const ImageLoading({super.key, this.width, this.height, this.icon = Icons.filter_vintage});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      width: width,
      height: height,
      child: Center(
        child: StreamBuilder(
          stream: Stream<double>.periodic(const Duration(milliseconds: 600), (count) => count % 2),
          builder: (context, snapshot) {
            return AnimatedOpacity(
                opacity: min(0.5, max(0.2, snapshot.data ?? 0)),
                duration: const Duration(milliseconds: 400),
                child:
                    Icon(icon, size: width != null && height != null && width! > height! ? height : (width ?? height)));
          },
        ),
      ),
    );
  }
}

class ImagesSize {
  static Future<Size?> getSize(String src) async {
    return getSizeBytes(await ImageNetworkCache.standard().readBytes(src));
  }

  static getSizeBytes(Uint8List? bytes) {
    if (bytes == null) {
      return null;
    }
    Completer<Size> completer = Completer();
    Image.memory(bytes).image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          var myImage = image.image;
          Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        },
      ),
    );

    return completer.future;
  }
}

class ImageMemoryCache {
  static const double _maxStoreInBytes = 200 * 1e+6;
  static final ValueStore<double> _size = ValueStore(0);
  static final LinkedHashMap<String, Uint8List> _images = LinkedHashMap(
      equals: (p0, p1) => p0 == p1, hashCode: (p0) => p0.hashCode, isValidKey: (key) => (key ?? "").isNotEmpty);

  static Uint8List? get(String url) {
    Uint8List? bytes = _images[url];
    if (bytes != null) {
      _images.remove(url);
      _images[url] = bytes;
      return bytes;
    }
    return null;
  }

  static void add(String url, Uint8List bytes) {
    try {
      if (_size.value + bytes.lengthInBytes > _maxStoreInBytes) {
        _purge(bytes.lengthInBytes);
      }
      _images[url] = bytes;
      _size.value = _size.value + bytes.lengthInBytes;
    } catch (_) {
      _purge(bytes.lengthInBytes);
    }
  }

  static void _purge(int lengthInBytes) {
    for (String key in _images.keys.toList()) {
      _size.value = _size.value - (_images.remove(key)?.lengthInBytes ?? 0);
      if (_size.value + lengthInBytes < _maxStoreInBytes) {
        return;
      }
    }
  }
}
