import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/threads/widgets/posts_inputs.dart';
import 'package:engine/threads/widgets/posts_views.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:flutter/material.dart';

class ThreadsView extends StatefulWidget {
  final Json? page;
  final String? url;
  final String? inputHint;
  final TextEditingController textController = TextEditingController();
  final ValueNotifier<List<Json>> images = ValueNotifier([]);
  final void Function(bool load) loading;

  ThreadsView(this.loading, {super.key, this.inputHint, this.page, this.url});

  @override
  ThreadsViewState createState() => ThreadsViewState();
}

class ThreadsViewState extends State<ThreadsView> {
  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    ApiListView? list;
    list = ApiListView(
        header: widget.inputHint != null
            ? PostsTextInput(
                loading: widget.loading,
                images: widget.images,
                parent: widget.page?.id != null ? "Pages/${widget.page?.id}" : null,
                hintText: widget.inputHint,
                after: (Json post) {
                  if (post['url'] != null && context.mounted) {
                    Navigator.pushNamed(context, post['url'], arguments: post).then(
                      (value) => list?.update(post),
                    );
                    list?.update(post);
                  }
                },
                controller: widget.textController,
              )
            : null,
        request: (paging) async {
          Json? result =
              await Api.get(widget.url ?? widget.page?['url'] ?? '/threads', paging: paging, lng: locale.lng);
          return Result(result?['threads'] ?? result?['posts'] ?? result);
        },
        getView: (context, item, index) {
          return PostsViewItem(
            clickable: true,
            breadcrumb: true,
            editActions: [
              if (Users.isAdmin) ...[ModeTextEdit.question, ModeTextEdit.rewrite],
              ModeTextEdit.title
            ],
            item,
            onUpdate: (Json item) {
              if (item.id != null) {
                list?.update(item);
              } else {
                Fx.log("Post error : ${item.encode()}");
              }
            },
          );
        });
    return list;
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }
}
