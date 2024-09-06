import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/socket/channels.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/buttons.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:engine/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NoticesButton extends StatefulWidget {
  const NoticesButton({super.key});

  @override
  NoticesButtonState createState() => NoticesButtonState();
}

class NoticesButtonState extends State<NoticesButton> with ChannelFollowable {
  final ValueNotifier<String?> notices = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: Language.of(context).notifications,
      child: ValueListenableBuilder(
        valueListenable: UsersStore.currentUser,
        builder: (context, user, child) {
          notices.value = user?.data['notices'];
          return ValueListenableBuilder(
            valueListenable: notices,
            builder: (context, notices, child) => IconButton(
              onPressed: () {
                if (user == null) {
                  Navigator.pushNamed(context, "/profile");
                  return;
                }
                NoticesView.view(context);
              },
              icon: getIcon(notices),
            ),
          );
        },
      ),
    );
  }

  Widget getIcon(String? notices) {
    if (notices == null) {
      return const Icon(Icons.notifications_off_outlined);
    }

    if (notices != "0") {
      return Row(children: [
        const Icon(Icons.notifications_active),
        const SizedBox(width: 3),
        Text(
          notices,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ]);
    }
    return const Icon(Icons.notifications_none);
  }

  @override
  void initState() {
    super.initState();
    follow(Channel.simple("user")).then((stream) {
      stream.listen((user) {
        if (user['action'] == "notices") {
          notices.value = user["notices"];
          Fx.log(user["notices"]);
        }
      });
    });
  }

  @override
  void dispose() {
    unfollowAll();
    super.dispose();
  }
}

class NoticesView extends StatefulWidget {
  const NoticesView({super.key});

  @override
  NoticesViewState createState() => NoticesViewState();

  static Future<dynamic> view(BuildContext context) {
    return Navigator.push(context, PageRouteEffects.slideLoad(const NoticesView()));
  }

  static bool isNoticesView(BuildContext context) {
    if (context is StatefulElement && context.state is NoticesViewState) {
      return true;
    }
    return context.findAncestorStateOfType<NoticesViewState>() != null;
  }
}

class NoticesViewState extends BaseRoute<NoticesView> {
  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    return ApiListView(
      request: (paging) async {
        return Result(await Api.get("/notices", paging: paging));
      },
      getView: (context, item, index) {
        return Column(
          children: [Text("index $index"), Text(item.toString())],
        );
      },
    );
  }

  @override
  List<ActionMenuItem> getBaseActionsMenu() {
    return [];
  }

  @override
  String? getTitle() {
    return Language.of(context).notifications;
  }
}

class FollowButton extends StatelessWidget {
  final Channel channel;
  final double? size;
  static const osNotifications = MethodChannel('osNotifications');

  const FollowButton(this.channel, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    if (UsersStore.user == null) {
      return const SizedBox.shrink();
    }

    final Future<bool> hasOsNotifications = this.hasOsNotifications();
    final Future<String?> control = this.control();

    return FutureBuilder(
      future: hasOsNotifications,
      builder: (context, hasOsNotifications) {
        return FutureBuilder(
          future: control,
          builder: (context, snapshotControl) {
            if (snapshotControl.connectionState != ConnectionState.done ||
                hasOsNotifications.connectionState != ConnectionState.done) {
              return Opacity(
                  opacity: 0.4,
                  child: ButtonIcon(
                    size: size,
                    icon: Symbols.notifications_paused,
                  ));
            }

            bool capable = hasOsNotifications.data ?? false;
            String? type = snapshotControl.data;
            return StatefulBuilder(
              builder: (context, setState) {
                return ButtonIcon(
                  opacity: type != null && type != 'off' ? 1 : null,
                  size: size,
                  onTapDown: (details) {
                    AppLocalizations locale = Language.of(context);
                    showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        items: [
                          if (capable && type != 'os')
                            PopupMenuItem<String>(
                              value: "os",
                              child: Row(
                                children: [
                                  const Icon(Symbols.wifi_notification),
                                  const SizedBox(width: 5),
                                  Text(locale.notifications_os)
                                ],
                              ),
                            ),
                          if (type == 'off' || type == 'os')
                            PopupMenuItem<String>(
                              value: "app",
                              child: Row(
                                children: [
                                  const Icon(Symbols.notifications_active),
                                  const SizedBox(width: 5),
                                  Text(locale.notifications_app)
                                ],
                              ),
                            ),
                          if (type != 'off')
                            PopupMenuItem<String>(
                              value: "off",
                              child: Row(
                                children: [
                                  const Icon(Symbols.notifications_off),
                                  const SizedBox(width: 5),
                                  Text(locale.notifications_off)
                                ],
                              ),
                            )
                        ]).then(
                      (chosen) {
                        register(chosen).then(
                          (_) {
                            setState(
                              () {
                                type = chosen;
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                  icon: type == 'os'
                      ? Symbols.wifi_notification
                      : type == 'app'
                          ? Symbols.notifications_active
                          : Symbols.notifications_off,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> hasOsNotifications() async {
    try {
      bool? hasWebPush = await osNotifications.invokeMethod<bool?>("hasOsNotifications");
      return hasWebPush ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> register(String? type) async {
    if (type != null) {
      await Api.post("/notices", Json({"action": 'subscribe', 'channel': channel, 'type': type}));
    }
  }

  Future<String?> control() async {
    Json? control = await Api.post("/notices", Json({'action': 'control', 'channel': channel}));
    return control?['type'] ?? 'off';
  }
}
