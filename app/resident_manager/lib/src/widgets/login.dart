import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../routes.dart";
import "../utils.dart";
import "../core/translations.dart";

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

  Future<void> _login(bool isAdmin) async {
    await _actionLock.run(
      () async {
        _notification = Text(AppLocale.LoggingInEllipsis.getString(context), style: const TextStyle(color: Colors.blue));
        refresh();

        if (!context.mounted) {
          return;
        }

        final loggedInAs = AppLocale.LoggedInAs.getString(context);
        final invalidCredentials = AppLocale.InvalidCredentials.getString(context);

        final username = _username.text;

        bool authorized = false;
        try {
          authorized = await state.authorize(username: username, password: _password.text, isAdmin: isAdmin);
        } catch (_) {
          await showToastSafe(msg: mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
          return;
        }

        if (authorized) {
          await showToastSafe(msg: "$loggedInAs \"$username\"");

          if (mounted) {
            await Navigator.pushReplacementNamed(context, isAdmin ? ApplicationRoute.adminRegisterQueue : ApplicationRoute.home);
          }
        } else {
          _notification = Text(
            invalidCredentials,
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
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.lock_outlined),
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
                onSubmitted: (_) => _login(false),
              ),
              const SizedBox.square(dimension: 5),
              _notification,
              const SizedBox.square(dimension: 5),
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
