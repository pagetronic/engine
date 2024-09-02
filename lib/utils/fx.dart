// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Fx {
  static void log(var obj, [bool debug = false]) {
    if (!debug || (debug && kDebugMode)) {
      print("${DateFormat('HH:mm:ss.SSS').format(DateTime.now())}: ${obj.toString()}");
    }
  }

  static String humanReadableBytes(num size,
      {String? locale, int minimumFractionDigits = 0, int maximumFractionDigits = 2}) {
    const List<String> units = ['o', 'Ko', 'Mo', 'Go', 'To', 'Po', 'Eo', 'Zo', 'Yo'];

    double log10(num x) => math.log(x) / math.ln10;
    RegExp removeTrailingZerosRegex = RegExp(r'([.]*0)(?!.*\d)');

    String toLocaleString(num number, String? locale, int minimumFractionDigits, int maximumFractionDigits) {
      if (locale == null) {
        return number.toStringAsFixed(maximumFractionDigits).replaceAll(removeTrailingZerosRegex, '');
      }
      NumberFormat formatter = NumberFormat(null, locale);
      formatter.minimumFractionDigits = minimumFractionDigits;
      formatter.maximumFractionDigits = maximumFractionDigits;
      return formatter.format(number);
    }

    if (size == 0) {
      return '0 ${units[0]}';
    }

    bool isNegative = size < 0;
    String prefix = isNegative ? '-' : '';
    if (isNegative) {
      size = -size;
    }

    int exponent = (log10(size) / log10(1024)).floor();
    exponent = math.min(exponent, units.length - 1);

    size /= math.pow(1024, exponent);
    String numberStr = toLocaleString(size, locale, minimumFractionDigits, maximumFractionDigits);
    String unit = units[exponent];

    return '$prefix$numberStr $unit';
  }
}

class ValueStore<T> {
  T value;

  ValueStore(this.value);
}

extension ListUtilsData<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (T element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
