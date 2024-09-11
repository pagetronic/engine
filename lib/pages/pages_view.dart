import 'dart:async';

import 'package:engine/admin/pages.dart';
import 'package:engine/api/api.dart';
import 'package:engine/api/html/html.dart';
import 'package:engine/api/utils/html.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/threads/widgets/posts_inputs.dart';
import 'package:engine/threads/widgets/posts_views.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/error.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/lists/lists_utils.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

mixin PageViewer<T extends StatefulWidget> on BaseRoute<T> {
  final Json page = Json();
  final TextEditingController controller = TextEditingController();
  ApiListView? noreply;

  String getUrl();

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    Object? arguments = RouteSettingsSaver.routeSettings(context)?.arguments;

    if (arguments != null && arguments is Json) {
      page.addAll(arguments);
    }
    Json? page_ = HtmlDocumentData.getData("page") ?? (await Api.get(getUrl(), lng: Language.of(context).lng));
    if (page_ != null) {
      page.clear();
      page.addAll(page_);
    }

    clearTabs();
    await canOrderTabs("pageOrder");

    addTab(
      getFirst(),
      title: "infos",
      icon: Icons.info_outline,
      tag: "page",
    );

    if ((page['noreply']?['result'] ?? []).isNotEmpty) {
      noreply = ApiListView(
          initial: Result(page['noreply']),
          request: (paging) async {
            Json? result = await Api.get("/threads/noreply?id=${page.id}", paging: paging);
            return Result(result);
          },
          getView: (context, item, index) {
            return PostsViewItem(
              item,
              onUpdate: (item) => reload(),
            );
          });
      addTab(
        noreply!,
        title: locale.threads_noreply,
        icon: Icons.forum_outlined,
        tag: "threads_noreply",
      );
    }

    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    return getViews();
  }

  ApiListView? list;

  Widget getFirst() {
    if (page.id == null) {
      return const NotFoundView();
    }
    AppLocalizations locale = Language.of(context);
    return list = ApiListView(
      padding: const EdgeInsets.only(bottom: 20),
      noRefresh: true,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (page.id != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageText("=${HtmlEscaper.unescape(page['title'] ?? "")}=\n\n\n"
                      "${HtmlEscaper.unescape(page['text'] ?? '')}"),
                ],
              ),
            ),
          Container(
            decoration: const BoxDecoration(border: Border(top: StyleListView.border)),
            child: PostsTextInput(
              parent: "Pages/${page.id}",
              loading: loading,
              after: (post) {
                noreply?.update(post);
              },
              hintText: locale.threads_question_hint_titled(page['title']),
              controller: controller,
            ),
          ),
          for (Json child in page['children']) PageChild(child),
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(border: Border(top: StyleListView.border)),
            child: const SizedBox(height: 1),
          ),
        ],
      ),
      initial: Result(page['threads']),
      noEmpty: true,
      request: (paging) async {
        Json? result = await Api.get("/threads/reply?id=${page.id}", paging: paging);
        return Result(result);
      },
      getView: (context, item, index) {
        return PostsViewItem(
          clickable: true,
          item,
          onUpdate: (item) => list?.update(item),
        );
      },
    );
  }

  @override
  List<ActionMenuItem> getActionsMenu() {
    if (!Users.isAdmin) {
      return [];
    }
    return [
      ActionMenuItem(
        title: "Edit",
        icon: Icons.edit_outlined,
        onSelect: () => Navigator.push(context, PageRouteEffects.slideLoad(PagesEdit(page: page))),
      )
    ];
  }

  @override
  FutureOr<List<BreadcrumbItem>>? getBreadcrumb() async {
    List<BreadcrumbItem> breadcrumb = [];
    if (page['breadcrumb'] != null) {
      for (dynamic bread in page['breadcrumb']) {
        breadcrumb.add(BreadcrumbItem(HtmlEscaper.unescape(bread['title']), (BuildContext context) {
          Navigator.pushNamed(context, bread['url'], arguments: bread);
        }));
      }
      breadcrumb.add(BreadcrumbItem(HtmlEscaper.unescape(page['title'])));
    }
    return breadcrumb;
  }
}

class PageText extends StatelessWidget {
  final String? text;

  const PageText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return const SizedBox.shrink();
    }
    List<Widget> riches = [];
    RegExp pattern = RegExp("([^\n\r]+)?([\n\r ]+)?");
    RegExp headPattern = RegExp('^([= ]+)([^=]+)([= ]+)\$');
    RegExp hrefPattern = RegExp('(.*)?<a[^>]+href="(.*?)"[^>]*>(.*)?</a>(.*)?');
    Iterator<RegExpMatch> matches = pattern.allMatches(text!).iterator;
    while (matches.moveNext()) {
      String subText = matches.current.group(1) ?? "";
      if (subText.isEmpty) {
        continue;
      }
      RegExpMatch? head = headPattern.firstMatch(subText);
      if (head != null) {
        riches.add(Text.rich(
            textAlign: TextAlign.justify,
            TextSpan(
              text: head.group(2)!.trim(),
              style: head.group(1)!.length == 1
                  ? Theme.of(context).textTheme.headlineLarge
                  : head.group(1)!.length == 2
                      ? Theme.of(context).textTheme.headlineMedium
                      : head.group(1)!.length == 3
                          ? Theme.of(context).textTheme.headlineSmall
                          : head.group(1)!.length == 4
                              ? Theme.of(context).textTheme.titleLarge
                              : head.group(1)!.length == 5
                                  ? Theme.of(context).textTheme.titleMedium
                                  : head.group(1)!.length == 6
                                      ? Theme.of(context).textTheme.titleSmall
                                      : null,
            )));
      } else if (subText.startsWith("*")) {
        riches.add(Text.rich(
            textAlign: TextAlign.justify,
            TextSpan(
                text: "   ${String.fromCharCode(0x2022)}  ${subText.substring(1)}",
                style: Theme.of(context).textTheme.bodyMedium)));
      } else {
        List<TextSpan> subRiches = [];
        if (hrefPattern.hasMatch(subText)) {
          Iterator<RegExpMatch> hrefMatches = hrefPattern.allMatches(subText).iterator;

          while (hrefMatches.moveNext()) {
            String before = hrefMatches.current.group(1) ?? '';
            String anchor = hrefMatches.current.group(3) ?? '';
            String url = hrefMatches.current.group(2) ?? '';
            String after = hrefMatches.current.group(4) ?? '';
            subRiches.add(
              TextSpan(text: before, style: Theme.of(context).textTheme.bodyMedium),
            );
            subRiches.add(
              TextSpan(
                text: anchor,
                mouseCursor: SystemMouseCursors.click,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap =
                      () => url.startsWith("http") ? launchUrl(Uri.parse(url)) : Navigator.pushNamed(context, url),
              ),
            );
            subRiches.add(
              TextSpan(text: "$after ", style: Theme.of(context).textTheme.bodyMedium),
            );
          }
        } else {
          subRiches.add(TextSpan(text: subText, style: Theme.of(context).textTheme.bodyMedium));
        }
        riches.add(Text.rich(textAlign: TextAlign.justify, TextSpan(children: subRiches)));
        riches.add(const SizedBox(height: 10));
      }
    }
    return SelectionArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: riches));
  }
}

class PageChild extends StatelessWidget {
  final Json child;

  const PageChild(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, child['url'], arguments: child),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(HtmlEscaper.unescape(child['title'] ?? "no title"),
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                  decoration: TextDecoration.underline,
                )),
            if (child['text'] != null) Text(HtmlEscaper.unescape(child['text'])),
          ],
        ),
      ),
    );
  }
}
