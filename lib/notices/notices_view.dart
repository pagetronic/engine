import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/notices/notices.dart';
import 'package:engine/socket/channels.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/buttons.dart';
import 'package:engine/utils/device/device.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/url/url.dart';
import 'package:engine/utils/widgets/date.dart';
import 'package:flutter/material.dart';

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
    List<String> unsubscribe = [];
    ApiListView? list;
    return FutureBuilder(
      future: Device.uuid,
      builder: (context, deviceData) {
        if (deviceData.connectionState != ConnectionState.done) {
          return const Loading(delay: Duration(milliseconds: 100));
        }
        String? device = deviceData.data;
        return list ??= ApiListView(
          request: (paging) async {
            return Result(await Api.get("/notices", paging: paging));
          },
          getView: (context, item, index) {
            return Column(
              children: [
                InkWell(
                  onTap: item['url'] == null
                      ? null
                      : () {
                          NoticesUtils.read(item['ids']).then(
                            (_) {
                              list?.update(item..['read'] = true);
                            },
                          );
                          if (item['url'].startsWith("http")) {
                            UrlOpener.open(item['url']);
                          } else {
                            Navigator.of(context).pushNamed(item['url']);
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Opacity(
                      opacity: (item['read'] ?? false) ? 0.5 : 1,
                      child: Row(
                        children: [
                          if (item['icon'] != null) ImageWidget.src(item['icon'], format: ImageFormat.png32x32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                H4(item['title'] ?? ''),
                                Since(isoString: item['date']),
                                Text(item['message'] ?? ''),
                              ],
                            ),
                          ),
                          if (item['count'] != null) Big("${item['count']}", fontSize: 25),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    ButtonIcon(
                      icon: Icons.delete_forever_outlined,
                      text: Language.of(context).notifications_delete,
                      onPressed: () {
                        Api.post(
                            "/notices",
                            Json({
                              "action": 'remove',
                              'ids': item['ids'],
                            })).then(
                          (_) {
                            list?.remove(item.id);
                          },
                        );
                      },
                    ),
                    if (item['devices'].contains(device) && !unsubscribe.contains(item['channel']))
                      ButtonIcon(
                        onPressed: () {
                          Api.post(
                              "/notices",
                              Json({
                                "action": 'subscribe',
                                'channel': item['channel'],
                                'type': "off",
                              })).then(
                            (_) {
                              unsubscribe.add(item['channel']);
                              list?.update(item);
                            },
                          );
                        },
                        icon: Icons.not_interested,
                        text: Language.of(context).notifications_disable_channel,
                      )
                  ],
                )
              ],
            );
          },
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
