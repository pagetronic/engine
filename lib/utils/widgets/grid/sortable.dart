import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class DragWidgetBuilder {
  final bool isScreenshotDragWidget;

  final Widget Function(int index, Widget child, ImageProvider? screenshot) builder;

  DragWidgetBuilder({this.isScreenshotDragWidget = false, required this.builder});
}

typedef ScrollSpeedController = double Function(int timeInMilliSecond, double overSize, double itemSize);

typedef PlaceholderBuilder = Widget Function(int dropIndex, int dropInddex, Widget dragWidget);

typedef OnDragStart = void Function(int dragIndex);

typedef OnDragUpdate = void Function(int dragIndex, Offset position, Offset delta);

class SortableGridView extends StatelessWidget {
  final ReorderCallback onReorder;
  final DragWidgetBuilder? dragWidgetBuilder;
  final ScrollSpeedController? scrollSpeedController;
  final PlaceholderBuilder? placeholderBuilder;
  final OnDragStart? onDragStart;
  final OnDragUpdate? onDragUpdate;

  final bool? primary;
  final bool shrinkWrap;
  final bool restrictDragScope;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool reverse;
  final double? cacheExtent;
  final int? semanticChildCount;

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;
  final String? restorationId;

  final SliverChildDelegate childrenDelegate;

  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final DragStartBehavior dragStartBehavior;

  final Duration? dragStartDelay;
  final bool? dragEnabled;

  final double? elevation;

  final BorderRadius? borderRadius;

