import 'dart:ui';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:engine/data/files.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/data/store.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/socket/websocket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'natives.dart';

class Engine extends StatelessWidget {
  final Route Function(RouteSettings settings) routeMaker;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;
  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;
  final String title;

  const Engine({
    super.key,
    this.title = "",
    required this.routeMaker,
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.localizationsDelegates,
  });

  @override
  Widget build(BuildContext context) {
    TabBarTheme tabBarTheme = TabBarTheme(
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: lightColorScheme.secondary)),
        indicatorColor: lightColorScheme.primary,
        overlayColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          const Set<WidgetState> interactiveStates = {WidgetState.pressed, WidgetState.hovered, WidgetState.focused};
          if (states.any(interactiveStates.contains)) {
            return lightColorScheme.tertiaryContainer.withOpacity(0.2);
          }
          return lightColorScheme.tertiary;
        }));
    return AdaptiveTheme(
      light: ThemeData(
          brightness: Brightness.light, useMaterial3: true, colorScheme: lightColorScheme, tabBarTheme: tabBarTheme),
      dark: ThemeData(
          brightness: Brightness.dark, useMaterial3: true, colorScheme: darkColorScheme, tabBarTheme: tabBarTheme),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        title: title,
        onGenerateInitialRoutes: (initialRoute) => [routeMaker(RouteSettings(name: initialRoute))],
        onGenerateRoute: (settings) => routeMaker(settings),
        debugShowCheckedModeBanner: false,
        scrollBehavior: CustomScrollBehavior(),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: Language.supportedLocales(),
        theme: theme,
        darkTheme: darkTheme,
        navigatorObservers: [history],
      ),
    );
  }
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

final NavigationHistoryObserver history = NavigationHistoryObserver();

class NavigationHistoryObserver extends NavigatorObserver {
  final List<String> history = [];

  String? get lastBefore => history.length >= 2 ? history[history.length - 2] : null;

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name != null) {
      history.add(route.settings.name!);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name != null && history.last == route.settings.name) {
      history.removeLast();
    }
  }
}

class GlobalInit {
  static Future<void> init(Color systemUIOverlay) async {
    WidgetsFlutterBinding.ensureInitialized();

    NativeCall.init();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(systemNavigationBarColor: systemUIOverlay));

    SettingsStore.init();
    await UsersStore.init();
    if (UsersStore.user == null) {
      await Store.init();
    }
    MasterSocket.init();
    FilesCache.purge();
  }

  static Future<void> nativeInit() async {
    WidgetsFlutterBinding.ensureInitialized();

    SettingsStore.init();
    await UsersStore.init();

    if (UsersStore.user == null) {
      await Store.init();
    }

    NativeCall.init();
  }
}
