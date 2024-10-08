import 'package:engine/api/api.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Json? user) builder;

  const UserBuilder({required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, user, child_) {
        return builder(context, user?.data);
      },
    );
  }
}

class UserLoginOrWidget extends StatelessWidget {
  final Widget child;

  const UserLoginOrWidget({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, user, child_) {
        if (user == null) {
          return Stack(
            children: [
              child,
              Positioned.fill(
                  child: Stack(children: [
                ColoredBox(
                  color: Theme.of(context).dialogTheme.shadowColor ?? Colors.black.withOpacity(0.5),
                  child: const SizedBox.expand(),
                ),
                Center(
                  child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, "/profile",
                          arguments: {"referer": RouteSettingsSaver.routeSettings(context)?.name}),
                      icon: const Icon(Icons.person_off),
                      label: Text(Language.of(context).login)),
                )
              ]))
            ],
          );
        }
        return child;
      },
    );
  }
}

class ValueNotifierUser implements ValueListenable<User?> {
  final List<VoidCallback> listeners = [];
  User? current;

  @override
  User? get value => current;

  set value(User? newValue) {
    if (newValue?.identifier != current?.identifier) {
      current = newValue;
      notifyListeners();
    }
  }

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  void notifyListeners() {
    for (VoidCallback listener in listeners) {
      listener.call();
    }
  }
}
