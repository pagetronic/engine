import 'package:engine/lng/language.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/text.dart';
import 'package:flutter/material.dart';

class Ux {
  static Widget loading(BuildContext context, {Duration? delay, double? size}) {
    return SizedBox(
      height: size ?? 100,
      width: size ?? 100,
      child: Padding(
        padding: EdgeInsets.all(size != null ? size / 5 : 20),
        child: Center(
          child: Loading(delay: delay),
        ),
      ),
    );
  }

  static Widget emptyList(BuildContext context, String? text, {Key? key}) {
    return Row(
        key: key,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: H6(text ?? Language.of(context).empty_result))
        ]);
  }
}
