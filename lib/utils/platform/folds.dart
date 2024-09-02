import 'dart:async';

import 'package:engine/api/network.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/platform/load.dart';
import 'package:engine/utils/sizer.dart';
import 'package:engine/utils/tabs.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:flutter/material.dart';

class Fold extends StatelessWidget {
  final List<GlobalMenuItem>? menus;
  final FutureOr<List<BreadcrumbItem>>? breadcrumb;
  final TabStore tabStore;
  final bool showHeader;
  final String? title;
  final List<ActionMenuItem> actionsMenu;
  final List<Widget> actionButtons;
  final bool isLoaded;
  final BottomNavigation? bottomNavigation;
  final Widget? fab;
  final Widget child;
  final String? appTitle;
  final String? appSlogan;
  final String? search;

  final Widget networkButton = const NetworkActionButton();

  const Fold({
    super.key,
    this.search,
    this.menus,
    required this.tabStore,
    this.title,
    this.showHeader = true,
    this.breadcrumb,
    required this.actionsMenu,
    required this.actionButtons,
    required this.isLoaded,
    this.bottomNavigation,
    this.fab,
    this.appTitle,
    this.appSlogan,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizerWidget(
      sizes: const [1200],
      builder: (context, maxSize) {
        if (!actionButtons.contains(networkButton)) {
          actionButtons.add(networkButton);
        }
        bool isSmall = maxSize == 1200;

        Widget? rail = isSmall ? null : GlobalMenu.getRail(menus);
        Widget body = tabStore.getTabsController(
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            drawer: !isSmall ? null : GlobalMenu.getBurger(menus, appTitle, appSlogan),
            appBar: !showHeader
                ? null
                : Header(
                    search: search,
                    automaticallyImplyLeading: isSmall || (Navigator.of(context).canPop() && menus == null),
                    tabs: tabStore,
                    title: title,
                    actionsButtons: [...actionButtons],
                    actionsMenu: [
                      for (ActionMenuItem menu in actionsMenu) menu,
                    ],
                  ),
            body: Builder(
              builder: (context) {
                return !isSmall
                    ? Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Stack(
                          children: [
                            Positioned(
                              left: rail != null ? 80 : 0,
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Column(
                                children: [
                                  if (tabStore.length > 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        backgroundBlendMode: BlendMode.srcIn,
                                        border: const Border(bottom: BorderSide(width: 1, color: Colors.black12)),
                                      ),
                                      child: Flex(
                                        direction: Axis.horizontal,
                                        children: [
                                          Expanded(
                                              child:
                                                  tabStore.getTabBar(context, padding: const EdgeInsets.only(left: 5)))
                                        ],
                                      ),
                                    ),
                                  Breadcrumb(breadcrumb, top: true),
                                  Expanded(child: !isLoaded ? const CaterpillarDelayedLoading(delay: 900) : child),
                                ],
                              ),
                            ),
                            Positioned(left: 0, top: 0, bottom: 0, child: rail ?? const SizedBox.shrink()),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (tabStore.length > 1)
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                backgroundBlendMode: BlendMode.srcIn,
                                border: const Border(bottom: BorderSide(width: 1, color: Colors.black12)),
                              ),
                              child: tabStore.getTabBar(context),
                            ),
                          Breadcrumb(breadcrumb, top: true),
                          Expanded(
                              child: !isLoaded
                                  ? const Loading()
                                  : Align(
                                      alignment: Alignment.topCenter,
                                      child: child,
                                    )),
                        ],
                      );
              },
            ),
            floatingActionButtonLocation: bottomNavigation == null
                ? FloatingActionButtonLocation.endFloat
                : FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: bottomNavigation,
            floatingActionButton: fab,
          ),
        );

        body = NetworkListener(
          onNetwork: (bool network) {
            networkAvailable.value = network;
          },
          child: body,
        );
        return body;
      },
    );
  }
}

class LowFold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Object? tag;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

  const LowFold(
      {super.key,
      required this.body,
      this.tag,
      this.title,
      this.backgroundColor,
      this.automaticallyImplyLeading = true});

  @override
  Widget build(BuildContext context) {
    Scaffold fold = Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      body: body,
      appBar: Header(
        title: title,
        automaticallyImplyLeading: automaticallyImplyLeading,
        actionsButtons: const [NetworkActionButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (tag != null) {
      return Hero(tag: tag!, child: fold);
    }
    return fold;
  }
}

class SearchFold extends StatelessWidget {
  final Widget body;
  final Object? tag;
  final TextEditingController controller;

  const SearchFold({super.key, required this.body, required this.controller, this.tag});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 1200) {
          Scaffold fold = Scaffold(body: body, appBar: SearchFoldHead(controller, tag));
          return tag != null ? Hero(tag: tag!, child: fold) : fold;
        }
        Widget dialog = Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: ColoredBox(color: Theme.of(context).shadowColor.withOpacity(0.1))),
            Center(
              child: Container(
                clipBehavior: Clip.antiAlias,
                constraints: BoxConstraints(maxWidth: 800, maxHeight: constraints.maxHeight * 0.8),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                ),
                child: Scaffold(
                  body: body,
                  appBar: SearchFoldHead(
                    controller,
                    tag,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        );
        return Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          child: tag != null ? Hero(tag: tag!, child: dialog) : dialog,
        );
      },
    );
  }
}
