import 'package:engine/admin/ai/ai.dart';
import 'package:engine/admin/ai/questions.dart';
import 'package:engine/api/api.dart';
import 'package:engine/blobs/picker.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/threads/widgets/posts_images.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/sizer.dart';
import 'package:engine/utils/toast.dart';
import 'package:engine/utils/widgets/form/form_utils.dart';
import 'package:flutter/material.dart';

class PostsTextInput extends StatelessWidget {
  late final TextEditingController textController;
  late final TextEditingController titleController;
  final String? hintText;
  final bool active;
  final bool avatar;
  final ValueNotifier<List<Json>>? images;
  final void Function()? onCancel;
  final String? parent;
  final String? route;
  final void Function(bool active)? loading;
  final void Function(Json post)? after;
  final BoxDecoration? decoration;
  final ValueNotifier<bool> loadingModal = ValueNotifier(false);
  final Json? post;
  final int? lines;
  final void Function(String text)? onPost;
  final List<ModeTextEdit> actions;
  final List<ModeTextEdit> editActions;
  final EdgeInsetsGeometry? padding;

  PostsTextInput({
    super.key,
    this.parent,
    this.route,
    this.loading,
    TextEditingController? controller,
    this.hintText,
    void Function()? onFocus,
    this.active = true,
    this.images,
    this.onCancel,
    this.after,
    this.decoration,
    this.post,
    this.lines,
    this.padding,
    this.onPost,
    this.actions = const [],
    this.editActions = const [],
    this.avatar = false,
  }) {
    textController = controller ?? TextEditingController();
    textController.addListener(() {
      if (onFocus != null) {
        onFocus!();
        onFocus = null;
      }
      if (textController.value.text.length > 3000) {
        textController.text = textController.value.text.substring(0, 3000);
      }
    });

    titleController = TextEditingController();
    titleController.text = post?['title'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    return ValueListenableBuilder(
      valueListenable: loadingModal,
      builder: (context, loading, child) => Stack(
        children: [
          Container(
            padding: padding ?? const EdgeInsets.all(10),
            decoration: decoration ?? StyleListView.getOddEvenBoxDecoration(0),
            child: SafeArea(
              right: false,
              child: Column(
                children: [
                  if (editActions.contains(ModeTextEdit.title))
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: TextField(
                        autocorrect: true,
                        enabled: active,
                        onSubmitted: (_) {
                          submit(context);
                        },
                        minLines: 1,
                        maxLines: 10,
                        maxLength: 70,
                        decoration: InputDecoration(
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          hintText: locale.title,
                        ),
                        controller: titleController,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: SizerWidget(
                      sizes: const [600],
                      builder: (context, maxSize) {
                        TextField textField = TextField(
                          enabled: active,
                          maxLength: 3000,
                          autocorrect: true,
                          onSubmitted: (_) {
                            submit(context);
                          },
                          minLines: lines ?? 1,
                          maxLines: lines ?? 10000,
                          decoration: InputDecoration(
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            border: InputBorder.none,
                            hintText: hintText ?? locale.bot_ask_hint,
                          ),
                          controller: textController,
                        );
                        Row buttons = Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (actions.contains(ModeTextEdit.rewrite))
                            IconButton(
                              onPressed: () => aiReply(context),
                              icon: const Icon(Icons.quickreply),
                            ),
                          if (images != null)
                            IconButton(
                              onPressed: !active
                                  ? null
                                  : () {
                                      Json tempImage = Json();
                                      ImagePicker.getImage(
                                          context: context,
                                          onPick: (XFile? file) {
                                            if (file != null) {
                                              tempImage['XFile'] = file;
                                              images!.value = [
                                                for (Json image in images!.value) image,
                                                tempImage,
                                              ];
                                            }
                                          }).then((newImage) {
                                        if (newImage != null) {
                                          images!.value = [
                                            for (Json image in images!.value)
                                              if (tempImage != image) image,
                                            newImage,
                                          ];
                                        }
                                      });
                                    },
                              icon: const Icon(Icons.add_a_photo_outlined),
                            ),
                          if (images != null) const SizedBox(width: 5),
                          if (onCancel != null)
                            IconButton(
                              onPressed: onCancel!,
                              icon: const Icon(Icons.cancel_outlined),
                            ),
                          if (onCancel != null) const SizedBox(width: 5),
                          IconButton(
                            onPressed: !active
                                ? null
                                : () {
                                    submit(context);
                                  },
                            icon: const Icon(Icons.send),
                          )
                        ]);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (maxSize == 600)
                              Column(children: [textField, buttons])
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: textField,
                                  ),
                                  const SizedBox(width: 5),
                                  buttons
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (editActions.contains(ModeTextEdit.rewrite))
                                  IconButton(
                                    tooltip: "Rewrite input",
                                    onPressed: () => aiRewrite(context),
                                    icon: const Icon(Icons.copyright),
                                  ),
                                if (editActions.contains(ModeTextEdit.question))
                                  IconButton(
                                    tooltip: "Rewrite question",
                                    onPressed: () => aiRewriteQuestion(context),
                                    icon: const Icon(Icons.psychology_alt),
                                  ),
                              ],
                            ),
                            if (images != null) PostsImageInput(images!),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).dialogTheme.shadowColor ?? Colors.black.withOpacity(0.5),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  void submit(BuildContext context) {
    if (onPost != null) {
      onPost!(textController.value.text);
      return;
    }
    if (textController.value.text.isNotEmpty) {
      _onPost(textController.value.text, context).then((value) {
        if (value) {
          textController.text = "";
          if (images != null) {
            images!.value = [];
          }
        }
      });
    }
  }

  Future<bool> _onPost(String message, BuildContext context) async {
    if (loading != null) {
      loading!(true);
    } else {
      loadingModal.value = true;
    }
    List<String>? docs;
    if (images != null && images!.value.isNotEmpty) {
      docs = [];
      for (Json image in images!.value) {
        docs.add(image.id!);
      }
    }
    String? deducted;
    if (parent == null && route != null) {
      Json? rez = await Api.get(route!, lng: Language.of(context).lng);
      if (rez != null) {
        deducted = "Pages/${rez.id}";
      }
    }

    Json? rez = await Api.post(
        "/threads",
        Json({
          'action': 'post',
          'id': post?.id,
          if ((parent ?? deducted) != null) 'parent': parent ?? deducted,
          'text': message,
          if (editActions.contains(ModeTextEdit.title)) 'title': titleController.value.text,
          if (docs != null) "docs": docs,
          'lng': context.mounted ? Language.of(context).lng : 'fr',
          'sysid': UsersStore.user == null ? await Users.sysId() : null
        }));

    if (loading != null) {
      loading!(false);
    } else {
      loadingModal.value = false;
    }

    if (rez?['errors'] != null && context.mounted) {
      AppLocalizations locale = Language.of(context);
      List<String> message = [];
      for (Json error in rez?['errors']) {
        message.add(error['element'] + ": " + FormUtils.translate(error['message'], locale));
      }
      Messager.toast(context, message.join(", "));
      return false;
    }
    if (after != null) {
      after!(rez?['post'] ?? rez);
    }

    return (rez?.id ?? rez?['post']?['id']) != null;
  }

  void aiReply(BuildContext context) {
    if (textController.text.isNotEmpty) {
      AIUtils.rewrite(textController.text, 100, 500).then((value) => textController.text = value);
    } else {
      Api.get(RouteSettingsSaver.routeSettings(context)!.name!).then(
        (thread) => AIUtils.replyThread(thread!.id!).then((value) => textController.text = value),
      );
    }
    textController.text = "...";
  }

  void aiRewrite(BuildContext context) {
    AIUtils.rewrite(textController.value.text, 100, 500).then((value) => textController.text = value);
    textController.text = "...";
  }

  void aiRewriteQuestion(BuildContext context) {
    BaseRoute? route = BaseRoute.maybeOf(context);
    if (route == null) {
      return;
    }
    Api.get(RouteSettingsSaver.routeSettings(context)!.name!).then((post) {
      route.dialogModal.setModal(QuestionsSuggest(
        post: post!,
        selected: (Json question) {
          titleController.text = question['title'];
          textController.text = question['text'];
          route.dialogModal.setModal(null);
        },
      ));
    });
  }
}

enum ModeTextEdit { question, rewrite, title }
