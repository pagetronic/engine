import 'package:engine/api/api.dart';
import 'package:engine/utils/base.dart';
import 'package:flutter/material.dart';

class PagesEdit extends StatefulWidget {
  final Json? page;

  const PagesEdit({super.key, this.page});

  @override
  State<StatefulWidget> createState() => PagesEditState();
}

class PagesEditState extends BaseRoute<PagesEdit> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget getBody() {
    space() => const SizedBox(height: 20);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      children: [
        TextField(
          controller: TextEditingController()..text = widget.page?['title'] ?? "",
          onSubmitted: (_) {},
          minLines: 1,
          maxLines: 1,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "title",
          ),
        ),
        space(),
        TextField(
          controller: TextEditingController()..text = widget.page?['text'] ?? "",
          onSubmitted: (_) {},
          minLines: 1,
          maxLines: 1000000,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "text",
          ),
        ),
      ],
    );
  }

  @override
  String? getTitle() {
    return "Page edit";
  }
}
