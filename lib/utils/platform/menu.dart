import 'package:engine/api/utils/json.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/profile/avatar.dart';
import 'package:flutter/material.dart';

class GlobalMenu {
  static ImageFormat format = ImageFormat.png32x32;

  static Widget? getBurger(List<GlobalMenuItem>? menus, String? title, String? slogan) {
    if (menus == null) {
      return null;
    }

    return SafeArea(
      left: false,
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Colors.white,
            child: ListView(
              shrinkWrap: true,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 15, bottom: 18, left: 10, right: 6),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
                  child: ValueListenableBuilder(
                    valueListenable: UsersStore.currentUser,
                    builder: (context, currentUser, child) {
                      Json? user = currentUser?.data;
                      if (user != null) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UserSwitcher(),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'],
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSecondary)),
                                Text(user['idn'] ?? user.id,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary)),
                              ],
                            ))
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Image.asset("assets/images/logo.png", height: 60, width: 60),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Text(title,
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSecondary)),
                              if (slogan != null)
                                Text(slogan,
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSecondary)),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ),
                for (GlobalMenuItem menu in menus)
                  Builder(
                    builder: (context) {
                      ValueNotifier<List<ChildrenMenuItem>?> submenu = ValueNotifier(null);
                      return Column(
                        children: [
                          ListTile(
                            leading: menu.icon != null
                                ? Icon(menu.icon,
                                    size: 22,
                                    color: menu.onTap == null && menu.children == null ? Colors.grey : Colors.black54)
                                : const SizedBox(width: 22),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(menu.title,
                                    style: TextStyle(
                                        color:
                                            menu.onTap == null && menu.children == null ? Colors.grey : Colors.black)),
                                if (menu.children != null)
                                  InkWell(
                                      onTap: () {
                                        submenu.value = submenu.value == null ? menu.children : null;
                                      },
                                      child: ValueListenableBuilder(
                                          valueListenable: submenu,
                                          builder: (context, submenu, child) {
                                            return Icon(submenu == null ? Icons.chevron_right : Icons.expand_more);
                                          }))
                              ],
                            ),
                            onTap: menu.onTap == null
                                ? (menu.children != null
                                    ? () {
                                        submenu.value = submenu.value == null ? menu.children : null;
                                      }
                                    : null)
                                : () {
                                    Navigator.of(context).pop();
                                    menu.onTap!();
                                  },
                          ),
                          ValueListenableBuilder(
                            valueListenable: submenu,
                            builder: (context, submenu, child) {
                              if (submenu == null || submenu.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 5, bottom: 15),
                                child: Column(
                                  children: [
                                    for (ChildrenMenuItem menu in submenu)
                                      ListTile(
                                        leading: menu.icon != null
                                            ? Icon(menu.icon,
                                                size: 22, color: menu.onTap == null ? Colors.grey : Colors.black54)
                                            : const SizedBox(width: 22),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                        title: Text(menu.title),
                                        onTap: menu.onTap == null
                                            ? null
                                            : () {
                                                Navigator.of(context).pop();
                                                menu.onTap!();
                                              },
                                      )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      );
                    },
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget? getRail(List<GlobalMenuItem>? menus) {
    if (menus == null) {
      return null;
    } else {
      ValueNotifier<List<ChildrenMenuItem>?> submenu = ValueNotifier(null);
      return Builder(
        builder: (context) {
          return Material(
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        color: Theme.of(context).shadowColor,
                        spreadRadius: -1.5,
                        blurRadius: 2,
                        offset: const Offset(1, 0))
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ValueListenableBuilder(
                            valueListenable: UsersStore.currentUser,
                            builder: (context, userStore, child) {
                              Json? user = userStore?.data;
                              Brightness brightness = Theme.of(context).brightness;
                              Color unActive = brightness == Brightness.dark ? Colors.white30 : Colors.black26;
                              Color active = brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]!;
                              return Column(
                                children: [
                                  for (GlobalMenuItem menu in menus)
                                    if ((menu.type == GlobalMenuItemType.admin && !(user?['admin'] ?? false)) ||
                                        (menu.type == GlobalMenuItemType.auth && user == null))
                                      const SizedBox.shrink()
                                    else
                                      InkWell(
                                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                                        onTap: menu.onTap ??
                                            () {
                                              submenu.value =
                                                  menu.children != null && submenu.value == null ? menu.children : null;
                                            },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              if ((menu.icon != null && menu.type != GlobalMenuItemType.profile) ||
                                                  (menu.type == GlobalMenuItemType.profile && user?['avatar'] == null))
                                                Icon(menu.icon,
                                                    size: format.size,
                                                    color: menu.onTap != null || (menu.children ?? []).isNotEmpty
                                                        ? active
                                                        : unActive),
                                              if (menu.type == GlobalMenuItemType.profile && user?['avatar'] != null)
                                                Container(
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: const BoxDecoration(
                                                        borderRadius: BorderRadius.all(Radius.circular(5))),
                                                    child: ImageWidget.src(
                                                      user!['avatar'],
                                                      format: format,
                                                      errorBuilder: (context, error, stackTrace) => Icon(menu.icon,
                                                          size: format.size,
                                                          color: menu.onTap != null || (menu.children ?? []).isNotEmpty
                                                              ? active
                                                              : unActive),
                                                      loadingBuilder: (context, child) =>
                                                          child ??
                                                          Icon(menu.icon,
                                                              size: format.size,
                                                              color:
                                                                  menu.onTap != null || (menu.children ?? []).isNotEmpty
                                                                      ? active
                                                                      : unActive),
                                                    )),
                                              const SizedBox(width: 6),
                                              Text(
                                                  menu.type == GlobalMenuItemType.profile
                                                      ? (user?['name'] ?? menu.title)
                                                      : menu.title,
                                                  maxLines: 2,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      overflow: TextOverflow.ellipsis,
                                                      fontSize: 12,
                                                      color: menu.onTap != null || (menu.children ?? []).isNotEmpty
                                                          ? active
                                                          : unActive),
                                                  softWrap: true)
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: submenu,
                      builder: (context, submenu, child) {
                        if (submenu == null || submenu.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            constraints: const BoxConstraints(maxWidth: 200, minWidth: 80),
                            child: ListView(
                              padding: const EdgeInsets.only(top: 20),
                              children: submenu
                                  .map((subItem) => InkWell(
                                        onTap: subItem.onTap,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                          child: Text(
                                            subItem.title,
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ));
                      },
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}

class GlobalMenuItem {
  final String title;
  final IconData? icon;
  final void Function()? onTap;
  final GlobalMenuItemType type;
  final List<ChildrenMenuItem>? children;

  const GlobalMenuItem(this.title, {this.icon, this.onTap, this.type = GlobalMenuItemType.standard, this.children});
}

class ChildrenMenuItem {
  final String title;
  final IconData? icon;
  final void Function()? onTap;
  final GlobalMenuItemType type;

  const ChildrenMenuItem(this.title, {this.icon, this.onTap, this.type = GlobalMenuItemType.standard});
}

enum GlobalMenuItemType { standard, profile, auth, admin }
