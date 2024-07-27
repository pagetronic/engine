import 'package:engine/api/api.dart';
import 'package:engine/blobs/images.dart';
import 'package:engine/data/settings.dart';
import 'package:engine/lng/language.dart';
import 'package:engine/profile/auth/users.dart';
import 'package:engine/utils/base.dart';
import 'package:engine/utils/main.dart';
import 'package:engine/utils/platform/views.dart';
import 'package:engine/utils/routes.dart';
import 'package:engine/utils/text.dart';
import 'package:engine/utils/toast.dart';
import 'package:engine/utils/url/url.dart';
import 'package:engine/utils/web/web.dart';
import 'package:engine/utils/widgets/form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthView extends StatelessWidget {
  final BaseRoute main;
  final bool register;

  const AuthView(this.main, {super.key, this.register = true});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UsersStore.currentUser,
      builder: (context, user, child) {
        bool smallBack = false;
        Widget? view;
        return LayoutBuilder(
          builder: (context, constraints) {
            bool small = constraints.maxWidth < 1000;
            if (view != null && smallBack == small) {
              return view!;
            }
            List<Widget> columns = [
              Container(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: small ? 0 : 10),
                decoration: BoxDecoration(
                    border: !small ? const Border(right: BorderSide(width: 1, color: Colors.grey)) : null),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (UsersStore.users.isNotEmpty) ...[
                      AuthBox(OthersUsers(loading: main.loading, reload: main.reload),
                          padding: small ? null : EdgeInsets.all(constraints.maxWidth * 30 / 1200)),
                      const DividerWidget(),
                    ],
                    AuthBox(OauthWidget(loading: main.loading, doneLogin: doneLogin),
                        padding: small ? null : EdgeInsets.all(constraints.maxWidth * 30 / 1200)),
                    const DividerWidget(),
                    AuthBox(LoginWidget(loading: main.loading, doneLogin: doneLogin),
                        padding: small ? null : EdgeInsets.all(constraints.maxWidth * 30 / 1200)),
                    if (small) const DividerWidget(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: small ? 0 : 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AuthBox(RegisterWidget(loading: main.loading, doneLogin: doneLogin),
                        padding: small ? null : EdgeInsets.all(constraints.maxWidth * 50 / 1200)),
                    const DividerWidget(),
                    AuthBox(RecoverWidget(loading: main.loading),
                        padding: small ? null : EdgeInsets.all(constraints.maxWidth * 50 / 1200)),
                  ],
                ),
              ),
            ];
            Widget body = small
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columns,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (Widget widget_ in columns) Flexible(child: widget_)],
                  );

            view = BaseView(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: small ? 5 : 0),
              maxWidth: 1500,
              children: [
                body,
              ],
            );
            smallBack = small;
            return view!;
          },
        );
      },
    );
  }

  Future<void> doneLogin(Function unload) async {
    String? referer =
        (RouteSettingsSaver.routeSettings(main.context)?.arguments as Map?)?['referer'] ?? history.lastBefore;
    if (referer != null) {
      Navigator.pushNamed(main.context, referer);
      return;
    }
    unload();
  }
}

class AuthBox extends StatelessWidget {
  final EdgeInsets? padding;
  final Widget child;

  const AuthBox(this.child, {super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding != null ? padding! : const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
      child: child,
    );
  }
}

class OthersUsers extends StatelessWidget {
  final void Function(bool loading, [Function()? dismiss]) loading;
  final void Function() reload;

