import 'dart:async';

import 'package:engine/api/utils/json.dart';
import 'package:engine/pages/pages_search.dart';
import 'package:engine/utils/base.dart';
import 'package:flutter/widgets.dart';

class PageChooser {
  static Future<String?> choose(BuildContext context, {String? initial}) async {
    BaseRoute? route = BaseRoute.maybeOf(context);
    if (route == null) {
      return null;
    }
    Completer<String?> completer = Completer();
    route.dialogModal.setModal(PageSearcher(
        initial: initial,
        onSelect: (Json? page) {
          completer.complete(page?.id);
          route.dialogModal.setModal(null);
        }));

    return completer.future;
  }
}
