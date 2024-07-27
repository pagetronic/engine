import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/platform/folds.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/widgets/photos.dart';
import 'package:flutter/widgets.dart';

class GalleryChooser extends StatelessWidget {
  static String baseUrl = "/blobs";
  final void Function(Json img) onSelect;

  const GalleryChooser({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return PhotoList(
      request: (String? paging) async {
        return Result(await Api.get("/blobs", paging: paging));
      },
      onSelect: onSelect,
    );
  }

  static void pop(BuildContext context, {required void Function(Json? img) onSelect}) {
    Navigator.push(
      context,
      PageRouteEffects.slideLoad(
        Builder(
          builder: (context) {
            return LowFold(
              title: Language.of(context).gallery,
              body: PhotoList(
                  request: (String? paging) async {
                    return Result(await Api.get("/blobs", paging: paging));
                  },
                  onSelect: (img) {
                    onSelect(img);
                    Navigator.pop(context);
                  },
                  addGallery: false),
            );
          },
        ),
      ),
    );
  }
}
