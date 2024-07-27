import 'dart:math';

import 'package:flutter/material.dart';

class FreeScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  FreeScrollView({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        verticalController.jumpTo(
            max(0, min(verticalController.position.maxScrollExtent, verticalController.offset - details.delta.dy)));
        horizontalController.jumpTo(
            max(0, min(horizontalController.position.maxScrollExtent, horizontalController.offset - details.delta.dx)));
      },
      child: SingleChildScrollView(
        controller: verticalController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.only(top: padding?.top ?? 0, bottom: padding?.bottom ?? 0),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(left: padding?.left ?? 0, right: padding?.right ?? 0),
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}
