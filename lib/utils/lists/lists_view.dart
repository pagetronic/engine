import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/widgets/date.dart';
import 'package:flutter/material.dart';

class ListViewItem extends StatelessWidget {
  final String title;
  final int index;
  final bool sortable;
  final void Function()? onTap;
  final List<Widget>? buttons;
  final Widget Function(BuildContext context, ImageFormat format)? getIcon;
  final DateTime? date;
  final DateTime? update;
  final Widget? breadcrumb;

  const ListViewItem({
    super.key,
    this.sortable = false,
    required this.title,
    required this.index,
    this.onTap,
    this.getIcon,
    this.buttons,
    this.date,
    this.update,
    this.breadcrumb,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    return Material(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmall = constraints.maxWidth <= 500;
          if (isSmall) {
            return Container(
              padding: const EdgeInsets.only(top: 8, bottom: 5, left: 10, right: 10),
              decoration: StyleListView.getOddEvenBoxDecoration(index),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (sortable)
                    ReorderableDragStartListener(
                      index: index,
                      child: const MouseRegion(
                          cursor: SystemMouseCursors.move,
                          child: Icon(Icons.height_outlined, size: 20, color: Colors.grey)),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: onTap,
                          child: Row(
                            children: [
                              if (getIcon != null) ...[getIcon!(context, ImageFormat.png20), const SizedBox(width: 8)],
                              Expanded(
                                child: H4(title, softWrap: true),
                              ),
                            ],
                          ),
                        ),
                        if (date != null || update != null)
                          Wrap(
                            spacing: 5,
                            children: [
                              if (date != null)
                                Since(date: date, locale: locale.since_created, style: const TextStyle(fontSize: 10)),
                              if (update != null && (date == null || !date!.isAtSameMomentAs(update!)))
                                Since(date: update, locale: locale.since_updated, style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        if (breadcrumb != null) breadcrumb!,
                      ],
                    ),
                  ),
                  if (buttons != null) Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: buttons!)
                ],
              ),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: StyleListView.getOddEvenBoxDecoration(index),
            child: Row(
              children: [
                if (sortable)
                  ReorderableDragStartListener(
                    index: index,
                    child: const MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: Icon(Icons.height_outlined, size: 30, color: Colors.grey)),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 7, left: 10, right: 10),
                          child: Row(
                            children: [
                              if (getIcon != null) ...[getIcon!(context, ImageFormat.png40), const SizedBox(width: 8)],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    H3(title),
                                    if (date != null || update != null)
                                      Wrap(
                                        spacing: 5,
                                        children: [
                                          if (date != null) Since(date: date, locale: locale.since_created),
                                          if (update != null && (date == null || !date!.isAtSameMomentAs(update!)))
                                            Since(date: update, locale: locale.since_updated),
                                        ],
                                      ),
                                    if (breadcrumb != null) breadcrumb!,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (buttons != null) Row(children: buttons!)
              ],
            ),
          );
        },
      ),
    );
  }
}
