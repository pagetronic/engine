import 'dart:async';
import 'dart:math';

import 'package:engine/api/api.dart';
import 'package:engine/api/utils/range.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_filters.dart';
import 'package:engine/utils/ux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'package:engine/utils/lists/lists_view.dart';

abstract class ReorderListView extends StatefulWidget {
  final void Function()? onReload;
  final Widget? header;
  final Widget? footer;
  final bool withRange;
  final ValueStore<bool> filterCollapse = ValueStore(true);
  final ValueStore<DateTimeRangeNullable?> range = ValueStore(null);
  final GlobalKey footerKey = GlobalKey();
  final bool noRefresh;

  final ScrollPhysics? physics;

  late final Result data;

  final ScrollController controller = ScrollController(initialScrollOffset: 0.0);

  ReorderListView({
    super.key,
    this.header,
    this.footer,
    this.onReload,
    this.withRange = false,
    Result? initial,
    this.noRefresh = false,
    this.physics,
  }) {
    data = initial ?? Result();
  }

  Future<Result> getData(String? paging, DateTimeRangeNullable? range);

  void onReorder(List<String> order);

  Widget getView(BuildContext context, Json item, int index, int length);

  Widget loading(BuildContext context) {
    return Ux.loading(context);
  }

  @override
  ReorderListViewState createState() => ReorderListViewState();
}

class ReorderListViewState extends State<ReorderListView> {
  double footerHeight = 0;
  bool sticky = false;

  @override
  Widget build(BuildContext context) {
    makeSticky();
    ReorderableListView list = ReorderableListView.builder(
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      scrollController: widget.controller,
      onReorderStart: (int index) {
        HapticFeedback.heavyImpact();
      },
      buildDefaultDragHandles: false,
      header: widget.header,
      footer: widget.footer != null
          ? Container(key: widget.footerKey, child: sticky ? SizedBox(height: footerHeight) : widget.footer!)
          : null,
      itemCount: max(1, widget.data.result.length + (widget.data.next != null ? 1 : 0) /* + (isLoading ? 1 : 0)*/),
      itemBuilder: (context, index) {
        if (widget.data.result.isEmpty && widget.data.next == null && !isLoading) {
          return Ux.emptyList(context, Language.of(context).empty_result, key: const Key("empty"));
        }
        if (index >= widget.data.result.length) {
          load();
          return SizedBox(key: const Key("loading"), child: Ux.loading(context, delay: Duration.zero));
        }
        return widget.getView(context, widget.data.result[index], index, widget.data.result.length);
      },
      onReorder: (int oldIndex, int newIndex) {
        if (newIndex > widget.data.result.length) {
          return;
        }
        final Json item = widget.data.result.removeAt(oldIndex);
        widget.data.result.insert(newIndex + (oldIndex > newIndex ? 0 : -1), item);
        widget.onReorder(widget.data.result.map<String>((e) => e['id']).toList());
      },
    );
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: widget.filterCollapse.value ? 0 : 26),
          child: widget.noRefresh
              ? list
              : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  onRefresh: () async {
                    reload();
                  },
                  child: list,
                ),
        ),
        if (widget.withRange)
          DateListFilter(
            collapse: widget.filterCollapse.value,
            range: widget.range.value,
            onCollapse: (bool collapse) {
              setState(() {
                widget.filterCollapse.value = collapse;
              });
            },
            onChange: (DateTimeRangeNullable? newRange) {
              setState(() {
                widget.range.value = newRange;
              });
            },
          ),
        if (sticky && widget.footer != null)
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [
                    BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 3, offset: const Offset(0, 2.8))
                  ]),
                  child: widget.footer!)),
      ],
    );
  }

  void makeSticky() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients) {
        footerHeight = widget.footerKey.currentContext?.size?.height ?? footerHeight;
        bool sticky = widget.controller.position.maxScrollExtent > 0;
        if (this.sticky != sticky && mounted) {
          setState(() {
            this.sticky = sticky;
          });
        }
      }
    });
  }

  bool isLoading = false;

  Future<void> load() async {
    if (isLoading || widget.data.next == null) {
      return;
    }
    isLoading = true;
    Result nextData = await widget.getData(widget.data.next, widget.range.value);
    setState(() {
      widget.data.next = nextData.next;
      widget.data.result.addAll(nextData.result);
      isLoading = false;
    });
  }

  Future<void> reload() async {
    setState(() {
      widget.data.clear();
      isLoading = true;
    });
    Result nextData = await widget.getData(null, widget.range.value);
    setState(() {
      widget.data.next = nextData.next;
      widget.data.result.addAll(nextData.result);
      isLoading = false;
    });
  }
}
