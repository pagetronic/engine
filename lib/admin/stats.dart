import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/error.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/platform/menu.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatefulWidget> createState() => PagesViewState();
}

class PagesViewState extends BaseRoute<StatsView> {
  Json? stats;

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    stats = await Api.get("/admin/stats");
    await super.beforeLoad(locale);
  }

  @override
  List<GlobalMenuItem> getBaseMenu([String? active]) {
    return [];
  }

  @override
  Widget getBody() {
    if (stats == null) {
      return const CaterpillarLoading();
    }
    if (stats?['stats'] == null || stats?['urls'] == null) {
      Navigator.pushNamed(context, "/profile");
      return const NotFoundView();
    }
    NumberFormat format = NumberFormat.decimalPattern(Language.of(context).lng);
    return Material(
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          const H3("Globales"),
          const H5("Aujourd'hui"),
          Text(
              "${format.format(stats!['stats']['TODAY']['unique'])} / ${format.format(stats!['stats']['TODAY']['view'])}"),
          const HR(),
          const H5("Hier"),
          Text(
              "${format.format(stats!['stats']['YESTERDAY']['unique'])} / ${format.format(stats!['stats']['YESTERDAY']['view'])}"),
          const HR(),
          const H5("Semaine passée"),
          Text(
              "${format.format(stats!['stats']['LAST_WEEK']['unique'])} / ${format.format(stats!['stats']['LAST_WEEK']['view'])}"),
          const HR(),
          const H5("Ce mois-ci"),
          Text(
              "${format.format(stats!['stats']['THIS_MONTH']['unique'])} / ${format.format(stats!['stats']['THIS_MONTH']['view'])}"),
          const HR(),
          const H5("Le mois dernier"),
          Text(
              "${format.format(stats!['stats']['LAST_MONTH']['unique'])} / ${format.format(stats!['stats']['LAST_MONTH']['view'])}"),
          const HR(height: 3),
          const H3("Meilleurs URLs"),
          const H5("Aujourd'hui"),
          for (Json url in stats!['urls']['TODAY'])
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      onTap: url['url'] != null
                          ? () =>
                              Navigator.of(context).pushNamed(url['url'], arguments: PageRouteInfo(PageRouteType.slide))
                          : null,
                      child: Text(
                        "${format.format(url['unique'])} / ${format.format(url['view'])} => "
                        "${(url['lng'] ?? '')}:${(url['url'] ?? '')}",
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const HR(),
          const H5("Ce mois-ci"),
          for (Json url in stats!['urls']['THIS_MONTH'])
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: InkWell(
                    onTap: url['url'] != null
                        ? () =>
                            Navigator.of(context).pushNamed(url['url'], arguments: PageRouteInfo(PageRouteType.slide))
                        : null,
                    child: Text(
                      "${format.format(url['unique'])} / ${format.format(url['view'])} => "
                      "${(url['lng'] ?? '')}:${(url['url'] ?? '')}",
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  String? getTitle() {
    return "Stats";
  }
}
