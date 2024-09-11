import 'package:engine/api/api.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/blobs/picker.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final ImageFormat format;
  final Widget? fail;

  const UserAvatar({super.key, this.format = ImageFormat.png32x32, this.fail});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, user, child_) {
        if (user?.data['avatar'] != null) {
          return ImageWidget.json(user!.data['avatar'], format: format);
        }
        return fail ?? Icon(Icons.account_circle, size: format.size);
      },
    );
  }
}

class Avatar extends StatelessWidget {
  final ImageFormat? format;
  final Future<void> Function()? onChange;
  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  late final ValueNotifier<String> url;

  Avatar(String url, {super.key, this.format, this.onChange}) {
    this.url = ValueNotifier<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    ImageFormat format = this.format ?? ImageFormat.png48x48;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        ImagePicker.getImage(
            context: context,
            onPick: (XFile? file) {
              loading.value = true;
            }).then(
          (image) async {
            if (image != null) {
              await Api.post(
                  "/profile",
                  Json({
                    "action": "avatar",
                    "avatar": image.id,
                  }));
              url.value = image['src'];
              await UsersStore.reloadCurrent();
              onChange?.call();
            }
            loading.value = false;
          },
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: format.width,
          height: format.height,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5))),
          child: ValueListenableBuilder(
            valueListenable: loading,
            builder: (context, loading, child) => ValueListenableBuilder(
              valueListenable: url,
              builder: (context, url, child) => loading
                  ? ImageLoading(width: format.width, height: format.height)
                  : ImageWidget.src(url, format: format),
            ),
          ),
        ),
      ),
    );
  }
}
