import 'dart:async';

import 'package:engine/api/utils/json.dart';
import 'package:engine/blobs/picker/picker_os.dart'
    if (dart.library.html) 'package:engine/blobs/picker/picker_web.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/gallery.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

export 'package:image_picker/image_picker.dart';

class ImagePicker {
  static Future<Json?> getImage({BuildContext? context, void Function(XFile? file)? onPick}) {
    Completer<Json?> completer = Completer<Json?>();
    pick() {
      TypedFilePicker()
          .getImageUpload(source: ImageSource.gallery, onPick: onPick)
          .then((img) => completer.complete(img));
    }

    if (context == null) {
      pick();
    } else {
      AppLocalizations locale = Language.of(context);
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            elevation: 5,
            title: Text(locale.gallery_choose_source),
            actions: [
              FilledButton(
                child: Text(locale.gallery_gallery_source),
                onPressed: () {
                  Navigator.pop(context);
                  GalleryChooser.pop(
                    context,
                    onSelect: (Json? img) {
                      if (onPick != null) {
                        onPick(null);
                      }
                      completer.complete(img);
                    },
                  );
                },
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  pick();
                },
                child: Text(locale.gallery_upload_source),
              ),
            ],
          );
        },
      );
    }
    return completer.future;
  }
}

enum ImagePickerType { upload, gallery }

abstract class TypedFilePickerAbstract {
  Future<Json?> getImageUpload({required ImageSource source, void Function(XFile? file)? onPick});
}
