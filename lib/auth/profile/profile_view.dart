import 'package:engine/api/api.dart';
import 'package:engine/auth/auth_view.dart';
import 'package:engine/auth/profile/avatar.dart';
import 'package:engine/auth/users.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/platform/menu.dart';
import 'package:engine/utils/platform/views.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/web/web.dart';
import 'package:engine/utils/widgets/date.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

mixin ProfileViewBase<T extends StatefulWidget> on BaseRoute<T> {
  Json? activation;

  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    String? url = RouteSettingsSaver.routeSettings(context)?.name;
    if (url != null) {
      Uri uri = Uri.parse(url);
      if (activation == null && uri.queryParameters.containsKey('activate')) {
        String activate = uri.queryParameters['activate']!;
        WebData.setUrl("/profile");
        activation = await Api.post("/profile", Json({"action": "activate", "activate": activate}));
        if (activation?['session'] != null) {
          await Users.putSession(activation?['session']);
        }
      }
    }
    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    AppLocalizations locale = Language.of(context);
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, userStore, child) {
        Json? user = userStore?.data;
        if (user == null) {
          return AuthView(this);
        }

        return BaseView(children: [
          Container(constraints: const BoxConstraints(minWidth: 800), child: H1(locale.profile)),
          Wrap(
            runSpacing: 10,
            children: [
              Avatar(user['avatar'], format: ImageFormat.png164x164),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user['name'] != null) H2(user['name']),
                  H3(user['pseudo'] ?? user.id),
                  if (user['email'] != null) H4(user['email']),
                  if (user['join'] != null)
                    H5(DateFormat(null, Language.of(context).localeName).format(DateTime.parse(user['join']))),
                  if (user['join'] != null) H5(Since.formatSince(context, DateTime.parse(user['join']))),
                ],
              )
            ],
          ),
          const DividerWidget(spacing: 30),
          ChangePasswordWidget(
              activation: activation?['activation'],
              loading: loading,
              done: () {
                activation = null;
                reload();
              }),
          const DividerWidget(spacing: 30),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(icon: const Icon(Icons.logout), onPressed: logout, label: Text(locale.logout)),
              FilledButton.tonalIcon(
                  icon: const Icon(Icons.people_alt), onPressed: change, label: Text(locale.profile_user_change)),
            ],
          ),
          const SizedBox(height: 40),
        ]);
      },
    );
  }

  Future<void> change() async => kIsWeb ? UsersStore.activateWeb(userId: null) : UsersStore.activate(null);

  @override
  List<GlobalMenuItem>? getMenu() => getBaseMenu('profile');
}
