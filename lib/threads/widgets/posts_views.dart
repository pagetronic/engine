import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/profile/auth/users_utils.dart';
import 'package:engine/profile/avatar.dart';
import 'package:engine/threads/utils/threads_utils.dart';
import 'package:engine/threads/widgets/posts_images.dart';
import 'package:engine/threads/widgets/posts_inputs.dart';
import 'package:engine/utils/actions.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/main.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/sizer.dart';
import 'package:engine/utils/toast.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:engine/utils/widgets/date.dart';
import 'package:flutter/material.dart';

class PostsViewItem extends StatelessWidget {
  final Json post;
  final void Function(Json item)? onUpdate;
  final List<ModeTextEdit> editActions;
  final bool breadcrumb;
  final bool clickable;
  final String? heroTag;

  const PostsViewItem(this.post,
      {super.key,
      this.onUpdate,
      this.editActions = const [],
      this.breadcrumb = false,
      this.heroTag,
      this.clickable = false});

  @override
  Widget build(BuildContext context) {
    bool editMode = false;
    bool deleted = post['deleted'] ?? false;
    String? url = RouteSettingsSaver.routeSettings(context)?.name;
    void Function()? onTap = post['url'] != url && post['url'] != null
        ? () {
            if (history.lastBefore == post['url']) {
              Navigator.pop(context);
              return;
            }
            Navigator.pushNamed(context, post['url'], arguments: post).then(
              (post) {
                if (post != null && post is Json) {
                  onUpdate?.call(post);
                }
              },
            );
          }
        : null;
    return StatefulBuilder(
      builder: (context, setState) {
        Widget text = Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 6),
          child: !clickable
              ? SelectableText.rich(
                  PostParser.parse(context, post['text']),
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: Text.rich(
                    PostParser.parse(context, post['text']),
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                  ),
                ),
        );
        if (clickable) {
          text = SelectionArea(
            child: InkWell(onTap: onTap, child: text),
          );
        }

        return Hero(
          tag: heroTag ?? "post/${post.id}",
          child: Material(
            type: MaterialType.transparency,
            child: SizerWidget(
              sizes: const [800],
              builder: (context, maxSize) {
                bool isSmall = maxSize == 800;
                Widget content = Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 8),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: PhysicalModel(
                                elevation: 3,
                                borderRadius: const BorderRadius.all(Radius.circular(4)),
                                color: Theme.of(context).cardColor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(color: Colors.grey, width: 1),
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (editMode)
                                        Builder(
                                          builder: (context) {
                                            AppLocalizations locale = Language.of(context);
                                            TextEditingController controller = TextEditingController();
                                            controller.text = post['text'];
                                            ValueNotifier<List<Json>>? images = ValueNotifier([
                                              if (post['docs'] != null)
                                                for (Json doc in post['docs']) doc
                                            ]);

                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PostsTextInput(
                                                  editActions: editActions,
                                                  post: post,
                                                  loading: (active) {},
                                                  onCancel: () {
                                                    setState(() {
                                                      editMode = false;
                                                    });
                                                  },
                                                  images: images,
                                                  controller: controller,
                                                  hintText: locale.threads_post_hint,
                                                  after: (Json post) {
                                                    post.addAll(post);
                                                    onUpdate?.call(post);
                                                    setState(() {
                                                      editMode = false;
                                                    });
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                      else
                                        Opacity(
                                          opacity: deleted ? 0.3 : 1,
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(child: text),
                                                ],
                                              ),
                                              if (post['docs'] != null) PostsViewImagesList(post['docs']),
                                            ],
                                          ),
                                        ),
                                      if (!editMode)
                                        Container(
                                          margin: const EdgeInsets.only(top: 5),
                                          decoration: const BoxDecoration(
                                              border: Border(top: BorderSide(color: Colors.black12, width: 1))),
                                          child: Column(
                                            children: [
                                              if (breadcrumb &&
                                                  post['breadcrumb'] != null &&
                                                  !editMode &&
                                                  post['url'] != url)
                                                Container(
                                                  padding: const EdgeInsets.only(top: 5, bottom: 4),
                                                  decoration: const BoxDecoration(
                                                      border:
                                                          Border(bottom: BorderSide(color: Colors.black12, width: 1))),
                                                  child: BreadcrumbEmbedded(BreadcrumbUtils.make(post['breadcrumb']),
                                                      padding: const EdgeInsets.only(left: 10, right: 10),
                                                      fontSize: 11),
                                                ),
                                              UserBuilder(
                                                builder: (BuildContext context, Json? user) {
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                                          child: Wrap(
                                                            textDirection: TextDirection.rtl,
                                                            spacing: 20,
                                                            runSpacing: 10,
                                                            alignment: WrapAlignment.spaceBetween,
                                                            runAlignment: WrapAlignment.spaceBetween,
                                                            children: [
                                                              Wrap(
                                                                children: [
                                                                  if (user != null &&
                                                                      ((post['user'] != null &&
                                                                              post['user'].id == user.id) ||
                                                                          (user['admin'] ?? false))) ...[
                                                                    PostsViewButton(
                                                                      icon: deleted
                                                                          ? Icons.restore
                                                                          : Icons.delete_forever,
                                                                      onPressed: () {
                                                                        ActionsUtils.confirm(context, canAlways: true)
                                                                            .then(
                                                                          (type) {
                                                                            if (type != ActionsType.yes) {
                                                                              return;
                                                                            }
                                                                            setState(() {
                                                                              deleted = !deleted;
                                                                            });
                                                                            Api.post(
                                                                                "/threads",
                                                                                Json({
                                                                                  'action': 'remove',
                                                                                  'restore': !deleted,
                                                                                  'id': post.id
                                                                                })).then(
                                                                              (value) {
                                                                                if (!(value?.ok ?? false)) {
                                                                                  setState(() {
                                                                                    deleted = !deleted;
                                                                                  });
                                                                                  Messager.toast(
                                                                                      context,
                                                                                      Language.of(context)
                                                                                          .unknown_error);
                                                                                } else {
                                                                                  post['deleted'] = deleted;
                                                                                  onUpdate?.call(post);
                                                                                }
                                                                              },
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                    ),
                                                                    PostsViewButton(
                                                                      icon: Icons.edit_note,
                                                                      onPressed: () {
                                                                        setState(() {
                                                                          editMode = true;
                                                                        });
                                                                      },
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                              Wrap(
                                                                spacing: 20,
                                                                runSpacing: 10,
                                                                children: [
                                                                  PostsViewButton(
                                                                    onPressed: onTap,
                                                                    icon: Icons.question_answer_outlined,
                                                                    text: (post['replies'] ?? 0).toString(),
                                                                  ),
                                                                  LikeButton(
                                                                    type: 'post',
                                                                    onUpdate: onUpdate,
                                                                    item: post,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post['date'] != null)
                        Positioned(
                          top: 0,
                          left: 12,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                  top: 6,
                                  child: ColoredBox(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      child: const SizedBox.expand())),
                              InkWell(
                                borderRadius: BorderRadius.circular(3),
                                onTap: post['url'] != null && post['url'] != url ? onTap : null,
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Since(
                                        isoString: post['date'],
                                        style: TextStyle(
                                          fontSize: 9,
                                          decoration: post['url'] != null && post['url'] != url
                                              ? TextDecoration.underline
                                              : null,
                                          decorationStyle: TextDecorationStyle.dashed,
                                        ))),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
                return isSmall
                    ? Stack(
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 2), child: content),
                          getUserSmall(context, post),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          getUserNormal(context, post),
                          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: content)),
                        ],
                      );
              },
            ),
          ),
        );
      },
    );
  }

  Widget getUserNormal(BuildContext context, Json post) {
    return Container(
      width: 63,
      padding: const EdgeInsets.only(top: 5, left: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          getAvatar(post, ImageFormat.png48x48),
          const SizedBox(height: 5),
          Text(
            (post['user']?['name'] ?? Language.of(context).anonymous),
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget getUserSmall(BuildContext context, Json post) {
    return Positioned(
      top: 1,
      right: 12,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                post['user']?['name'] ?? Language.of(context).anonymous,
                style: const TextStyle(fontSize: 9),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(width: 5),
              getAvatar(post, ImageFormat.png24x24),
            ],
          ),
        ),
      ),
    );
  }

  Widget getAvatar(Json post, ImageFormat format) {
    Icon defAvatar = Icon(
      Icons.account_circle,
      size: format.size,
      color: Colors.grey,
    );
    if (post['user'] == null) {
      return defAvatar;
    }
    if (post['user'] == 'user') {
      return UserAvatar(format: format);
    }
    if (post['user'] == "agrobot" || post['user'].id == "agrobot") {
      return Image.asset("assets/images/agrobot.png", width: format.width, height: format.height);
    }

    if (post['user']['avatar'] != null) {
      return ImageWidget.src(post['user']['avatar'],
          format: format, errorBuilder: (context, error, stackTrace) => defAvatar);
    }

    return defAvatar;
  }
}

class PostsViewButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? text;
  final ValueNotifier<bool> hover = ValueNotifier(false);

  PostsViewButton({super.key, this.onPressed, required this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      onHover: (value) => hover.value = value,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ValueListenableBuilder(
          valueListenable: hover,
          builder: (context, hover, child) => AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hover ? 1 : 0.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                if (text != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    text!,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LikeButton extends StatelessWidget {
  final ValueNotifier<bool> loading = ValueNotifier(false);
  late final ValueStore<bool> liked;
  late final ValueStore<int> likes;
  final Json item;
  late final String parent;
  final String type;
  final Function(Json item)? onUpdate;

  LikeButton({super.key, required this.type, required this.item, this.onUpdate}) {
    parent = item.id!;
    liked = ValueStore<bool>(item['liked'] ?? false);
    likes = ValueStore<int>(item['likes'] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: loading,
      builder: (context, loading, child) => Opacity(
        opacity: loading ? 0.5 : 1,
        child: PostsViewButton(
          onPressed: loading
              ? null
              : () {
                  if (UsersStore.user == null) {
                    Navigator.of(context).pushNamed("/profile");
                    return;
                  }
                  this.loading.value = true;
                  Api.post("/likes", Json({'action': 'like', 'like': !liked.value, 'parent': parent, 'type': type}))
                      .then(
                    (value) {
                      this.loading.value = false;
                      if (value?['ok'] ?? false) {
                        if (liked.value) {
                          likes.value -= 1;
                        } else {
                          likes.value += 1;
                        }
                        item['likes'] = likes.value;
                        liked.value = !liked.value;
                        item['liked'] = liked.value;
                        onUpdate?.call(item);
                      }
                    },
                  );
                },
          icon: liked.value ? Icons.favorite : Icons.favorite_outline,
          text: likes.value.toString(),
        ),
      ),
    );
  }
}
