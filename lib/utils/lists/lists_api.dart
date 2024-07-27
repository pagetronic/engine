import 'dart:math';

import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/fx.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/ux.dart';
import 'package:flutter/material.dart';

class ApiListView extends StatefulWidget {
  final ValueStore<Result?> result = ValueStore(null);
  final GlobalKey<AnimatedListState> listKey = GlobalKey(debugLabel: "apiList");

  final ScrollController? controller;
  final Axis scrollDirection;
  final EdgeInsets? padding;
  final Widget Function(BuildContext context, Json item, int index) getView;
  final Widget? header;
  final Widget? footer;
  final Future<Result?> Function(String? paging) request;
  final ValueStore<double> lastIndex = ValueStore<double>(0);
  final bool oddEven;
  final LoadingDirection direction;
  final int? sticky;
  final ScrollPhysics? physics;
  final bool noRefresh;
  final bool? primary;
  final bool noEmpty;
  final bool shrinkWrap;
  final bool insertToBottom;

  ApiListView({
    super.key,
    required this.request,
    this.scrollDirection = Axis.vertical,
    this.padding,
    required this.getView,
    this.header,
    this.footer,
    this.sticky,
    this.controller,
    this.oddEven = true,
    this.direction = LoadingDirection.toBottom,
    Result? initial,
    this.noRefresh = false,
    this.physics,
    this.primary,
    this.noEmpty = false,
    this.shrinkWrap = false,
    this.insertToBottom = false,
  }) {
    result.value = initial;
  }

  @override
  ApiListViewState createState() => ApiListViewState();

