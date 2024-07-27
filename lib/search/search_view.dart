import 'package:engine/api/utils/html.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/lng/base_localizations.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/defer.dart';
import 'package:engine/utils/platform/folds.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:flutter/material.dart';

mixin SearchViewer<T extends StatefulWidget> on BaseRoute<T> {
  final TextEditingController controller = TextEditingController();
  final Deferrer deferrer = Deferrer(700);

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    NavigatorState nav = Navigator.of(context);
    if (!nav.canPop()) {
      nav.pushReplacementNamed("/");
      nav.pushNamed("/search");
    }
    await super.beforeLoad(locale);
  }

  @override
  Widget getFold() => SearchFold(body: getBody(), controller: controller);

  void onSearch(String search);

  void makeSearch() => deferrer.defer(() => onSearch(controller.value.text));

  @override
  void initState() {
    super.initState();
    controller.addListener(makeSearch);
  }

  @override
  void dispose() {
    controller.removeListener(makeSearch);
    super.dispose();
  }
}

class SearchItem extends StatelessWidget {
  final Json item;

  const SearchItem(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    if (item['url'] == null || (item['title'] == null && item['intro'] == null)) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item['url'], arguments: PageRouteInfo(PageRouteType.slide, item)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['title'] != null)
              Text(HtmlEscaper.unescape(item['title'] ?? "no title"),
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                    decoration: TextDecoration.underline,
                  )),
            if (item['intro'] != null) Text(HtmlEscaper.unescape(item['intro'])),
            if (item['breadcrumb'] != null) BreadcrumbEmbedded(BreadcrumbUtils.make(item['breadcrumb']))
          ],
        ),
      ),
    );
  }
}
