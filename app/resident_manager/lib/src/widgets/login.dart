import "dart:async";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "utils.dart";
import "../routes.dart";
import "../translations.dart";
import "../utils.dart";

class LoginPage extends StateAwareWidget {
  const LoginPage({super.key, required super.state});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends AbstractCommonState<LoginPage> with CommonStateMixin<LoginPage> {
  final _actionLock = Lock();
  Widget _notification = const SizedBox.square(dimension: 0);

  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;

  Future<void> _login(bool isAdmin) async {
    await _actionLock.run(
      () async {
        _notification = TranslatedText(
          (ctx) => AppLocale.LoggingInEllipsis.getString(ctx),
          state: state,
          style: const TextStyle(color: Colors.blue),
        );
        refresh();

        final username = _username.text;

        var authorized = false;
        try {
          authorized = await state.authorize(
            username: username,
            password: _password.text,
            isAdmin: isAdmin,
            remember: _remember,
          );
        } catch (e) {
          if (e is SocketException || e is TimeoutException) {
            _notification = TranslatedText(
              (ctx) => AppLocale.ConnectionError.getString(ctx),
              state: state,
              style: const TextStyle(color: Colors.red),
            );

            refresh();
            return;
          }

          rethrow;
        }

        if (authorized) {
          await showToastSafe(msg: "${mounted ? AppLocale.LoggedInAs.getString(context) : AppLocale.LoggedInAs} \"$username\"");

          if (mounted) {
            await Navigator.pushReplacementNamed(context, isAdmin ? ApplicationRoute.adminRegisterQueue : ApplicationRoute.home);
          }
        } else {
          _notification = TranslatedText(
            (ctx) => AppLocale.InvalidCredentials.getString(ctx),
            state: state,
            style: const TextStyle(color: Colors.red),
          );

          refresh();
        }
      },
    );
  }

  Future<void> _residentRegister() async {
    await Navigator.pushReplacementNamed(context, ApplicationRoute.register);
  }

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.orientation == Orientation.landscape ? 0.25 * mediaQuery.size.width : 20.0;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.menu_outlined),
        ),
        title: Text(AppLocale.Login.getString(context)),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding, right: padding),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                autofocus: true,
                controller: _username,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Username.getString(context)),
                ),
                enabled: !_actionLock.locked,
              ),
              TextField(
                controller: _password,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Password.getString(context)),
                ),
                enabled: !_actionLock.locked,
                obscureText: true,
              ),
              const SizedBox.square(dimension: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox.adaptive(
                    value: _remember,
                    onChanged: (state) {
                      if (state != null) {
                        _remember = state;
                      }

                      refresh();
                    },
                  ),
                  Text(AppLocale.RememberMe.getString(context)),
                ],
              ),
              const SizedBox.square(dimension: 5),
              _notification,
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.login_outlined),
                  label: Text(AppLocale.LoginAsResident.getString(context)),
                  onPressed: _actionLock.locked ? null : () => _login(false),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(AppLocale.RegisterAsResident.getString(context)),
                  onPressed: _actionLock.locked ? null : () => _residentRegister(),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(AppLocale.LoginAsAdministrator.getString(context)),
                  onPressed: _actionLock.locked ? null : () => _login(true),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: createDrawer(context),
    );
  }
}