  const OthersUsers({super.key, required this.loading, required this.reload});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          H3(Language.of(context).profile_others, textAlign: TextAlign.left),
          const SizedBox(height: 10),
          for (int i = 0; i < UsersStore.users.length; i++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i > 0) const DividerWidget(spacing: 8),
                InkWell(
                  customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onTap: () {
                    loading(true);
                    UsersStore.activate(UsersStore.users[i].id).then((value) => loading(false));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            if (UsersStore.users[i].data['avatar'] != null)
                              ImageWidget.src(UsersStore.users[i].data['avatar'], format: ImageFormat.png32x32)
                            else
                              const Icon(Icons.person, size: 32),
                          ],
                        ),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            H5(UsersStore.users[i].data['name']),
                            Label(UsersStore.users[i].data['pseudo'] ?? UsersStore.users[i].id),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (UsersStore.users[i].data['original'] != null)
                  InkWell(
                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    onTap: () {
                      loading(true);
                      UsersStore.switchUser(null, UsersStore.users[i].session).then(
                        (ok) {
                          loading(false);
                          if (ok) {
                            reload();
                          } else {
                            Messager.toast(context, Language.of(context).unknown_error);
                          }
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 21, right: 10),
                      child: Row(
                        children: [
                          UsersStore.users[i].data['original'].first['avatar'] != null
                              ? ImageWidget.src(UsersStore.users[i].data['original']?.first['avatar'],
                                  format: ImageFormat.png16x16)
                              : const Icon(Icons.person, size: 16),
                          const SizedBox(width: 3),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label(UsersStore.users[i].data['original'].first['name']),
                              Small(UsersStore.users[i].data['original'].first['pseudo'] ?? UsersStore.users[i].id),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if ((UsersStore.users[i].data['children'] ?? []).isNotEmpty)
              Container(
                padding: const EdgeInsets.only(left: 8),
                margin: const EdgeInsets.only(left: 18, top: 0, bottom: 10),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (Json subUser in UsersStore.users[i].data['children'])
                      InkWell(
                        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onTap: () {
                          loading(true);
                          UsersStore.switchUser(subUser.id!, UsersStore.users[i].session).then(
                            (ok) {
                              loading(false);
                              if (ok) {
                                reload();
                              } else {
                                Messager.toast(context, Language.of(context).unknown_error);
                              }
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if (subUser['avatar'] != null)
                                ImageWidget.src(subUser['avatar'], format: ImageFormat.png24x24)
                              else
                                const Icon(Icons.person, size: 24),
                              const SizedBox(width: 3),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Label(subUser['name'], softWrap: true),
                                  Small(subUser['pseudo'] ?? subUser.id, softWrap: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
          ],
        ],
      ),
    );
  }
}

class OauthWidget extends StatelessWidget {
  final void Function(bool loading, [Function()? dismiss]) loading;
  final Future<void> Function(Function unload) doneLogin;

  const OauthWidget({super.key, required this.loading, required this.doneLogin});

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);

    oAuthLogin(BuildContext context, String type) async {
      bool aborted = false;
      loading(true, () {
        aborted = true;
      });
      String? code;
      verify() async {
        await Future.delayed(const Duration(seconds: 3));
        if (aborted) return;

        Json? sessionData = await Api.post(
            "/oauth",
            Json({
              "action": "oauth_verify",
              "code": code,
            }),
            anonymous: true);
        if (sessionData?['session'] != null) {
          await Users.putSession(sessionData!['session']);
          doneLogin(() => loading(false));
          return;
        }
        if (sessionData?['await'] ?? false) {
          verify();
        } else {
          loading(false);
        }
      }

      Json? oauth = await Api.post(
          "/oauth",
          Json({
            "action": "oauth_url",
            "provider": "google",
            if (kIsWeb) 'redirect': WebData.getLocation(),
          }));
      if (oauth != null) {
        code = oauth['code'];
        UrlOpener.open(oauth['url']).then((value) => verify());
      }
    }

    List<Widget> children = [];
    children.add(H3(locale.profile_login_oauth, textAlign: TextAlign.left));
    children.add(const SizedBox(height: 5));
    children.add(Text(locale.profile_login_oauth_explain, style: const TextStyle(fontSize: 12)));
    children.add(const SizedBox(height: 14));
    children.add(Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
            child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 20,
          runSpacing: 20,
          runAlignment: WrapAlignment.center,
          children: [
            FilledButton.tonalIcon(
              icon: Image.asset("packages/engine/assets/oauth/google.png"),
              onPressed: () => oAuthLogin(context, "Google"),
              label: Text(
                locale.profile_login_oauth_google,
              ),
            ),
          ],
        ))
      ],
    ));
    return Column(
        mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class LoginWidget extends StatelessWidget {
  final void Function(bool loading, [Function()? dismiss]) loading;
  final Future<void> Function(Function unload) doneLogin;

  const LoginWidget({super.key, required this.loading, required this.doneLogin});

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    List<Widget> children = [];
    children.add(H3(locale.profile_login));
    children.add(const SizedBox(height: 10));

    Input? email;
    Input? password;

    loginAction() {
      TextInput.finishAutofillContext();
      email!.error(null, locale);
      password!.error(null, locale);
      bool error = false;
      if (email.value.isEmpty) {
        email.error("EMPTY", locale);
        error = true;
      }
      if (password.value.isEmpty) {
        password.error("EMPTY", locale);
        error = true;
      }
      if (error) {
        return;
      }

      loading(true);

      Api.post("/auth", Json({"action": "login", "email": email.value, "password": password.value})).then(
        (session) async {
          if (session != null && session['session'] != null) {
            await Users.putSession(session['session']);
          }
          loading(false);
          return null;
        },
      );
    }

    email = Input(
      locale.profile_login_email,
      onSubmit: (value) => loginAction(),
      autofillHints: const [AutofillHints.email],
    );

    SettingsStore.get("email", email.controller.value.text).then((value) {
      email!.controller.text = value;
      email.controller.addListener(() {
        SettingsStore.set("email", email!.controller.value.text);
      });
    });
    children.add(email);
    children.add(const SizedBox(height: 10));
    password = Input(locale.profile_login_password,
        obscureText: true, autofillHints: const [AutofillHints.password], onSubmit: (value) => loginAction());
    children.add(password);
    children.add(const SizedBox(height: 10));
    children.add(FilledButton(
      onPressed: loginAction,
      child: Text(locale.login),
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class RegisterWidget extends StatelessWidget {
  final Future<void> Function(Function unload) doneLogin;
  final void Function(bool loading, [Function()? dismiss]) loading;

  const RegisterWidget({super.key, required this.loading, required this.doneLogin});

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    List<Widget> children = [];
    children.add(H3(locale.profile_login_register));
    children.add(const SizedBox(height: 10));
    Input name = Input(locale.profile_login_register_name, autofillHints: const [AutofillHints.username]);
    children.add(name);
    children.add(const SizedBox(height: 10));
    Input email = Input(locale.profile_login_register_email, autofillHints: const [AutofillHints.email]);
    children.add(email);
    children.add(const SizedBox(height: 10));
    Input password = Input(
        obscureText: true, locale.profile_login_register_password, autofillHints: const [AutofillHints.newPassword]);
    children.add(password);
    children.add(const SizedBox(height: 10));
    children.add(FilledButton(
      onPressed: () {
        TextInput.finishAutofillContext();
        bool error = false;

        name.error(null, locale);
        email.error(null, locale);
        password.error(null, locale);

        if (name.value.isEmpty) {
          name.error("EMPTY", locale);
          error = true;
        }
        if (email.value.isEmpty) {
          email.error("EMPTY", locale);
          error = true;
        }
        if (password.value.isEmpty) {
          password.error("EMPTY", locale);
          error = true;
        }
        if (error) {
          return;
        }
        loading(true);
        Api.post(
                "/profile",
                Json(
                  {
                    "action": "register",
                    "name": name.value,
                    "email": email.value,
                    "password": password.value,
                  },
                ),
                anonymous: true)
            .then((rez) async {
          if (rez?['session'] != null) {
            await Users.putSession(rez!['session']);
            await doneLogin(() => loading(false));
          } else {
            loading(false);
            name.error(rez?['errors']?['name'], locale);
            email.error(rez?['errors']?['email'], locale);
            password.error(rez?['errors']?['password'], locale);

            Messager.toast(context, locale.profile_login_register_error);
          }
        });
      },
      child: Text(locale.profile_login_register_submit),
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class RecoverWidget extends StatelessWidget {
  final void Function(bool loading, [Function()? dismiss]) loading;

  const RecoverWidget({super.key, required this.loading});

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    List<Widget> children = [];
    children.add(H3(locale.profile_login_recover));
    children.add(const SizedBox(height: 10));
    Input? email;

    recoverAction() {
      TextInput.finishAutofillContext();
      bool aborted = false;
      loading(
        true,
        () {
          aborted = true;
        },
      );
      Api.post("/profile", Json({"action": "recover", "email": email!.value}), anonymous: true).then((rez) {
        if (aborted) {
          return;
        }
        loading(false);
        if (rez != null) {
          if (rez['ok'] ?? false) {
            Messager.toast(context, locale.profile_login_recover_watch);
          } else if (rez['error'] == 'UNKNOWN_USER') {
            Messager.toast(context, locale.profile_login_recover_error);
          } else {
            Messager.toast(context, locale.unknown_error);
          }
        } else {
          Messager.toast(context, locale.unknown_error);
        }
      });
    }

    email = Input(locale.profile_login_recover_email,
        onSubmit: (value) => recoverAction(), autofillHints: const [AutofillHints.email]);
    children.add(email);

    SettingsStore.get("email", email.controller.value.text).then((value) {
      email!.controller.text = value;
      email.controller.addListener(() {
        SettingsStore.set("email", email!.controller.value.text);
      });
    });
    children.add(const SizedBox(height: 10));
    children.add(FilledButton(
      onPressed: recoverAction,
      child: Text(locale.profile_login_recover_submit),
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class ChangePasswordWidget extends StatelessWidget {
  final void Function(bool loading, [Function()? dismiss]) loading;
  final void Function() done;
  final String? activation;

  const ChangePasswordWidget({super.key, required this.loading, required this.done, this.activation});

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = Language.of(context);
    List<Widget> children = [];
    children.add(H3(locale.profile_change_password));
    children.add(const SizedBox(height: 10));

    Input? password;
    if (activation == null) {
      password = Input(locale.profile_login_register_current_password,
          obscureText: true, autofillHints: const [AutofillHints.password]);
      children.add(password);
      children.add(const SizedBox(height: 30));
    }

    Input newPassword = Input(locale.profile_login_register_new_password,
        obscureText: true, autofillHints: const [AutofillHints.newPassword]);
    Input passwordRepeat = Input(locale.profile_login_register_repeat_new_password,
        obscureText: true, autofillHints: const [AutofillHints.newPassword]);
    children.add(AutofillGroup(child: Column(children: [newPassword, const SizedBox(height: 10), passwordRepeat])));

    children.add(const SizedBox(height: 15));

    children.add(FilledButton.icon(
      icon: const Icon(Icons.key),
      label: Text(locale.profile_change_password_short),
      onPressed: () {
        TextInput.finishAutofillContext();
        bool error = false;

        password?.error(null, locale);
        newPassword.error(null, locale);
        passwordRepeat.error(null, locale);

        if (password != null && password.value.isEmpty) {
          password.error("EMPTY", locale);
          error = true;
        }
        if (newPassword.value.isEmpty) {
          newPassword.error("EMPTY", locale);
          error = true;
        } else if (newPassword.value.length < 5) {
          newPassword.error("TOO_SHORT", locale);
          error = true;
        } else if (passwordRepeat.value != newPassword.value) {
          passwordRepeat.error("DO_NOT_MATCH", locale);
          error = true;
        }
        if (error) {
          return;
        }

        bool aborted = false;
        loading(
          true,
          () => aborted = true,
        );
        Api.post(
            "/profile",
            Json({
              "action": "password",
              "key": password != null ? password.value : activation,
              "newPassword": newPassword.value
            })).then((rez) async {
          if (aborted) {
            return;
          }
          loading(false);
          if (rez?['ok'] ?? false) {
            password?.value = null;
            newPassword.value = null;
            passwordRepeat.value = null;
            Messager.toast(context, Language.of(context).profile_changed_password);
            Future.delayed(const Duration(seconds: 2)).then((value) => done());
          } else {
            Messager.toast(
                context,
                password != null
                    ? Language.of(context).profile_changed_password_invalid_password
                    : Language.of(context).profile_changed_password_invalid_key);
            newPassword.error(rez?['errors']?['password'], locale);
          }
        });
      },
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class DividerWidget extends StatelessWidget {
  final double spacing;

  const DividerWidget({super.key, this.spacing = 20});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing, horizontal: 10),
      child: const ColoredBox(
        color: Colors.grey,
        child: SizedBox(
          height: 1,
          width: double.infinity,
        ),
      ),
    );
  }
}
