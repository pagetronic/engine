import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/defer.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/text.dart';
import 'package:flutter/material.dart';

class PageSearcher extends StatelessWidget {
  final void Function(Json? page) onSelect;
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<String> search = ValueNotifier("");
  final Deferrer deferrer = Deferrer(700);

  PageSearcher({super.key, required this.onSelect, String? initial}) {
    controller.text = initial ?? "";
    search.value = initial ?? "";

    controller.addListener(() {
      deferrer.defer(() {
        search.value = controller.value.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    TextField inputSearch = TextField(
      maxLines: 1,
      controller: controller,
      decoration: InputDecoration(
          hintText: Language.of(context).search,
          contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10)),
    );
    return ValueListenableBuilder(
      valueListenable: search,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
          child: ApiListView(
            header: inputSearch,
            request: (paging) async {
              Json? result = await Api.get("/search?q=${controller.value.text}&type=pages", paging: paging);
              return Result(result);
            },
            getView: (context, item, index) {
              return InkWell(
                  onTap: () => onSelect(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: H5(item['title']),
                  ));
            },
          ),
        );
      },
    );
  }
}
