import "dart:async";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../routes.dart";
import "../translations.dart";
import "../utils.dart";

class LoginPage extends StateAwareWidget {
  const LoginPage({super.key, required super.state});

  @override
  AbstractCommonState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends AbstractCommonState<LoginPage> with CommonStateMixin<LoginPage> {
  final _actionLock = Lock();
  Widget _notification = const SizedBox.square(dimension: 0);

  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;

  Future<void> _login(bool isAdmin) async {
    await _actionLock.run(
      () async {
        _notification = Builder(
          builder: (context) => Text(
            AppLocale.LoggingInEllipsis.getString(context),
            style: const TextStyle(color: Colors.blue),
          ),
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
            _notification = Builder(
              builder: (context) => Text(
                AppLocale.ConnectionError.getString(context),
                style: const TextStyle(color: Colors.red),
              ),
            );

            refresh();
            return;
          }

          rethrow;
        }

        if (authorized) {
          await showToastSafe(msg: "${mounted ? AppLocale.LoggedInAs.getString(context) : AppLocale.LoggedInAs} \"$username\"");

          if (mounted) {
            await Navigator.pushReplacementNamed(context, isAdmin ? ApplicationRoute.adminHomePage : ApplicationRoute.home);
          }
        } else {
          _notification = Builder(
            builder: (context) => Text(
              AppLocale.InvalidCredentials.getString(context),
              style: const TextStyle(color: Colors.red),
            ),
          );

          refresh();
        }
      },
    );
  }

  Future<void> _residentRegister() async {
    await pushNamedAndRefresh(context, ApplicationRoute.register);
  }

  @override
  CommonScaffold<LoginPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Login.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: SliverFillRemaining(
        hasScrollBody: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage("assets/luxury-apartment.webp"),
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7),
                BlendMode.srcOver,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: mediaQuery.size.width > ScreenWidth.MEDIUM ? 0.25 * mediaQuery.size.width : 20,
              right: mediaQuery.size.width > ScreenWidth.MEDIUM ? 0.25 * mediaQuery.size.width : 20,
              top: 20,
              bottom: 20,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _username,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      label: Text(
                        AppLocale.Username.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    enabled: !_actionLock.locked,
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    controller: _password,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      label: Text(
                        AppLocale.Password.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    enabled: !_actionLock.locked,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
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
                      Text(
                        AppLocale.RememberMe.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox.square(dimension: 5),
                  _notification,
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.login_outlined, color: Colors.white),
                      label: Text(
                        AppLocale.LoginAsResident.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _actionLock.locked ? null : () => _login(false),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.how_to_reg_outlined, color: Colors.white),
                      label: Text(
                        AppLocale.RegisterAsResident.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _actionLock.locked ? null : () => _residentRegister(),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                      label: Text(
                        AppLocale.LoginAsAdministrator.getString(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: _actionLock.locked ? null : () => _login(true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
