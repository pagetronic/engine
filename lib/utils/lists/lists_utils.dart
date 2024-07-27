import 'package:flutter/material.dart';

class StyleListView {
  static const BorderSide border = BorderSide(color: Colors.black12);

  static Color getOddEvenColor(int index) {
    return index.isEven ? Colors.black.withOpacity(0.015) : Colors.white.withOpacity(0.015);
  }

  static BoxDecoration getOddEvenBoxDecoration(int index, {Color? color, List<BoxShadow>? shadow}) {
    return BoxDecoration(
      boxShadow: shadow,
      color: color ?? getOddEvenColor(index),
      border: index == 0 ? const Border(bottom: border) : const Border(bottom: border),
    );
  }
}

enum LoadingDirection { toTop, toBottom }
