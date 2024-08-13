import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/blobs/picker.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/defer.dart';
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

class UserSwitcher extends StatelessWidget {
  final ImageFormat format;
  final Deferrer deferrer = Deferrer(700);

  UserSwitcher({super.key, this.format = ImageFormat.png60x60});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, value, child) {
        if (UsersStore.user == null) {
          return const SizedBox.shrink();
        }

        PageController controller = PageController(initialPage: 0, keepPage: false);
        List<dynamic> allUsers = UsersStore.allUsers;
        for (int i = 0; i < allUsers.length; i++) {
          if (allUsers[i] == UsersStore.user) {
            controller = PageController(initialPage: i, keepPage: false);
            break;
          }
        }

        Widget avatar(Json user) {
          return user['avatar'] != null
              ? ImageWidget.src(user['avatar'],
                  format: ImageFormat.png60x60,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.account_circle_outlined, size: format.size, color: Colors.white))
              : Icon(Icons.account_circle_outlined, size: format.size, color: Colors.white);
        }

        int length = allUsers.length;
        if (length == 1) {
          return avatar(UsersStore.user!.data);
        }

        return SizedBox(
          width: format.size,
          height: format.size,
          child: PageView.builder(
            itemCount: length,
            scrollDirection: Axis.vertical,
            pageSnapping: true,
            onPageChanged: (index) {
              deferrer.defer(
                () {
                  if (allUsers[index] is User) {
                    UsersStore.setCurrentUser(allUsers[index]);
                  } else {
                    UsersStore.switchUser(allUsers[index].id);
                  }
                },
              );
            },
            controller: controller,
            itemBuilder: (context, index) {
              if (index >= length) {
                return null;
              }
              dynamic user_ = allUsers[index];
              return avatar(user_ is User ? user_.data : user_);
            },
          ),
        );
      },
    );
  }
}