  void update(Json item) {
    for (int index = 0; index < result.value!.result.length; index++) {
      if (item.id == result.value!.result[index].id) {
        int goodIndex = direction == LoadingDirection.toBottom
            ? (header != null ? 1 : 0) + (result.value!.paging != null ? 1 : 0) + index
            : (header != null ? 1 : 0) +
                (result.value!.paging != null ? 1 : 0) +
                (footer != null ? 1 : 0) +
                result.value!.result.length -
                1 -
                index;

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
    if (!insertToBottom && direction == LoadingDirection.toBottom) {
      result.value!.result.insert(0, item);
      listKey.currentState?.insertItem((header != null ? 1 : 0), duration: Duration.zero);
    } else {
      result.value!.result.add(item);
      listKey.currentState?.insertItem(result.value!.result.length + (header != null ? 1 : 0), duration: Duration.zero);
    }
  }

  void remove(String? id) {
    int goodIndex = -1;
    for (int index = 0; index < result.value!.result.length; index++) {
      if (id == result.value!.result[index].id) {
        goodIndex = index;
        break;
      }
    }
    int realIndex = direction == LoadingDirection.toBottom
        ? goodIndex + (header != null ? 1 : 0)
        : result.value!.result.length - goodIndex - (footer != null ? 1 : 0);

    result.value!.result.removeAt(goodIndex);

    listKey.currentState?.removeItem(realIndex, (context, animation) {
      return const SizedBox.shrink();
    }, duration: Duration.zero);
  }
}

class ApiListViewState extends State<ApiListView> {
  bool loading = false;
  final GlobalKey headerKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();
  ScrollController? controller;

  double headerHeight = 0;
  double footerHeight = 0;
  double listHeight = 0;
  double offsetHeader = 0;
  double offsetFooter = 0;
  bool sticky = false;

  @override
  Widget build(BuildContext context) {
    Widget list = Material(
        child: AnimatedList(
            key: widget.listKey,
            shrinkWrap: widget.shrinkWrap,
            controller: controller,
            primary: widget.primary,
            physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
            scrollDirection: widget.scrollDirection,
            reverse: widget.direction == LoadingDirection.toTop,
            padding: widget.padding ?? const EdgeInsets.all(0),
            initialItemCount: itemCount(),
            itemBuilder: itemBuilder));

    makeSticky();
    list = widget.noRefresh
        ? list
        : RefreshIndicator(
            color: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            onRefresh: reload,
            child: list,
          );
    if (widget.sticky == null) {
      return list;
    }
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          left: 0,
          child: widget.noRefresh
              ? list
              : RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  onRefresh: reload,
                  child: list,
                ),
        ),
        if (sticky && widget.header != null)
          AnimatedPositioned(
              top: offsetHeader,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                  key: headerKey,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 3, offset: const Offset(0, -1.5))
                    ],
                  ),
                  child: widget.header!)),
        if (sticky && widget.footer != null)
          AnimatedPositioned(
              bottom: offsetFooter,
              left: 0,
              right: 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                  key: footerKey,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 3, offset: const Offset(0, 2.8))
                    ],
                  ),
                  child: widget.footer!)),
      ],
    );
  }

  Widget itemBuilder(BuildContext context, int index, Animation<double> animation) {
    if (widget.direction == LoadingDirection.toBottom) {
      return itemBuilderToBottom(context, index, animation);
    }
    return itemBuilderToTop(context, index, animation);
  }

  Widget itemBuilderToBottom(BuildContext context, int index, Animation<double> animation) {
    if (widget.header != null && index == 0) {
      return sticky ? SizedBox(height: headerHeight) : widget.header!;
    }
    int realIndex = index - (widget.header != null ? 1 : 0);
    if (realIndex > (widget.result.value?.result.length ?? 0) - 5) {
      requestMore();
    }
    if (widget.footer != null &&
        realIndex ==
            (widget.result.value?.result.length ?? 0) +
                ((widget.result.value?.result.length ?? 0) > 0 && widget.result.value?.paging == null ? 0 : 1)) {
      return sticky ? SizedBox(height: footerHeight) : widget.footer!;
    }
    if (widget.result.value != null && realIndex < (widget.result.value?.result.length ?? 0)) {
      return FadeTransition(
        opacity: animation,
        child: Container(
            decoration: widget.oddEven ? StyleListView.getOddEvenBoxDecoration(index) : null,
            child: widget.getView(context, widget.result.value!.result[realIndex], realIndex)),
      );
    }
    if ((widget.result.value?.result.length ?? 0) > 0 && widget.result.value?.paging == null) {
      return const SizedBox.shrink();
    }

    if (widget.result.value != null && widget.result.value!.result.isEmpty && widget.result.value!.paging == null) {
      return widget.noEmpty ? const SizedBox.shrink() : Ux.emptyList(context, Language.of(context).empty_result);
    }

    requestMore();
    return Ux.loading(context, delay: Duration.zero);
  }

  Widget itemBuilderToTop(BuildContext context, int index, Animation<double> animation) {
    if (index == 0 && widget.footer != null) {
      return sticky ? SizedBox(height: footerHeight) : widget.footer!;
    }

    if (widget.header != null && index == itemCount() - 1) {
      return sticky ? SizedBox(height: headerHeight) : widget.header!;
    }

    int realIndex = (widget.result.value?.result.length ?? 0) +
        (widget.header != null ? 1 : 0) +
        (widget.result.value?.paging == null ? 0 : 1) -
        1 -
        index;

    if (realIndex < 5) {
      requestMore();
    }
    if (widget.result.value == null ||
        (widget.result.value?.paging != null &&
            ((widget.header == null && realIndex == -1) || (widget.header != null && realIndex == 0)))) {
      requestMore();
      return Ux.loading(context, delay: Duration.zero);
    }
    if (widget.result.value != null && widget.result.value!.result.isEmpty && widget.result.value!.paging == null) {
      return widget.noEmpty ? const SizedBox.shrink() : Ux.emptyList(context, Language.of(context).empty_result);
    }
    if (realIndex < 0 || realIndex >= widget.result.value!.result.length) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
        opacity: animation,
        child: Container(
          decoration: widget.oddEven ? StyleListView.getOddEvenBoxDecoration(index) : null,
          child: widget.getView(context, widget.result.value!.result[realIndex], index),
        ));
  }

  void requestMore() async {
    if (!mounted || loading || (widget.result.value != null && widget.result.value?.paging == null)) {
      return;
    }
    loading = true;

    int loadingIndex = widget.direction == LoadingDirection.toBottom
        ? (widget.result.value?.result.length ?? 0) + (widget.header != null ? 1 : 0)
        : (widget.footer != null ? 1 : 0);

    Result? result = await widget.request(widget.result.value?.paging);

    widget.result.value ??= Result();

    if (result != null) {
      if (widget.direction == LoadingDirection.toTop) {
        widget.result.value?.prev = result.prev;
      } else {
        widget.result.value?.next = result.next;
      }
    }
    if (result?.paging == null) {
      widget.listKey.currentState?.removeItem(loadingIndex, duration: const Duration(milliseconds: 100),
          (context, animation) {
        return FadeTransition(opacity: animation, child: Ux.loading(context));
      });
      widget.result.value?.next = null;
      widget.result.value?.prev = null;
    }

    if (result != null) {
      List<Json> results = result.result;
      if (mounted) {
        int animeCount = results.length;
        if (widget.direction == LoadingDirection.toBottom) {
          int count = widget.result.value?.result.length ?? 0;
          for (Json res in results) {
            widget.result.value?.result.add(res);
            widget.listKey.currentState?.insertItem(count + (widget.header != null ? 1 : 0),
                duration: Duration(milliseconds: 30 * animeCount));
            animeCount--;
          }
        } else {
          int count = 0;
          for (Json res in results.reversed) {
            count++;
            widget.result.value?.result.insert(0, res);
            widget.listKey.currentState
                ?.insertItem((widget.footer != null ? 1 : 0), duration: Duration(milliseconds: 30 * count));
          }
        }
      }
      if (results.isEmpty &&
          widget.result.value != null &&
          widget.result.value!.result.isEmpty &&
          widget.result.value?.paging == null) {
        widget.listKey.currentState?.insertItem(0 + (widget.footer != null ? 1 : 0), duration: Duration.zero);
      }
    }
    loading = false;
    makeSticky();
  }

  void scrollChange() {
    makeSticky();
    if (!sticky) {
      return;
    }

    if (widget.direction == LoadingDirection.toBottom) {
      if (controller!.offset < widget.lastIndex.value) {
        setState(() {
          offsetHeader = 0;
          offsetFooter = -footerHeight - 5;
        });
      } else {
        setState(() {
          offsetHeader = -headerHeight - 5;
          offsetFooter = 0;
        });
      }
    } else {
      if (controller!.offset > widget.lastIndex.value) {
        setState(() {
          offsetHeader = 0;
          offsetFooter = -footerHeight - 5;
        });
      } else {
        setState(() {
          offsetHeader = -headerHeight - 5;
          offsetFooter = 0;
        });
      }
    }
    widget.lastIndex.value = controller!.offset;
  }

  @override
  void initState() {
    super.initState();
    controller = controller ?? widget.controller ?? ScrollController();
    controller!.addListener(scrollChange);
    makeSticky();
  }

  @override
  void dispose() {
    controller!.removeListener(scrollChange);
    super.dispose();
  }

  void makeSticky() {
    if (widget.header == null && widget.footer == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      headerHeight = headerKey.currentContext?.size?.height ?? headerHeight;
      footerHeight = footerKey.currentContext?.size?.height ?? footerHeight;
      listHeight = widget.listKey.currentContext?.size?.height ?? 0;
      bool sticky = widget.sticky == null ? false : widget.sticky! <= (widget.result.value?.result.length ?? 0);
      if (sticky && headerHeight > listHeight / 3) {
        sticky = false;
      }
      if (this.sticky != sticky && mounted) {
        setState(() {
          this.sticky = sticky;
        });
      }
    });
  }

  void remove(Json item) {
    int index = widget.result.value?.result.indexWhere((element) => element['id'] == element['id']) ?? -1;
    widget.result.value?.result.removeAt(index);
    if (index >= 0) {
      widget.listKey.currentState?.removeItem(index,
          (context, animation) => FadeTransition(opacity: animation, child: widget.getView(context, item, index)));
    }
  }

  Future<void> reload() async {
    widget.result.value = null;
    widget.listKey.currentState
        ?.removeAllItems((context, animation) => const SizedBox.shrink(), duration: Duration.zero);
    widget.listKey.currentState?.insertAllItems(
        0, 1 + (widget.header != null ? 1 : 0) + (widget.footer != null ? 1 : 0),
        duration: Duration.zero);
  }

  int itemCount() {
    return (widget.header != null ? 1 : 0) +
        (widget.footer != null ? 1 : 0) +
        max(
            1,
            (widget.result.value == null || widget.result.value!.paging != null ? 1 : 0) +
                (widget.result.value?.result.length ?? 0));
  }
}
