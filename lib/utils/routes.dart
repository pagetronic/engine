import 'package:engine/api/utils/json.dart';
import 'package:flutter/material.dart';

class PageRouteEffects {
  static PageRoute normalLoad(Widget route, {RouteSettings? settings, bool maintainState = true}) {
    return SimplePageRoute(
      settings: settings,
      maintainState: maintainState,
      builder: (BuildContext context) => RouteSettingsSaver(settings: settings, child: route),
    );
  }

  static PageRoute slideLoad(Widget route, {RouteSettings? settings, bool maintainState = true}) {
    return SlidePageRoute(
        maintainState: maintainState,
        settings: settings,
        builder: (context) {
          return RouteSettingsSaver(settings: settings, child: route);
        });
  }

  static PageRoute transparentLoad(Widget route, {RouteSettings? settings, bool maintainState = true}) {
    return TransparentPageRoute(
        maintainState: maintainState,
        settings: settings,
        builder: (context) {
          return RouteSettingsSaver(settings: settings, child: route);
        });
  }
}

class SlidePageRoute extends MaterialPageRoute {
  final Offset begin = const Offset(0.0, 1.2);
  final Offset end = Offset.zero;
  final CurveTween curve = CurveTween(curve: Curves.ease);

  SlidePageRoute({required super.builder, super.maintainState, super.settings});

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: animation.drive(Tween(begin: begin, end: end).chain(curve)),
      child: child,
    );
  }
}

class SimplePageRoute extends MaterialPageRoute {
  SimplePageRoute({required super.builder, super.settings, super.maintainState});

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class TransparentPageRoute extends PageRoute with MaterialRouteTransitionMixin {
  @override
  final bool maintainState;
  final WidgetBuilder builder;

  TransparentPageRoute(
      {required this.builder, super.settings, super.fullscreenDialog = false, this.maintainState = false});

  @override
  bool get opaque => false;

  @override
  Widget buildContent(BuildContext context) {
    return builder(context);
  }
}

class PageRouteInfo {
  final PageRouteType type;
  final Json? item;

  PageRouteInfo(this.type, [this.item]);
}

enum PageRouteType { slide, normal }

class RouteSettingsSaver extends StatelessWidget {
  //See bug https://github.com/flutter/flutter/issues/146132 for ModalRoute.of(context).
  final Widget child;
  final RouteSettings? settings;

  const RouteSettingsSaver({super.key, required this.child, this.settings});

  @override
  Widget build(BuildContext context) => child;

  static RouteSettings? routeSettings(BuildContext context) {
    return context.findAncestorWidgetOfExactType<RouteSettingsSaver>()?.settings;
  }
}
