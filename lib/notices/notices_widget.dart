import 'dart:async';

import 'package:engine/api/api.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/socket/channels.dart';
import 'package:engine/utils/buttons.dart';
import 'package:engine/utils/device/device.dart';
import 'package:engine/utils/natives.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class FollowButton extends StatelessWidget {
  final Channel channel;
  final double? size;

  const FollowButton(this.channel, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    if (UsersStore.user == null) {
      return const SizedBox.shrink();
    }

    final Future<bool> hasOsNotifications = this.hasOsNotifications();
    final Future<String?> deviceId = Device.uuid;
    final Future<String?> control = this.control(deviceId);

    return FutureBuilder(
      future: hasOsNotifications,
      builder: (context, hasOsNotifications) {
        return FutureBuilder(
          future: deviceId,
          builder: (context, snapshotDeviceId) {
            return FutureBuilder(
              future: control,
              builder: (context, snapshotControl) {
                if (snapshotControl.connectionState != ConnectionState.done ||
                    hasOsNotifications.connectionState != ConnectionState.done ||
                    snapshotDeviceId.connectionState != ConnectionState.done) {
                  return Opacity(
                      opacity: 0.4,
                      child: ButtonIcon(
                        size: size,
                        icon: Symbols.notifications_paused,
                      ));
                }

                bool capable = hasOsNotifications.data ?? false;
                String? type = snapshotControl.data;
                String? deviceId = snapshotDeviceId.data;
                return StatefulBuilder(
                  builder: (context, setState) {
                    return ButtonIcon(
                      opacity: type != null && type != 'off' ? 1 : null,
                      size: size,
                      onTapDown: (details) {
                        AppLocalizations locale = Language.of(context);
                        showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              details.globalPosition.dx,
                              details.globalPosition.dy,
                              details.globalPosition.dx,
                              details.globalPosition.dy,
                            ),
                            items: [
                              if (deviceId != null && capable && type != 'os')
                                PopupMenuItem<String>(
                                  value: "os",
                                  child: Row(
                                    children: [
                                      const Icon(Symbols.wifi_notification),
                                      const SizedBox(width: 5),
                                      Text(locale.notifications_os)
                                    ],
                                  ),
                                ),
                              if (type == 'off' || type == 'os')
                                PopupMenuItem<String>(
                                  value: "app",
                                  child: Row(
                                    children: [
                                      const Icon(Symbols.notifications_active),
                                      const SizedBox(width: 5),
                                      Text(locale.notifications_app)
                                    ],
                                  ),
                                ),
                              if (type != 'off')
                                PopupMenuItem<String>(
                                  value: "off",
                                  child: Row(
                                    children: [
                                      const Icon(Symbols.notifications_off),
                                      const SizedBox(width: 5),
                                      Text(locale.notifications_off)
                                    ],
                                  ),
                                )
                            ]).then(
                          (chosen) {
                            if (chosen != null) {
                              register(chosen, deviceId).then((_) => setState(() => type = chosen));
                            }
                          },
                        );
                      },
                      icon: type == 'os'
                          ? Symbols.wifi_notification
                          : type == 'app'
                              ? Symbols.notifications_active
                              : Symbols.notifications_off,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> hasOsNotifications() async {
    try {
      bool? hasWebPush = await MethodsCaller.native.invokeMethod<bool?>("hasOsNotifications");
      return hasWebPush ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> register(String? type, String? device) async {
    await Api.post(
        "/notices",
        Json({
          "action": 'subscribe',
          'channel': channel,
          'type': type,
          'device': device,
        }));
  }

  Future<String?> control(Future<String?> device) async {
    Json? control = await Api.post(
        "/notices",
        Json({
          'action': 'control',
          'channel': channel,
          'device': await device,
        }));
    return control?['type'] ?? 'off';
  }
}
