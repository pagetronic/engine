import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/blobs/picker.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/actions.dart';
import 'package:engine/utils/async.dart';
import 'package:engine/utils/icons.dart';
import 'package:engine/utils/lists/grid_api.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/toast.dart';
import 'package:engine/utils/widgets/date.dart';
import 'package:engine/utils/widgets/zoomer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PhotoList extends StatefulWidget {
  final ImageFormat format;
  final Future<bool> Function(Json img)? onAdd;
  final Future<bool> Function(Json img)? onRemove;
  final void Function(Json img)? onSelect;
  final Future<Result> Function(String? paging) request;
  final Result? initial;
  final ScrollController? controller;
  final bool addGallery;

  const PhotoList({
    super.key,
    this.format = ImageFormat.png348x232,
    this.initial,
    this.onAdd,
    this.onRemove,
    this.onSelect,
    this.addGallery = true,
    this.controller,
    required this.request,
  });

  @override
  PhotoListState createState() => PhotoListState();
}

class PhotoListState extends State<PhotoList> {
  ApiGridView? grid;

  @override
  Widget build(BuildContext context) {
    grid = ApiGridView(
      initial: widget.initial,
      controller: widget.controller,
      spacing: 1,
      request: widget.request,
      itemBuilder: photoItemBuilder,
      header: header(context),
      maxWidth: widget.format.width!.toInt(),
    );
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3), child: grid!);
  }

  Widget header(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10, left: 10, right: 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 3,
        child: InkWell(
          onTap: () {
            UsersStore.forceLogin(context, () {
              ImagePicker.getImage(context: widget.addGallery ? context : null).then((Json? newImage) async {
                if (newImage != null) {
                  bool ok = await widget.onAdd?.call(newImage) ?? true;
                  if (ok) {
                    grid!.insert(newImage);
                  } else {
                    if (context.mounted) {
                      Messager.toast(context, locale.unknown_error);
                    }
                  }
                }
              });
            });
          },
          child: const Icon(Icons.add_circle_outline_rounded, size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  Widget photoItemBuilder(BuildContext context, Json photo, int index) {
    AppLocalizations locale = Language.of(context);
    return InkWell(
      onTap: widget.onSelect != null
          ? () => widget.onSelect!(photo)
          : photo.src == null
              ? null
              : () => PhotoDialog.show(
                    context,
                    photo.src! + (photo["type"] == "image/svg+xml" ? "@1024.png" : ""),
                    heroId: photo['id'],
                  ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: photo.id!,
              child: ImageWidget.json(photo, format: widget.format, fit: BoxFit.cover),
            ),
          ),
          if (photo['date'] != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ColoredBox(
                color: Colors.black.withOpacity(0.4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Since(
                          locale: locale.since_date,
                          isoString: photo['date'],
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onRemove != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                  onPressed: () {
                    ActionsUtils.confirm(context, canAlways: true, title: locale.delete_confirm).then((value) async {
                      if (value == ActionsType.yes) {
                        bool ok = await widget.onRemove!(photo);
                        if (!ok) {
                          if (context.mounted) {
                            Messager.toast(context, locale.unknown_error);
                          }
                          return;
                        }
                        grid!.remove(photo);
                      }
                    });
                  },
                  icon: const ShadowIcon(Icons.close)),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}

class PhotoDialog {
  static Future<void> show(context, String src, {String? heroId}) async {
    FutureOr<Uint8List?> image = ImageNetworkCache.standard().readBytes(src);
    GlobalKey<ButterflyLoadingState> butterflyKey = GlobalKey();
    ButterflyLoading loading = ButterflyLoading(key: butterflyKey);
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        opaque: false,
        maintainState: true,
        barrierColor: Colors.black.withOpacity(0.5),
        fullscreenDialog: true,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Hero(
            tag: heroId ?? "unknown",
            child: FutureOrBuilder(
              future: image,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Listener(onPointerDown: (event) => Navigator.pop(context), child: loading);
                } else if (snapshot.data == null) {
                  return Listener(
                      onPointerDown: (event) {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.red[900], size: 150));
                }
                butterflyKey.currentState?.stop.value = true;
                double lastRotate = 0;
                ValueNotifier<double> rotate = ValueNotifier(0);
                return DoubleTappableInteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.05,
                  maxScale: 50,
                  scaleFactor: 500,
                  constrained: true,
                  onInteractionStart: (details) {},
                  onInteractionUpdate: (details) {
                    rotate.value = lastRotate + details.rotation;
                  },
                  onInteractionEnd: (details) {
                    lastRotate = rotate.value;
                  },
                  onTap: () => Navigator.pop(context),
                  child: ValueListenableBuilder(
                    valueListenable: rotate,
                    builder: (BuildContext context, double value, Widget? child) {
                      return Transform.rotate(
                        angle: value,
                        child: child ??
                            Padding(
                                padding: const EdgeInsets.all(20),
                                child: Image.memory(snapshot.data!, fit: BoxFit.scaleDown)),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
