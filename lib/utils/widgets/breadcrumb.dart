import 'dart:async';

import 'package:engine/api/utils/html.dart';
import 'package:engine/api/utils/json.dart';
import 'package:engine/utils/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Breadcrumb extends StatelessWidget {
  final FutureOr<List<BreadcrumbItem>>? crumbs;
  final bool top;
  final double fontSize = 14;

  const Breadcrumb(this.crumbs, {super.key, this.top = false});

  @override
  Widget build(BuildContext context) {
    if (crumbs == null) {
      return const SizedBox.shrink();
    }
    return FutureOrBuilder(
      future: crumbs!,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null ||
            snapshot.data!.isEmpty ||
            snapshot.data!.length <= 1) {
          return const SizedBox.shrink();
        }
        List<Widget> children = [];

        for (int index = 0; index < snapshot.data!.length; index++) {
          if (index > 0) {
            Widget arrow = Icon(Icons.chevron_right, size: fontSize - 2);
            children.add(index == snapshot.data!.length - 1
                ? FutureBuilder(
                    future: Future<void>.delayed(const Duration(milliseconds: 100)),
                    builder: (context, snapshot) {
                      return AnimatedOpacity(
                          opacity: snapshot.connectionState != ConnectionState.done ? 0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: arrow);
                    })
                : arrow);
          }
          BreadcrumbItem crumb = snapshot.data![index];
          Text title = Text(crumb.title, style: TextStyle(fontSize: fontSize));
          children.add(Material(
            child: InkWell(
                borderRadius: BorderRadius.circular(3),
                onTap: crumb.route != null ? () => crumb.route!(context) : null,
                child: Padding(
                    padding: EdgeInsets.only(
                        left: (index == 0 ? 20 : 12),
                        right: (index == snapshot.data!.length - 1 ? 20 : 12),
                        top: 4,
                        bottom: 4),
                    child: index == snapshot.data!.length - 1
                        ? FutureBuilder(
                            future: Future<void>.delayed(const Duration(milliseconds: 100)),
                            builder: (context, snapshot) {
                              return AnimatedOpacity(
                                  opacity: snapshot.connectionState != ConnectionState.done ? 0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: title);
                            })
                        : title)),
          ));
        }
        ScrollController controller = ScrollController();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          try {
            controller.animateTo(
              controller.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          } catch (_) {}
        });
        return Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
          padding: top ? const EdgeInsets.only(bottom: 3) : const EdgeInsets.only(top: 3),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: fontSize * 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  if (top)
                    BoxShadow(
                        blurStyle: BlurStyle.solid,
                        color: Theme.of(context).shadowColor,
                        blurRadius: 3,
                        offset: const Offset(0, -1))
                  else
                    BoxShadow(
                        blurStyle: BlurStyle.solid,
                        color: Theme.of(context).shadowColor,
                        blurRadius: 3,
                        offset: const Offset(0, 1)),
                ],
              ),
              child: ListView(controller: controller, scrollDirection: Axis.horizontal, children: children),
            ),
          ),
        );
      },
    );
  }
}

class BreadcrumbEmbedded extends StatelessWidget {
  final FutureOr<List<BreadcrumbItem>>? crumbs;
  final EdgeInsets? padding;
  final double? fontSize;

  const BreadcrumbEmbedded(this.crumbs, {super.key, this.padding, this.fontSize});

  @override
  Widget build(BuildContext context) {
    if (crumbs == null) {
      return const SizedBox.shrink();
    }
    return FutureOrBuilder(
      future: crumbs!,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.data == null || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        List<Widget> children = [];

        for (int index = 0; index < snapshot.data!.length; index++) {
          BreadcrumbItem crumb = snapshot.data![index];
          children.add(Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (index > 0) Center(child: Icon(Icons.chevron_right, size: fontSize ?? 11)),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: crumb.route != null ? () => crumb.route!(context) : null,
                child: Padding(
                  padding: EdgeInsets.only(top: 2, bottom: 1, left: index == 0 ? 0 : 4, right: 4),
                  child: Text(crumb.title,
                      style: TextStyle(
                          fontSize: fontSize,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dashed)),
                ),
              ),
            ],
          ));
        }
        return SizedBox(
            height: (fontSize ?? 14) + 10,
            child: ListView(
              padding: padding,
              scrollDirection: Axis.horizontal,
              children: children,
            ));
      },
    );
  }
}

class BreadcrumbUtils {
  static List<BreadcrumbItem> make(List breadcrumb) {
    List<BreadcrumbItem> breadcrumb_ = [];
    if (breadcrumb.isNotEmpty) {
      for (Json crumb in breadcrumb) {
        breadcrumb_.add(BreadcrumbItem(HtmlEscaper.unescape(crumb['title'] ?? "--"),
            (BuildContext context) => Navigator.pushNamed(context, crumb['url'], arguments: crumb)));
      }
    }
    return breadcrumb_;
  }
}

class BreadcrumbItem {
  final String title;
  final Function(BuildContext context)? route;

  BreadcrumbItem(this.title, [this.route]);
}
