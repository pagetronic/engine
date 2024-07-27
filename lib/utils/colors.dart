import 'dart:math';

import 'package:flutter/material.dart';

class ColorsUtils {
  static Random rand = Random();

  static Color random() {
    return Color(rand.nextInt(0xFFFFFF)).withOpacity(1.0);
  }
}

extension HexColor on Color {
  static Color? fromHex(String? hexString) {
    if (hexString == null) {
      return null;
    }
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {}
    return null;
  }

  String toHex() => '#'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
