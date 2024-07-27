import 'package:engine/admin/ai/ai.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/ux.dart';
import 'package:flutter/material.dart';

class QuestionsSuggest extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey = GlobalKey(debugLabel: "iaList");
  final List<Json> questions = [];
  final ValueStore loading = ValueStore(false);
  final Json post;
  final void Function(Json question) selected;

  QuestionsSuggest({super.key, required this.post, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 300),
        child: AnimatedList(
          padding: const EdgeInsets.all(0),
          key: listKey,
          initialItemCount: questions.length + 1,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            if (index >= questions.length) {
              request();
              return Ux.loading(context, delay: Duration.zero);
            }
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: StyleListView.getOddEvenBoxDecoration(index),
              child: InkWell(
                onTap: () => selected(questions[index]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    H5(questions[index]['title']),
                    Text(questions[index]['text']),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> request() async {
    if (!loading.value) {
      loading.value = true;
      List<Json> questions = await AIUtils.question(post, this.questions);
      if (questions.isEmpty) {
        listKey.currentState?.removeItem(questions.length, duration: const Duration(milliseconds: 0),
            (context, animation) {
          return FadeTransition(opacity: animation, child: Ux.loading(context));
        });
        return;
      }
      for (Json question in questions) {
        this.questions.add(question);
        listKey.currentState?.insertItem(this.questions.length - 1);
      }
      loading.value = false;
    }
  }
}
