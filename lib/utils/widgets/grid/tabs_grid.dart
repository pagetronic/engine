import 'dart:math';

import 'package:engine/utils/tabs.dart';
import 'package:engine/utils/widgets/grid/sortable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TabGrid extends StatefulWidget {
  final OnReorder onReorder;
  final List<Widget>? header;
  final List<Widget>? children;
  final List<Widget>? footer;
  final double? ratio;

  const TabGrid({super.key, required this.onReorder, this.header, this.children, this.footer, this.ratio});

  @override
  TabGridState createState() {
    return TabGridState();
  }
}

class TabGridState extends State<TabGrid> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int maxWidth = 400;
        int maxHeight = 300;

        int minWidth = 350;

        int columns = constraints.maxWidth > minWidth ? max(2, constraints.maxWidth ~/ maxWidth) : 1;
        double spacing = max(17, 3.0 * columns);

        double finalWidth = constraints.maxWidth / columns;

        int boxCount = 0;
        if (widget.children != null) {
          boxCount += widget.children!.length;
        }
        if (widget.header != null) {
          boxCount += widget.header!.length;
        }
        if (widget.footer != null) {
          boxCount += widget.footer!.length;
        }
        int heightCount = (boxCount / columns).round();

        double finalHeight = max((constraints.maxHeight - heightCount * spacing) / heightCount, maxHeight.toDouble());

        double ratio = widget.ratio ?? max(0.5, finalWidth / finalHeight);

        if (context.mounted) {
          Future.delayed(const Duration(milliseconds: 1400), () {
            // Messager.toast(context, "${constraints.maxWidth}/${constraints.maxHeight}");
          });
        }
        return SortableGridView.count(
          elevation: 15.0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(4)),
          childAspectRatio: ratio,
          restrictDragScope: false,
          shrinkWrap: true,
          padding: EdgeInsets.all(spacing),
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          onDragStart: (int index) => HapticFeedback.heavyImpact(),
          onReorder: (int oldIndex, int newIndex) {
            setState(() {
              widget.children!.insert(newIndex, widget.children!.removeAt(oldIndex));
            });
            widget.onReorder(oldIndex, newIndex);
          },
          header: widget.header,
          footer: widget.footer,
          children: widget.children ?? [],
        );
      },
    );
  }
}

class TabGridItem extends StatelessWidget {
  final TabStoreItem item;
  final int index;
  final bool canMove;

  const TabGridItem(this.item, {super.key, required this.index, this.canMove = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(4)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(4)),
          color: item.color ?? Theme.of(context).secondaryHeaderColor,
          border: Border.all(width: 3, color: item.color ?? Theme.of(context).primaryColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SortableItemHandle(
              cursor: canMove ? SystemMouseCursors.move : null,
              child: Padding(
                padding: EdgeInsets.only(top: 0, bottom: 6, left: item.icon != null ? 2 : 7, right: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (item.icon != null) Icon(item.icon!, size: 14, color: Colors.white),
                    if (item.icon != null) const SizedBox(width: 5),
                    if (item.title != null)
                      Expanded(
                          child: Text(item.title!,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: SortableItemHandle(
                  immediate: false,
                  child: item.view,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
