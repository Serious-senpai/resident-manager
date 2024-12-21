import "dart:async";
import "dart:convert";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../utils.dart";
import "../../routes.dart";
import "../../translations.dart";
import "../../utils.dart";

class ChangePasswordPage extends StateAwareWidget {
  const ChangePasswordPage({super.key, required super.state});

  @override
  AbstractCommonState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends AbstractCommonState<ChangePasswordPage> with CommonScaffoldStateMixin<ChangePasswordPage> {
  final _username = TextEditingController();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final _actionLock = Lock();
  Widget _notification = const SizedBox.shrink();

  Future<void> _updatePassword() => _actionLock.run(
        () async {
          _notification = Builder(
            builder: (context) => Text(
              AppLocale.Loading.getString(context),
              style: const TextStyle(color: Colors.blue),
            ),
          );
          refresh();

          try {
            final response = await state.post(
              "/api/v1/admin/password",
              body: json.encode(
                {
                  "username": _username.text,
                  "old_password": _oldPassword.text,
                  "new_password": _newPassword.text,
                },
              ),
              headers: {"Content-Type": "application/json"},
              authorize: false,
              retry: 0,
            );

            if (response.statusCode == 204) {
              // Authorization info updated. Logout.
              await state.deauthorize();
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
                await Navigator.pushReplacementNamed(context, ApplicationRoute.login);
              }
            } else {
              _notification = Builder(
                builder: (context) => Text(
                  AppLocale.InvalidCredentials.getString(context),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
          } catch (e) {
            if (e is SocketException || e is TimeoutException) {
              _notification = Builder(
                builder: (context) => Text(
                  AppLocale.ConnectionError.getString(context),
                  style: const TextStyle(color: Colors.red),
                ),
              );

              return;
            }

            rethrow;
          }

          refresh();
        },
      );

  @override
  CommonScaffold<ChangePasswordPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.ChangePassword.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: mediaQuery.size.width > ScreenWidth.MEDIUM ? 0.25 * mediaQuery.size.width : 20,
            right: mediaQuery.size.width > ScreenWidth.MEDIUM ? 0.25 * mediaQuery.size.width : 20,
            top: 20,
            bottom: 20,
          ),
          child: Center(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _username,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      iconColor: Colors.black,
                      label: FieldLabel(
                        AppLocale.Username.getString(context),
                        required: true,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    validator: (value) => usernameValidator(context, required: true, value: value),
                  ),
                  TextFormField(
                    controller: _oldPassword,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      iconColor: Colors.black,
                      label: FieldLabel(
                        AppLocale.OldPassword.getString(context),
                        required: true,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                  ),
                  TextFormField(
                    controller: _newPassword,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      iconColor: Colors.black,
                      label: FieldLabel(
                        AppLocale.NewPassword.getString(context),
                        required: true,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                    validator: (value) => passwordValidator(context, required: true, value: value),
                  ),
                  TextFormField(
                    controller: _confirmPassword,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8.0),
                      iconColor: Colors.black,
                      label: FieldLabel(
                        AppLocale.RetypePassword.getString(context),
                        required: true,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black),
                    validator: (value) {
                      if (value == null || value != _newPassword.text) {
                        return AppLocale.RetypePasswordDoesNotMatch.getString(context);
                      }

                      return null;
                    },
                  ),
                  const SizedBox.square(dimension: 5),
                  _notification,
                  const SizedBox.square(dimension: 5),
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.done_outlined, color: Colors.black),
                      label: Text(AppLocale.ChangePassword.getString(context), style: const TextStyle(color: Colors.black)),
                      onPressed: _actionLock.locked ? null : _updatePassword,
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
