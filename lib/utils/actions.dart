import 'dart:async';

import 'package:engine/lng/language.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/fx.dart';
import 'package:flutter/material.dart';

class ActionsUtils {
  static final ValueStore<bool> confirmAll = ValueStore(false);

  static Future<ActionsType> confirm(BuildContext context, {bool canAlways = false, String? title, String? content}) {
    if (canAlways && confirmAll.value) {
      return Future<ActionsType>(() => ActionsType.yes);
    }

    AppLocalizations locale = Language.of(context);
    BaseRoute? route = BaseRoute.maybeOf(context);
    Completer<ActionsType> action = Completer();

    Widget getDialog(void Function() done) {
      return AlertDialog(
        title: Text(title ?? locale.confirmation),
        // On web the filePath is a blob url
        // while on other platforms it is a system path.
        content: content != null ? Text(content) : null,
        elevation: 10,
        actions: [
          if (canAlways)
            TextButton(
              child: Text(locale.always),
              onPressed: () {
                confirmAll.value = true;
                done();
                action.complete(ActionsType.yes);
              },
            ),
          FilledButton(
            child: Text(locale.yes),
            onPressed: () {
              done();
              action.complete(ActionsType.yes);
            },
          ),
          TextButton(
              child: Text(locale.no),
              onPressed: () {
                done();
                action.complete(ActionsType.no);
              })
        ],
      );
    }

    if (route != null) {
      route.dialogModal.setModal(getDialog(() {
        route.dialogModal.setModal(null);
      }));
      route.dialogModal.onDismiss(() {
        action.complete(ActionsType.cancel);
      });
    } else {
      showDialog<void>(
        useRootNavigator: false,
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return getDialog(() {
            Navigator.of(context).pop();
          });
        },
      ).then((value) {
        if (!action.isCompleted) {
          action.complete(ActionsType.cancel);
        }
      });
    }
    return action.future;
  }
}

enum ActionsType { yes, no, cancel }
