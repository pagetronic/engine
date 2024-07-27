import 'package:engine/api/api.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/ux.dart';
import 'package:flutter/material.dart';

class ApiGridView extends StatefulWidget {
  final ValueStore<Result?> result = ValueStore(null);
  final GlobalKey<AnimatedGridState> listKey = GlobalKey<AnimatedGridState>();

  final ScrollController? controller;
  final Axis scrollDirection;
  final EdgeInsets? padding;
  final Widget Function(BuildContext context, Json item, int index) itemBuilder;
  final Widget? header;
  final Widget? footer;
  final Future<Result?> Function(String? paging) request;
  final ValueStore<double> lastIndex = ValueStore<double>(0);
  final bool oddEven;
  final ScrollPhysics? physics;
  final bool noRefresh;
  final bool? primary;
  final ValueStore<bool> loading = ValueStore(false);
  final GlobalKey headerKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();
  final double spacing;
  final double childAspectRatio;

  final int maxWidth;

  ApiGridView({
    super.key,
    required this.request,
    this.scrollDirection = Axis.vertical,
    this.padding,
    required this.itemBuilder,
    this.header,
    this.footer,
    this.controller,
    this.oddEven = true,
    Result? initial,
    this.noRefresh = false,
    this.physics,
    this.primary,
    this.spacing = 0,
    this.childAspectRatio = 36 / 24,
    required this.maxWidth,
  }) {
    result.value = initial;
  }

  @override
  ApiGridViewState createState() => ApiGridViewState();

  void insert(Json item) {
    result.value!.result.insert(0, item);
    listKey.currentState?.insertItem((header != null ? 1 : 0), duration: const Duration(milliseconds: 500));
  }

  void update(Json item) {
    for (int index = 0; index < result.value!.result.length; index++) {
      if (item.id == result.value!.result[index].id) {
        int goodIndex = (header != null ? 1 : 0) + (result.value!.paging != null ? 1 : 0) + index;

        Json itemBefore = result.value!.result.removeAt(index);
        listKey.currentState?.removeItem(goodIndex, (context, animation) {
          return const SizedBox.shrink();
        }, duration: Duration.zero);

        itemBefore.addAll(item);
        result.value!.result.insert(index, itemBefore);
        listKey.currentState?.insertItem(goodIndex, duration: Duration.zero);
        return;
      }
    }
    result.value!.result.add(item);
    listKey.currentState?.insertItem(result.value!.result.length + (header != null ? 1 : 0), duration: Duration.zero);
  }

  void remove(Json item) {
    int? index = result.value?.result.indexOf(item);
    if (index != null && index >= 0) {
      result.value?.result.removeAt(index);
      listKey.currentState?.removeItem(
        index + (header != null ? 1 : 0),
        (context, animation) => const Loading(),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> reload() async {
    result.value = null;
    listKey.currentState?.removeAllItems((context, animation) => const SizedBox.shrink(), duration: Duration.zero);
    listKey.currentState
        ?.insertAllItems(0, 1 + (header != null ? 1 : 0) + (footer != null ? 1 : 0), duration: Duration.zero);
  }
}

class ApiGridViewState extends State<ApiGridView> with WidgetsBindingObserver {
  int columns = 1;

  @override
  Widget build(BuildContext context) {
    didChangeMetrics();
    AnimatedGrid list = AnimatedGrid(
      key: widget.listKey,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      initialItemCount: (widget.header != null ? 1 : 0) +
          (widget.footer != null ? 1 : 0) +
          (widget.result.value == null || widget.result.value?.paging != null ? 1 : 0) +
          (widget.result.value?.result.length ?? 0),
      itemBuilder: _itemBuilder,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: widget.spacing,
        crossAxisSpacing: widget.spacing,
        childAspectRatio: widget.childAspectRatio,
      ),
    );
    return widget.noRefresh
        ? list
        : RefreshIndicator(
            color: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            onRefresh: widget.reload,
            child: list,
          );
  }

  Widget _itemBuilder(BuildContext context, int index, Animation<double> animation) {
    int realIndex = index - (widget.header != null ? 1 : 0);
    if (widget.header != null && index == 0) {
      return widget.header!;
    }

    if (widget.footer != null &&
        realIndex == (widget.result.value?.result.length ?? 0) + (widget.header != null ? 1 : 0)) {
      return widget.footer!;
    }
    if (widget.result.value != null && realIndex < (widget.result.value?.result.length ?? 0)) {
      return FadeTransition(
        opacity: animation,
        child: Container(
            decoration: widget.oddEven ? StyleListView.getOddEvenBoxDecoration(index) : null,
            child: widget.itemBuilder(context, widget.result.value!.result[realIndex], realIndex)),
      );
    }
    if ((widget.result.value?.result.length ?? 0) > 0 && widget.result.value?.paging == null) {
      return const SizedBox.shrink();
    }
    requestMore();
    return Ux.loading(context, delay: Duration.zero);
  }

  void requestMore() async {
    if (widget.loading.value || (widget.result.value != null && widget.result.value?.paging == null)) {
      return;
    }
    widget.loading.value = true;

    int loadingIndex = (widget.result.value?.result.length ?? 0) + (widget.header != null ? 1 : 0);

    await Future.delayed(const Duration(milliseconds: 300));
    Result? result = await widget.request(widget.result.value?.paging);

    widget.result.value ??= Result();

    if (result != null) {
      widget.result.value!.next = result.next;
    }
    if (result == null || widget.result.value?.paging == null) {
      widget.listKey.currentState?.removeItem(loadingIndex, duration: const Duration(milliseconds: 0),
          (context, animation) {
        return FadeTransition(opacity: animation, child: Ux.loading(context));
      });
      widget.result.value!.next = null;
      widget.result.value!.prev = null;
    }

    if (result != null) {
      List<Json> results = result.result;
      int animeCount = results.length;
      int count = widget.result.value!.result.length;
      for (Json res in results) {
        widget.result.value!.result.add(res);
        widget.listKey.currentState
            ?.insertItem(count + (widget.header != null ? 1 : 0), duration: Duration(milliseconds: 30 * animeCount));
        animeCount--;
      }
    }
    widget.loading.value = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    double columns = MediaQuery.of(context).size.width / widget.maxWidth;
    setState(() {
      this.columns = columns.ceil();
    });
  }
}
