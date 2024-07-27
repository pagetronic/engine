import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/widgets/photos.dart';
import 'package:flutter/material.dart';

class PostsImageInput extends StatelessWidget {
  final ValueNotifier<List<Json>> images;

  const PostsImageInput(this.images, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Json>>(
      valueListenable: images,
      builder: (context, List<Json> images, child) {
        if (images.isEmpty) {
          return const SizedBox(height: 1);
        }
        return SizedBox(
          height: 73,
          child: ListView.builder(
            itemCount: images.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 5),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: images[index].id == null && images[index]['XFile'] == null
                      ? const CircularLoading(
                          height: 60,
                          width: 90,
                        )
                      : images[index]['XFile'] != null
                          ? Opacity(
                              opacity: 0.5, child: XFileImage.widget(images[index]['XFile'], width: 90, height: 60))
                          : InkWell(
                              onTap: () {
                                PhotoDialog.show(context, images[index]['src'], heroId: images[index]['id']);
                              },
                              child: Hero(
                                tag: images[index].id!,
                                child: Stack(
                                  children: [
                                    ImageWidget.json(
                                      images[index]['src'],
                                      format: ImageFormat.png90x60,
                                    ),
                                    Positioned(
                                      right: -8,
                                      top: -8,
                                      child: IconButton(
                                        onPressed: () {
                                          Api.post("/blobs", Json({"action": "delete", "id": images[index].id}));
                                          images.removeAt(index);
                                          this.images.value = [for (Json image in images) image];
                                        },
                                        icon: const Stack(
                                          children: [
                                            Positioned(
                                                left: 1.0,
                                                top: 2.0,
                                                child: Icon(Icons.close, color: Colors.black54, size: 16)),
                                            Icon(Icons.close, color: Colors.white, size: 16)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class PostsViewImagesList extends StatelessWidget {
  final List<Json> images = [];

  PostsViewImagesList(List images, {super.key}) {
    if (images.isNotEmpty) {
      this.images.addAll(images as List<Json>);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox(height: 4);
    }
    return SizedBox(
      height: 132,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        itemCount: images.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 5, right: 5, bottom: 12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () => PhotoDialog.show(context, images[index]['src'], heroId: images[index]['id']),
                child: Hero(
                  tag: images[index].id!,
                  child: ImageWidget.json(images[index], format: ImageFormat.png180x120),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
