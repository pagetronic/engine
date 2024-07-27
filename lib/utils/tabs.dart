import 'package:engine/data/settings.dart';
import 'package:engine/utils/platform/load.dart';
import 'package:engine/utils/widgets/order_tabbar.dart';
import 'package:flutter/material.dart';

typedef OnReorder = void Function(int oldIndex, int newIndex);

mixin TabStore<T extends StatefulWidget> {
  final List<TabStoreItem> tabs = [];
  OnReorder? onReorder;
  int reorderStartIndex = 0;
  int initialIndex = 0;

  String? orderKey;
  final List<String> order = [];

  Widget getView(int index) {
    return tabs[0].view;
  }

  Widget getTabBar(BuildContext context, {EdgeInsets? padding, List<BoxShadow>? boxShadow, BoxBorder? border}) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }
    boxShadow ??= [
      BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 3, offset: const Offset(0, -1)),
    ];

    return Container(
      height: kTabLabelPadding.vertical + kTextTabBarHeight,
      width: double.maxFinite,
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: boxShadow, border: border),
      child: SortableTabBar(
        sortable: orderKey != null,
        initialIndex: initialIndex >= tabs.length ? 0 : initialIndex,
        padding: padding,
        onTap: (value) {
          if (tabs[value].view is Function) {
            tabs[value].view.call();
            return false;
          }
          initialIndex = value;
          return true;
        },
        startDragIndex: reorderStartIndex,
        onReorder: orderKey != null
            ? (int oldIndex, int newIndex) {
                int globalOldIndex = oldIndex + reorderStartIndex;
                int globalNewIndex = newIndex + reorderStartIndex;

                TabStoreItem tab = tabs.removeAt(globalOldIndex);
                tabs.insert(globalNewIndex, tab);
                //initialIndex = globalNewIndex;
                if (onReorder != null) {
                  onReorder!(oldIndex, newIndex);
                }
                List<String> newOrder = tabs.map((e) => e.tag).toList();
                SettingsStore.set(orderKey!, newOrder).then((value) => reload());
              }
            : null,
        labelColor: Theme.of(context).textTheme.bodyMedium?.color,
        tabs: tabs.map((item) => BaseTab(title: item.title, icon: item.icon)).toList(),
        isScrollable: true,
      ),
    );
  }

  Widget getTabsController(Widget scaffold) {
    if (tabs.isEmpty) {
      return scaffold;
    }
    return DefaultTabController(
      initialIndex: initialIndex >= tabs.length ? 0 : initialIndex,
      length: tabs.length,
      child: scaffold,
    );
  }

  Widget getViews() {
    return TabBarView(
      physics: canTabSwipe() ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      children: tabs.map((e) {
        return e.view is Widget ? e.view as Widget : const SizedBox.expand();
      }).toList(),
    );
  }

  void addTab(dynamic view, {String? title, IconData? icon, Color? color, required String tag}) {
    tabs.add(TabStoreItem(title: title, view: view, icon: icon, color: color, tag: tag));
    if (order.isNotEmpty) {
      tabs.sort((a, b) {
        if (!order.contains(a.tag)) {
          return 10000;
        }
        if (!order.contains(b.tag)) {
          return -10000;
        }
        return order.indexOf(a.tag) - order.indexOf(b.tag);
      });
    }
  }

  void clearTabs() => tabs.clear();

  void activeTab(String tag) {
    initialIndex = 0;
    for (TabStoreItem tab in tabs) {
      if (tab.tag == tag) {
        break;
      }
      initialIndex++;
    }
  }

  Future<void> canOrderTabs(String orderKey) async {
    this.orderKey = orderKey;
    order.clear();
    List<dynamic>? order_ = await SettingsStore.get(orderKey);
    if (order_ != null && order_.isNotEmpty) {
      for (String element in order_) {
        order.add(element);
      }
    }
  }

  get length => tabs.length;

  void reload();

  bool canTabSwipe();
}

class TabStoreItem {
  final String? title;
  final IconData? icon;
  final Color? color;
  final dynamic view;
  final String tag;

  TabStoreItem({this.title, this.icon, this.color, required this.view, required this.tag});
}
