import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> networkAvailable = ValueNotifier(true);

class NetworkActionButton extends StatelessWidget {
  const NetworkActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: networkAvailable,
      builder: (context, value, child) => !value && child != null ? child : const SizedBox.shrink(),
      child: ActionButton(Icons.mobiledata_off_outlined, tooltip: Language.of(context).network_error, onPressed: () {
        context.dispatchNotification(NetworkNotification(true));
        Api.get("/ping").then((value) {
          if (value?['ok'] ?? false) {
            networkAvailable.value = true;
            context.findAncestorStateOfType<BaseRoute>()?.reload();
          }
        });
      }),
    );
  }

  static void notify(BuildContext context, bool network) {
    context.dispatchNotification(NetworkNotification(network));
  }
}

class NetworkListener extends StatelessWidget {
  final Widget child;
  final void Function(bool network) onNetwork;

  const NetworkListener({super.key, required this.onNetwork, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<NetworkNotification>(
      child: child,
      onNotification: (NetworkNotification notification) {
        onNetwork(notification.network);
        return false;
      },
    );
  }
}

class NetworkNotification extends Notification {
  final bool network;

  NetworkNotification(this.network);
}