  SortableGridView.builder({
    Key? key,
    required ReorderCallback onReorder,
    ScrollSpeedController? scrollSpeedController,
    DragWidgetBuilder? dragWidgetBuilder,
    PlaceholderBuilder? placeholderBuilder,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required SliverGridDelegate gridDelegate,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Duration? dragStartDelay,
    bool? dragEnabled,
    bool restrictDragScope = false,
    double? elevation,
    BorderRadius? borderRadius,
  }) : this(
          key: key,
          onReorder: onReorder,
          dragWidgetBuilder: dragWidgetBuilder,
          scrollSpeedController: scrollSpeedController,
          placeholderBuilder: placeholderBuilder,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          childrenDelegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              Widget child = itemBuilder(context, index);
              assert(() {
                if (child.key == null) {
                  throw FlutterError(
                    'Every item of SortableGridView must have a key.',
                  );
                }
                return true;
              }());
              return SortableItemView(
                key: child.key!,
                index: index,
                child: child,
              );
            },
            childCount: itemCount,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
          gridDelegate: gridDelegate,
          reverse: reverse,
          controller: controller,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount ?? itemCount,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          dragStartDelay: dragStartDelay,
          dragEnabled: dragEnabled,
          restrictDragScope: restrictDragScope,
          elevation: elevation,
          borderRadius: borderRadius,
        );

  factory SortableGridView.count({
    Key? key,
    required ReorderCallback onReorder,
    DragWidgetBuilder? dragWidgetBuilder,
    ScrollSpeedController? scrollSpeedController,
    PlaceholderBuilder? placeholderBuilder,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    List<Widget>? footer,
    List<Widget>? header,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    double? mainAxisExtent,
    bool reverse = false,
    ScrollController? controller,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
    required int crossAxisCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
    Duration? dragStartDelay,
    bool? dragEnabled,
    restrictDragScope = false,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    assert(
      children.every((Widget w) => w.key != null),
      'All children of this widget must have a key.',
    );
    return SortableGridView(
      key: key,
      onReorder: onReorder,
      dragWidgetBuilder: dragWidgetBuilder,
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      childrenDelegate: SliverChildListDelegate(
        SortableItemView.wrapMeList(header, children, footer),
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        addRepaintBoundaries: addRepaintBoundaries,
        addSemanticIndexes: addSemanticIndexes,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount ?? children.length,
      dragStartBehavior: dragStartBehavior,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      dragEnabled: dragEnabled,
      dragStartDelay: dragStartDelay,
      restrictDragScope: restrictDragScope,
      elevation: elevation,
      borderRadius: borderRadius,
    );
  }

  const SortableGridView({
    super.key,
    required this.onReorder,
    this.dragWidgetBuilder,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.onDragStart,
    this.onDragUpdate,
    required this.gridDelegate,
    required this.childrenDelegate,
    this.restrictDragScope = false,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent,
    this.semanticChildCount,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.controller,
    this.dragStartBehavior = DragStartBehavior.start,
    this.dragStartDelay,
    this.dragEnabled,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SortableWrapperWidget(
      onReorder: onReorder,
      dragWidgetBuilder: dragWidgetBuilder,
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      dragEnabled: dragEnabled,
      dragStartDelay: dragStartDelay,
      restrictDragScope: restrictDragScope,
      elevation: elevation,
      borderRadius: borderRadius,
      child: GridView.custom(
        key: key,
        gridDelegate: gridDelegate,
        childrenDelegate: childrenDelegate,
        controller: controller,
        reverse: reverse,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        padding: padding,
        cacheExtent: cacheExtent,
        semanticChildCount: semanticChildCount,
        keyboardDismissBehavior: keyboardDismissBehavior,
        restorationId: restorationId,
        clipBehavior: clipBehavior,
        dragStartBehavior: dragStartBehavior,
      ),
    );
  }
}

class SortableWrapperWidget extends StatefulWidget with SortableGridWidgetMixin {
  @override
  final ReorderCallback onReorder;

  @override
  final DragWidgetBuilder? dragWidgetBuilder;

  @override
  final ScrollSpeedController? scrollSpeedController;

  @override
  final PlaceholderBuilder? placeholderBuilder;

  final SortableChildPosDelegate? posDelegate;

  @override
  final OnDragStart? onDragStart;

  @override
  final OnDragUpdate? onDragUpdate;

  @override
  final Widget child;

  @override
  final bool? dragEnabled;

  @override
  final Duration? dragStartDelay;

  @override
  final bool? isSliver;

  @override
  final bool restrictDragScope;

  @override
  final BorderRadius? borderRadius;
  @override
  final double? elevation;

  const SortableWrapperWidget({
    super.key,
    required this.child,
    required this.onReorder,
    this.restrictDragScope = false,
    this.dragWidgetBuilder,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.posDelegate,
    this.onDragStart,
    this.onDragUpdate,
    this.dragEnabled,
    this.dragStartDelay,
    this.isSliver,
    this.borderRadius,
    this.elevation,
  });

  @override
  SortableWrapperWidgetState createState() {
    return SortableWrapperWidgetState();
  }
}

class SortableSliverGridView extends StatelessWidget {
  final List<Widget> children;
  final List<Widget>? header;
  final List<Widget>? footer;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  final ReorderCallback onReorder;
  final DragWidgetBuilder? dragWidgetBuilder;
  final ScrollSpeedController? scrollSpeedController;
  final PlaceholderBuilder? placeholderBuilder;
  final OnDragStart? onDragStart;
  final OnDragUpdate? onDragUpdate;
  final Duration dragStartDelay;
  final bool dragEnabled;
  final BorderRadius? borderRadius;
  final double? elevation;

  const SortableSliverGridView({
    super.key,
    this.children = const <Widget>[],
    required this.crossAxisCount,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.childAspectRatio,
    required this.onReorder,
    this.dragWidgetBuilder,
    this.header,
    this.footer,
    this.dragStartDelay = kLongPressTimeout,
    this.scrollSpeedController,
    this.placeholderBuilder,
    this.onDragStart,
    this.onDragUpdate,
    this.dragEnabled = true,
    this.borderRadius,
    this.elevation,
  });

  const SortableSliverGridView.count({
    Key? key,
    required int crossAxisCount,
    required ReorderCallback onReorder,
    DragWidgetBuilder? dragWidgetBuilder,
    List<Widget>? footer,
    List<Widget>? header,
    OnDragStart? onDragStart,
    OnDragUpdate? onDragUpdate,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    Duration dragStartDelay = kLongPressTimeout,
    children = const <Widget>[],
    bool dragEnabled = true,
  }) : this(
          key: key,
          onReorder: onReorder,
          children: children,
          footer: footer,
          header: header,
          crossAxisCount: crossAxisCount,
          dragWidgetBuilder: dragWidgetBuilder,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          onDragStart: onDragStart,
          onDragUpdate: onDragUpdate,
          dragStartDelay: dragStartDelay,
          dragEnabled: dragEnabled,
        );

  @override
  Widget build(BuildContext context) {
    var child = SliverGridWithSortablePosDelegate.count(
        key: key,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
        children: SortableItemView.wrapMeList(header, children, footer));

    return SortableWrapperWidget(
      onReorder: onReorder,
      dragWidgetBuilder: dragWidgetBuilder,
      scrollSpeedController: scrollSpeedController,
      placeholderBuilder: placeholderBuilder,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      isSliver: true,
      elevation: elevation,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

class SliverGridWithSortablePosDelegate extends SliverGrid {
  const SliverGridWithSortablePosDelegate({
    super.key,
    required super.delegate,
    required super.gridDelegate,
  });

  SliverGridWithSortablePosDelegate.count({
    Key? key,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  }) : this(
            key: key,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
            ),
            delegate: SliverChildListDelegate(children));
}

class SortableWrapperWidgetState extends State<SortableWrapperWidget>
    with TickerProviderStateMixin<SortableWrapperWidget>, SortableGridStateMixin {
  SortableWrapperWidgetState();
}

class SortableItemView extends StatefulWidget {
  const SortableItemView({
    required Key key,
    required this.child,
    required this.index,
    this.indexInAll,
  }) : super(key: key);

  final Widget child;
  final int index;

  final int? indexInAll;

  static List<Widget> wrapMeList(
    List<Widget>? header,
    List<Widget> children,
    List<Widget>? footer,
  ) {
    var rst = <Widget>[];
    rst.addAll(header ?? []);
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      assert(() {
        if (child.key == null) {
          throw FlutterError(
            'Every item of SortableGridView must have a key.',
          );
        }
        return true;
      }());
      rst.add(SortableItemView(
        key: child.key!,
        index: i,
        indexInAll: i + (header?.length ?? 0),
        child: child,
      ));
    }

    rst.addAll(footer ?? []);
    return rst;
  }

  @override
  State<SortableItemView> createState() => SortableItemViewState();
}

class SortableItemViewState extends State<SortableItemView> with TickerProviderStateMixin {
  late SortableGridStateMixin _listState;
  bool _dragging = false;

  Offset _startOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  AnimationController? _offsetAnimation;
  Offset _placeholderOffset = Offset.zero;

  Key get key => widget.key!;

  Widget get child => widget.child;

  int get index => widget.index;

  int? get indexInAll => widget.indexInAll;

  final Key childKey = GlobalKey();

  set dragging(bool dragging) {
    if (mounted) {
      setState(() {
        _dragging = dragging;
      });
    }
  }

  Offset getRelativePos(Offset dragPosition) {
    final parentRenderBox = _listState.context.findRenderObject() as RenderBox;
    final parentOffset = parentRenderBox.localToGlobal(dragPosition);

    final renderBox = context.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(parentOffset);
  }

  RenderBox get parentRenderBox {
    return _listState.context.findRenderObject() as RenderBox;
  }

  void updateForGap(int dropIndex) {
    if (!mounted) return;

    if (!_listState.containsByIndex(index)) {
      return;
    }

    _checkPlaceHolder();

    if (_dragging) {
      return;
    }

    Offset newOffset = _listState.getOffsetInDrag(index);
    if (newOffset != _targetOffset) {
      _targetOffset = newOffset;

      if (_offsetAnimation == null) {
        _offsetAnimation = AnimationController(vsync: _listState)
          ..duration = const Duration(milliseconds: 250)
          ..addListener(rebuild)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _startOffset = _targetOffset;
              _offsetAnimation?.dispose();
              _offsetAnimation = null;
            }
          })
          ..forward(from: 0.0);
      } else {
        _startOffset = offset;
        _offsetAnimation?.forward(from: 0.0);
      }
    }
  }

  void _checkPlaceHolder() {
    if (!_dragging) {
      return;
    }

    final selfPos = index;
    final targetPos = _listState.dropIndex;
    if (targetPos < 0) {
      return;
    }

    if (selfPos == targetPos) {
      setState(() {
        _placeholderOffset = Offset.zero;
      });
    }

    if (selfPos != targetPos) {
      setState(() {
        _placeholderOffset = _listState.getPosByIndex(targetPos) - _listState.getPosByIndex(selfPos);
      });
    }
  }

  void resetGap() {
    setState(() {
      if (_offsetAnimation != null) {
        _offsetAnimation!.dispose();
        _offsetAnimation = null;
      }

      _startOffset = Offset.zero;
      _targetOffset = Offset.zero;
      _placeholderOffset = Offset.zero;
    });
  }

  @override
  void initState() {
    _listState = SortableGridStateMixin.of(context);
    _listState.registerItem(this);
    super.initState();
  }

  Offset get offset {
    if (_offsetAnimation != null) {
      return Offset.lerp(
        _startOffset,
        _targetOffset,
        Curves.easeInOut.transform(_offsetAnimation!.value),
      )!;
    }

    return _targetOffset;
  }

  @override
  void dispose() {
    _listState.unRegisterItem(index, this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SortableItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _listState.unRegisterItem(oldWidget.index, this);
      _listState.registerItem(this);
    }
  }

  Widget _buildPlaceHolder() {
    if (_listState.placeholderBuilder == null) {
      return const SizedBox();
    }

    return Transform(
      transform: Matrix4.translationValues(_placeholderOffset.dx, _placeholderOffset.dy, 0),
      child: _listState.placeholderBuilder!(index, _listState.dropIndex, child),
    );
  }

  void onPointerDown(PointerDownEvent e, MultiDragGestureRecognizer recognizer) {
    var listState = SortableGridStateMixin.of(context);
    if (listState.dragEnabled) {
      listState.startDragRecognizer(index, e, recognizer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraint) {
          return Transform(
            transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
            child: Stack(
              children: [
                Offstage(
                  offstage: !_dragging,
                  child: Container(constraints: constraint, child: _buildPlaceHolder()),
                ),
                Offstage(
                  offstage: _dragging,
                  child: Container(
                    constraints: constraint,
                    child: child,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  static SortableItemViewState? of(BuildContext context) {
    return context.findAncestorStateOfType<SortableItemViewState>();
  }
}

class SortableItemHandle extends StatelessWidget {
  final Widget child;
  final bool immediate;
  final MouseCursor? cursor;

  const SortableItemHandle({super.key, required this.child, this.immediate = true, this.cursor});

  @override
  Widget build(BuildContext context) {
    Widget child = Listener(
      child: this.child,
      onPointerDown: (event) {
        SortableItemViewState? itemState = SortableItemViewState.of(context);
        itemState?.onPointerDown(
          event,
          immediate
              ? ImmediateMultiDragGestureRecognizer(debugOwner: itemState)
              : DelayedMultiDragGestureRecognizer(
                  debugOwner: itemState,
                  delay: kLongPressTimeout,
                ),
        );
      },
    );
    if (cursor == null) {
      return child;
    }
    return MouseRegion(cursor: cursor!, child: child);
  }
}

abstract class SortableChildPosDelegate {
  const SortableChildPosDelegate();

  Offset getPos(int index, Map<int, SortableItemViewState> items, BuildContext context);
}

mixin SortableGridWidgetMixin on StatefulWidget {
  ReorderCallback get onReorder;

  DragWidgetBuilder? get dragWidgetBuilder;

  ScrollSpeedController? get scrollSpeedController;

  PlaceholderBuilder? get placeholderBuilder;

  OnDragStart? get onDragStart;

  OnDragUpdate? get onDragUpdate;

  Widget get child;

  Duration? get dragStartDelay;

  bool? get dragEnabled;

  bool? get isSliver;

  bool? get restrictDragScope;

  double? get elevation;

  BorderRadius? get borderRadius;
}

mixin SortableGridStateMixin<T extends SortableGridWidgetMixin> on State<T>, TickerProviderStateMixin<T> {
  MultiDragGestureRecognizer? _recognizer;
  GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  Duration get dragStartDelay => widget.dragStartDelay ?? kLongPressTimeout;

  bool get dragEnabled => widget.dragEnabled ?? true;

  void startDragRecognizer(int index, PointerDownEvent event, MultiDragGestureRecognizer recognizer) {
    setState(() {
      if (_dragIndex != null) {
        _dragReset();
      }

      _dragIndex = index;
      _recognizer = recognizer
        ..onStart = _onDragStart
        ..addPointer(event);
    });
  }

  int? _dragIndex;

  int? _dropIndex;

  int get dropIndex => _dropIndex ?? -1;

  PlaceholderBuilder? get placeholderBuilder => widget.placeholderBuilder;

  OverlayState? getOverlay() {
    return overlayKey.currentState;
  }

  bool containsByIndex(int index) {
    return __items.containsKey(index);
  }

  Offset getPosByOffset(int index, int dIndex) {
    var keys = __items.keys.toList();
    var keyIndex = keys.indexOf(index);
    keyIndex = keyIndex + dIndex;
    if (keyIndex < 0) {
      keyIndex = 0;
    }
    if (keyIndex > keys.length - 1) {
      keyIndex = keys.length - 1;
    }

    return getPosByIndex(keys[keyIndex], safe: true);
  }

  Offset getPosByIndex(int index, {bool safe = true}) {
    if (safe) {
      if (index < 0) {
        index = 0;
      }
    }

    if (index < 0) {
      return Offset.zero;
    }

    var child = __items[index];

    var thisRenderObject = context.findRenderObject();

    if (thisRenderObject is RenderSliverGrid) {
      var renderObject = thisRenderObject;

      final SliverConstraints constraints = renderObject.constraints;
      final SliverGridLayout layout = renderObject.gridDelegate.getLayout(constraints);

      final fixedIndex = child!.indexInAll ?? child.index;
      final SliverGridGeometry gridGeometry = layout.getGeometryForChildIndex(fixedIndex);
      final rst = Offset(gridGeometry.crossAxisOffset, gridGeometry.scrollOffset);
      return rst;
    }

    var renderObject = child?.context.findRenderObject();
    if (renderObject == null) {
      return Offset.zero;
    }
    RenderBox box = renderObject as RenderBox;

    var parentRenderObject = context.findRenderObject() as RenderBox;
    final pos = parentRenderObject.globalToLocal(box.localToGlobal(Offset.zero));
    return pos;
  }

  int _calcDropIndex(int defaultIndex) {
    if (_dragInfo == null) {
      return defaultIndex;
    }

    for (var item in __items.values) {
      RenderBox box = item.context.findRenderObject() as RenderBox;
      Offset pos = box.globalToLocal(_dragInfo!.getCenterInGlobal());
      if (pos.dx > 0 && pos.dy > 0 && pos.dx < box.size.width && pos.dy < box.size.height) {
        return item.index;
      }
    }
    return defaultIndex;
  }

  Offset getOffsetInDrag(int index) {
    if (_dragInfo == null || _dropIndex == null || _dragIndex == _dropIndex) {
      return Offset.zero;
    }

    bool inDragRange = false;
    bool isMoveLeft = _dropIndex! > _dragIndex!;

    int minPos = min(_dragIndex!, _dropIndex!);
    int maxPos = max(_dragIndex!, _dropIndex!);

    if (index >= minPos && index <= maxPos) {
      inDragRange = true;
    }

    if (!inDragRange) {
      return Offset.zero;
    } else {
      if (isMoveLeft) {
        if (!containsByIndex(index - 1) || !containsByIndex(index)) {
          return Offset.zero;
        }
        return getPosByIndex(index - 1) - getPosByIndex(index);
      } else {
        if (!containsByIndex(index + 1) || !containsByIndex(index)) {
          return Offset.zero;
        }
        return getPosByIndex(index + 1) - getPosByIndex(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSliver ?? false || !(widget.restrictDragScope ?? false)) {
      return widget.child;
    }
    return Stack(children: [
      widget.child,
      Overlay(
        key: overlayKey,
      )
    ]);
  }

  Drag _onDragStart(Offset position) {
    HapticFeedback.heavyImpact();

    assert(_dragInfo == null);
    widget.onDragStart?.call(_dragIndex!);

    final SortableItemViewState item = __items[_dragIndex!]!;

    _dropIndex = _dragIndex;

    _dragInfo = DragInfo(
      item: item,
      tickerProvider: this,
      overlay: getOverlay(),
      context: context,
      dragWidgetBuilder: widget.dragWidgetBuilder,
      scrollSpeedController: widget.scrollSpeedController,
      onStart: _onDragStart,
      dragPosition: position,
      onUpdate: _onDragUpdate,
      onCancel: _onDragCancel,
      onEnd: _onDragEnd,
      elevation: widget.elevation,
      borderRadius: widget.borderRadius,
      readyCallback: () {
        item.dragging = true;
        item.rebuild();
        updateDragTarget();
      },
    );

    _startDrag(item);

    return _dragInfo!;
  }

  void _startDrag(SortableItemViewState item) async {
    if (_dragInfo == null) {
      return;
    }
    if (widget.dragWidgetBuilder?.isScreenshotDragWidget ?? false) {
      ui.Image? screenshot = await takeScreenShot(item);
      ByteData? byteData = await screenshot?.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        _dragInfo?.startDrag(MemoryImage(byteData.buffer.asUint8List()));
      }
    } else {
      _dragInfo?.startDrag(null);
    }
  }

  _onDragUpdate(DragInfo item, Offset position, Offset delta) {
    widget.onDragUpdate?.call(_dragIndex!, position, delta);
    updateDragTarget();
  }

  _onDragCancel(DragInfo item) {
    _dragReset();
    setState(() {});
  }

  _onDragEnd(DragInfo item) {
    widget.onReorder(_dragIndex!, _dropIndex!);
    _dragReset();
  }

  _dragReset() {
    if (_dragIndex != null) {
      if (__items.containsKey(_dragIndex!)) {
        final SortableItemViewState item = __items[_dragIndex!]!;
        item.dragging = false;
        item.rebuild();
      }

      _dragIndex = null;
      _dropIndex = null;

      for (var item in __items.values) {
        item.resetGap();
      }
    }

    _recognizer?.dispose();
    _recognizer = null;

    _dragInfo?.dispose();
    _dragInfo = null;
  }

  static SortableGridStateMixin of(BuildContext context) {
    return context.findAncestorStateOfType<SortableGridStateMixin>()!;
  }

  void reorder(int startIndex, int endIndex) {
    setState(() {
      if (startIndex != endIndex) widget.onReorder(startIndex, endIndex);
    });
  }

  final Map<int, SortableItemViewState> __items = <int, SortableItemViewState>{};

  DragInfo? _dragInfo;

  void registerItem(SortableItemViewState item) {
    __items[item.index] = item;
    if (item.index == _dragInfo?.index) {
      item.dragging = true;
      item.rebuild();
    }
  }

  void unRegisterItem(int index, SortableItemViewState item) {
    var current = __items[index];
    if (current == item) {
      __items.remove(index);
    }
  }

  Future<void> updateDragTarget() async {
    int newTargetIndex = _calcDropIndex(_dropIndex!);
    if (newTargetIndex != _dropIndex) {
      _dropIndex = newTargetIndex;
      for (var item in __items.values) {
        item.updateForGap(_dropIndex!);
      }
    }
  }
}

typedef DragItemUpdate = void Function(DragInfo item, Offset position, Offset delta);

typedef DragItemCallback = void Function(DragInfo item);

typedef DragWidgetReadyCallback = void Function();

class DragInfo extends Drag {
  late int index;
  final DragItemUpdate? onUpdate;
  final DragItemCallback? onCancel;
  final DragItemCallback? onEnd;
  final ScrollSpeedController? scrollSpeedController;
  final DragWidgetReadyCallback readyCallback;

  final TickerProvider tickerProvider;
  final GestureMultiDragStartCallback onStart;

  final DragWidgetBuilder? dragWidgetBuilder;
  late Size itemSize;
  late Widget child;
  late ScrollableState scrollable;

  Offset dragPosition;

  late Offset dragOffset;

  late double dragExtent;
  late Size dragSize;

  late SortableItemViewState item;

  AnimationController? _proxyAnimationController;

  OverlayEntry? _overlayEntry;
  BuildContext context;
  OverlayState? overlay;
  var hasEnd = false;

  Offset? zeroOffset;

  ImageProvider? dragWidgetScreenShot;

  final double? elevation;

  final BorderRadius? borderRadius;

  DragInfo({
    required this.readyCallback,
    required this.item,
    required this.tickerProvider,
    required this.onStart,
    required this.dragPosition,
    required this.context,
    this.overlay,
    this.scrollSpeedController,
    this.dragWidgetBuilder,
    this.onUpdate,
    this.onCancel,
    this.onEnd,
    this.elevation,
    this.borderRadius,
  }) {
    index = item.index;
    child = item.widget.child;
    itemSize = item.context.size!;

    zeroOffset = (_getOverlay().context.findRenderObject() as RenderBox).globalToLocal(Offset.zero);

    final RenderBox renderBox = item.context.findRenderObject()! as RenderBox;
    dragOffset = renderBox.globalToLocal(dragPosition);
    dragExtent = renderBox.size.height;
    dragSize = renderBox.size;

    scrollable = Scrollable.of(item.context);
  }

  NavigatorState? findNavigator(BuildContext context) {
    NavigatorState? navigator;
    if (context is StatefulElement && context.state is NavigatorState) {
      navigator = context.state as NavigatorState;
    }
    navigator = navigator ?? context.findAncestorStateOfType<NavigatorState>();
    return navigator;
  }

  Offset getCenterInGlobal() {
    return getPosInGlobal() + dragSize.center(Offset.zero);
  }

  Offset getPosInGlobal() {
    return dragPosition - dragOffset;
  }

  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _proxyAnimationController?.dispose();
    _proxyAnimationController = null;
  }

  Widget createProxy(BuildContext context) {
    var position = dragPosition - dragOffset;
    if (zeroOffset != null) {
      position = position + zeroOffset!;
    }
    return Positioned(
      top: position.dy,
      left: position.dx,
      child: SizedBox(
        width: itemSize.width,
        height: itemSize.height,
        child: dragWidgetBuilder != null
            ? dragWidgetBuilder!.builder(index, child, dragWidgetScreenShot)
            : Material(
                elevation: elevation ?? 5,
                borderRadius: borderRadius,
                child: _defaultDragWidget(context),
              ),
      ),
    );
  }

  Widget _defaultDragWidget(BuildContext context) {
    return child;
  }

  OverlayState _getOverlay() {
    return overlay ?? Overlay.of(context);
  }

  void startDrag(ImageProvider? screenshot) {
    readyCallback();
    dragWidgetScreenShot = screenshot;
    _overlayEntry = OverlayEntry(builder: createProxy);

    final OverlayState overlay = _getOverlay();
    overlay.insert(_overlayEntry!);
    _scrollIfNeed();
  }

  @override
  void update(DragUpdateDetails details) {
    dragPosition += details.delta;
    onUpdate?.call(this, dragPosition, details.delta);

    _overlayEntry?.markNeedsBuild();
    _scrollIfNeed();
  }

  var _autoScrolling = false;

  var _scrollBeginTime = 0;

  static const defaultScrollDuration = 14;

  void _scrollIfNeed() async {
    if (hasEnd) {
      _scrollBeginTime = 0;
      return;
    }
    if (hasEnd) return;

    if (!_autoScrolling) {
      double? newOffset;
      bool needScroll = false;
      final ScrollPosition position = scrollable.position;
      final RenderBox scrollRenderBox = scrollable.context.findRenderObject()! as RenderBox;

      final scrollOrigin = scrollRenderBox.localToGlobal(Offset.zero);
      final scrollStart = scrollOrigin.dy;

      final scrollEnd = scrollStart + scrollRenderBox.size.height;

      final dragInfoStart = getPosInGlobal().dy;
      final dragInfoEnd = dragInfoStart + dragExtent;

      final overBottom = dragInfoEnd > scrollEnd;
      final overTop = dragInfoStart < scrollStart;

      final needScrollBottom = overBottom && position.pixels < position.maxScrollExtent;
      final needScrollTop = overTop && position.pixels > position.minScrollExtent;

      const double oneStepMax = 5;
      double scroll = oneStepMax;

      double overSize = 0;

      if (needScrollBottom) {
        overSize = dragInfoEnd - scrollEnd;
        scroll = min(overSize, oneStepMax);
      } else if (needScrollTop) {
        overSize = scrollStart - dragInfoStart;
        scroll = min(overSize, oneStepMax);
      }

      calcOffset() {
        if (needScrollBottom) {
          newOffset = min(position.maxScrollExtent, position.pixels + scroll);
        } else if (needScrollTop) {
          newOffset = max(position.minScrollExtent, position.pixels - scroll);
        }
        needScroll = newOffset != null && (newOffset! - position.pixels).abs() >= 1.0;
      }

      calcOffset();

      if (needScroll && scrollSpeedController != null) {
        if (_scrollBeginTime <= 0) {
          _scrollBeginTime = DateTime.now().millisecondsSinceEpoch;
        }

        scroll = scrollSpeedController!(
          DateTime.now().millisecondsSinceEpoch - _scrollBeginTime,
          overSize,
          itemSize.height,
        );

        calcOffset();
      }

      if (needScroll) {
        _autoScrolling = true;
        await position.animateTo(newOffset!,
            duration: const Duration(milliseconds: defaultScrollDuration), curve: Curves.linear);
        _autoScrolling = false;
        _scrollIfNeed();
      } else {
        _scrollBeginTime = 0;
      }
    }
  }

  @override
  void end(DragEndDetails details) {
    onEnd?.call(this);

    _endOrCancel();
  }

  @override
  void cancel() {
    onCancel?.call(this);

    _endOrCancel();
  }

  void _endOrCancel() {
    hasEnd = true;
  }
}

Future<ui.Image?> takeScreenShot(State state) async {
  var renderObject = state.context.findRenderObject();

  if (renderObject is RenderRepaintBoundary) {
    RenderRepaintBoundary renderRepaintBoundary = renderObject;

    var devicePixelRatio = MediaQuery.of(state.context).devicePixelRatio;
    return renderRepaintBoundary.toImage(pixelRatio: devicePixelRatio);
  }
  return null;
}
