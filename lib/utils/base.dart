import 'dart:async';

import 'package:engine/api/socket/socket_master.dart';
import 'package:engine/api/stats/stats.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/loading.dart';
import 'package:engine/utils/platform/load.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/tabs.dart';
import 'package:engine/utils/web/web.dart';
import 'package:engine/utils/widgets/breadcrumb.dart';
import 'package:engine/utils/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class BaseRoute<T extends StatefulWidget> extends State<T>
    with TickerProviderStateMixin<T>, TabStore<T>, ChannelFollowable {
  final LoadingModal loadingModal = LoadingModal();
  final DialogModal dialogModal = DialogModal();
  final GlobalKey key = GlobalKey();
  bool isLoaded = false;
  bool isStats = false;
  bool showHeader = true;
  Widget? body;

  final MethodChannel platform = const MethodChannel("base");

  @mustCallSuper
  Future<void> beforeLoad(AppLocalizations locale) async {
    if (!isStats) {
      StatsUtils.pushStats(locale.lng, RouteSettingsSaver.routeSettings(context)?.name);
      isStats = true;
    }
    isLoaded = true;
    body = null;
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    Widget full() {
      return body ??= Stack(
        key: key,
        children: [
          getFold(),
          Positioned.fill(child: loadingModal),
          Positioned.fill(child: dialogModal),
        ],
      );
    }

    if (isLoaded) {
      return full();
    }
    return FutureBuilder(
      future: beforeLoad(Language.of(context)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return getFold();
        }
        return full();
      },
    );
  }

  @override
  Future<void> reload() async {
    if (mounted) {
      setState(() {
        isLoaded = false;
      });
    }
  }

  Future<void> login() async {
    await Navigator.pushNamed(context, "/profile");
  }

  Future<void> logout() async {
    await UsersStore.logout();
    reload();
  }

  void loading(bool active, [Function()? dismiss]) {
    loadingModal.setActive(active, dismiss);
  }

  Widget getBody();

  String? getSearchRoute() => null;

  List<GlobalMenuItem>? getMenu() {
    return null;
  }

  String? getTitle();

  List<Widget> getActionButtons() {
    return [];
  }

  List<ActionMenuItem> getBaseActionsMenu() {
    return [];
  }

  List<ActionMenuItem> getActionsMenu() {
    return [];
  }

  Widget? getFab() {
    return null;
  }

  BottomNavigation? getBottomNavigation() {
    return null;
  }

  List<GlobalMenuItem> getBaseMenu([String? active]) {
    return [];
  }

  FutureOr<List<BreadcrumbItem>>? getBreadcrumb() {
    return null;
  }

  Widget getFold() {
    String title = (getTitle() ?? '').replaceAll("\n", " ").trim();
    WebData.setTitle(title);
    return Fold(
      search: getSearchRoute(),
      appTitle: getAppTitle(),
      appSlogan: getAppSlogan(),
      menus: getMenu(),
      tabStore: this,
      title: title,
      showHeader: showHeader,
      breadcrumb: getBreadcrumb(),
      actionsMenu: [...getBaseActionsMenu(), ...getActionsMenu()],
      actionButtons: getActionButtons(),
      isLoaded: isLoaded,
      bottomNavigation: getBottomNavigation()?..show(true),
      fab: getFab(),
      child: getBody(),
    );
  }

  String? getAppTitle() => null;

  String? getAppSlogan() => null;

  @override
  bool canTabSwipe() => false;

  @override
  void reassemble() {
    clearTabs();
    isLoaded = false;
    super.reassemble();
  }

  @override
  void initState() {
    platform.setMethodCallHandler(nativeMethodCallHandler);
    MasterSocket.follow("user").then((stream) => stream.stream.listen((event) {
          if (event['action'] == 'logout') {
            logout();
          }
        }));
    super.initState();
  }

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case "pushNamed":
        Navigator.of(context).pushNamed(methodCall.arguments as String);
        break;
      default:
    }
  }

  static BaseRoute? maybeOf(BuildContext context) {
    if (context is StatefulElement && context.state is BaseRoute) {
      return context.state as BaseRoute;
    }
    return context.findAncestorStateOfType<BaseRoute>();
  }

  @override
  void dispose() {
    unfollowAll();
    super.dispose();
  }
}
