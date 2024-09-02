import 'package:engine/api/api.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/lists/lists_api.dart';
import 'package:engine/utils/platform/action.dart';
import 'package:engine/utils/routes.dart';
import 'package:flutter/material.dart';

class NoticesButton extends StatelessWidget {
  const NoticesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: Language.of(context).notifications,
      child: ValueListenableBuilder(
        valueListenable: UsersStore.currentUser,
        builder: (context, user, child) => IconButton(
          onPressed: () {
            if (user == null) {
              Navigator.pushNamed(context, "/profile");
              return;
            }
            NoticesView.view(context);
          },
          icon: getIcon(user?.data['notices']),
        ),
      ),
    );
  }

  Widget getIcon(int? notices) {
    if (notices == null) {
      return const Icon(Icons.notifications_off_outlined);
    }

    if (notices > 0) {
      return Row(children: [
        const Icon(Icons.notifications_active),
        const SizedBox(width: 3),
        Text(
          UsersStore.user!.data['notices'].toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ]);
    }
    return const Icon(Icons.notifications_none);
  }
}

class NoticesView extends StatefulWidget {
  const NoticesView({super.key});

  @override
  NoticesViewState createState() => NoticesViewState();

  static Future<dynamic> view(BuildContext context) {
    return Navigator.push(context, PageRouteEffects.slideLoad(const NoticesView()));
  }

  static bool isNoticesView(BuildContext context) {
    if (context is StatefulElement && context.state is NoticesViewState) {
      return true;
    }
    return context.findAncestorStateOfType<NoticesViewState>() != null;
  }
}

class NoticesViewState extends BaseRoute<NoticesView> {
  @override
  Future<void> beforeLoad(AppLocalizations locale) async {
    await super.beforeLoad(locale);
  }

  @override
  Widget getBody() {
    return ApiListView(
      request: (paging) async {
        return Result(await Api.get("/notices", paging: paging));
      },
      getView: (context, item, index) {
        return Column(
          children: [Text("index $index"), Text(item.toString())],
        );
      },
    );
  }

  @override
  List<ActionMenuItem> getBaseActionsMenu() {
    return [];
  }

  @override
  String? getTitle() {
    return Language.of(context).notifications;
  }
}
