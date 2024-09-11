import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/api/html/html.dart';
import 'package:engine/api/utils/html.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/auth/users_utils.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/pages/pages_chooser.dart';
import 'package:engine/socket/channels.dart';
import 'package:engine/threads/widgets/posts_inputs.dart';
import 'package:engine/threads/widgets/posts_views.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/error.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/main.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:engine/utils/platform/menu.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:flutter/material.dart';

mixin ThreadViewer<T extends StatefulWidget> on BaseRoute<T> {
  final ValueNotifierJson thread = ValueNotifierJson();
  ApiListView? list;

  final TextEditingController controller = TextEditingController();
  final ValueNotifier<List<Json>> images = ValueNotifier([]);

  Json? getThread();

  LoadingDirection direction = LoadingDirection.toTop;

  @override
  List<GlobalMenuItem>? getMenu() {
    return getThread() == null ? getBaseMenu(null) : null;
  }

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    direction = (RouteSettingsSaver.routeSettings(context)?.name ?? getThread()?['url']).endsWith("/last")
        ? LoadingDirection.toTop
        : LoadingDirection.toBottom;
    Future<Json?> get() async {
      return (await Api.get(RouteSettingsSaver.routeSettings(context)?.name ?? getThread()?['url'])) ??
          Json({"error": 404});
    }

    if (getThread() == null) {
      Json? data = HtmlDocumentData.getData("thread");
      if (data == null) {
        thread.value = await get();
      } else {
        thread.value = data;
      }
    } else {
      thread.value = getThread()!;
      thread.value = await get();
    }
    if (thread.value?.id != null) {
      Stream<Json> stream = await follow(Channel("posts", thread.value!.id!));
      stream.listen((event) {
        list?.update(event);
      });
    }
    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    if (thread.value?['error'] != null) {
      return const NotFoundView();
    }
    if (thread.value?.id == null) {
      return const CaterpillarDelayedLoading();
    }
    AppLocalizations locale = Language.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, thread.value);
        }
      },
      child: list = ApiListView(
        padding: const EdgeInsets.only(top: 5),
        insertToBottom: true,
        noEmpty: true,
        noRefresh: true,
        sticky: 10,
        oddEven: false,
        initial: thread.value?['posts'] != null ? Result(thread.value!['posts']) : null,
        direction: direction,
        header: ValueListenableBuilder(
          valueListenable: thread,
          builder: (context, thread, child) {
            return Column(
              children: [
                if (thread!['parent'] != null)
                  Row(
                    children: [
                      const Spacer(flex: 1),
                      Expanded(
                        flex: 9,
                        child: PostsViewItem(
                          thread['parent'],
                          heroTag: "parent/${thread['parent'].id}",
                          onUpdate: (Json item) {
                            this.thread['parent'] = item;
                          },
                        ),
                      ),
                    ],
                  ),
                PostsViewItem(
                  breadcrumb: true,
                  followable: Channel("posts", thread.id!),
                  editActions: [
                    if (Users.isAdmin) ...[ModeTextEdit.question, ModeTextEdit.rewrite],
                    ModeTextEdit.title
                  ],
                  thread,
                  onUpdate: (Json item) {
                    this.thread.value = item;
                  },
                ),
              ],
            );
          },
        ),
        footer: UserLoginOrWidget(
          child: PostsTextInput(
            actions: Users.isAdmin ? [ModeTextEdit.rewrite] : [],
            images: images,
            parent: "Posts/${thread.value!.id}",
            hintText: locale.threads_reply_hint,
            after: (Json post) {
              list?.update(post);
              thread['replies'] = (thread.value!['replies'] ?? 0) + 1;
            },
            controller: controller,
          ),
        ),
        request: (String? paging) async {
          if (thread.value?['url'] == null) {
            return null;
          }
          Json? result = await Api.get(thread.value?['url'], paging: paging);
          if (result?['posts'] == null) {
            return null;
          }
          return Result(result?['posts']);
        },
        getView: (BuildContext context, Json item, index) {
          return PostsViewItem(
            item.clone(),
            onUpdate: (Json itemUpdate) {
              if (itemUpdate['deleted'] != item['deleted']) {
                thread['replies'] = (thread.value!['replies'] ?? 0) + (itemUpdate['deleted'] ? -1 : 1);
              }
              list?.update(itemUpdate);
            },
          );
        },
      ),
    );
  }

  @override
  FutureOr<List<BreadcrumbItem>>? getBreadcrumb() async {
    List<BreadcrumbItem> breadcrumb = [];
    if (thread.value?['breadcrumb'] != null && thread.value!['breadcrumb'].isNotEmpty) {
      for (dynamic bread in thread.value!['breadcrumb']) {
        breadcrumb.add(BreadcrumbItem(HtmlEscaper.unescape(bread['title']), (BuildContext context) {
          if (history.lastBefore == bread['url']) {
            Navigator.pop(context);
            return;
          }
          Navigator.pushNamed(context, bread['url'], arguments: bread);
        }));
      }
      if (thread.value!['title'] != null) {
        breadcrumb.add(BreadcrumbItem(HtmlEscaper.unescape(thread.value!['title'])));
      }
    }
    return breadcrumb;
  }

  @override
  List<ActionMenuItem> getActionsMenu() {
    return [
      if (Users.isAdmin) ...[
        ActionMenuItem(
          icon: Icons.move_up_outlined,
          title: Language.of(context).move,
          onSelect: () {
            PageChooser.choose(context, initial: thread.value?['title']).then(
              (parent) {
                if (parent != null) {
                  Api.post("/threads", Json({'action': 'post', 'id': thread.value!.id, 'parent': "Pages/$parent"}))
                      .then((rez) {
                    if (rez != null) {
                      thread.value?.addAll(rez['post']);
                      reload();
                    }
                  });
                }
              },
            );
          },
        ),
      ]
    ];
  }

  @override
  String? getTitle() {
    return HtmlEscaper.unescape(thread.value?['title'] ?? super.getTitle());
  }
}
