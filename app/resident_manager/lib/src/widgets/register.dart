import "dart:async";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../core/translations.dart";
import "../core/models/auth.dart";
import "../core/models/info.dart";
import "../core/models/reg_request.dart";

class RegisterPage extends StateAwareWidget {
  const RegisterPage({super.key, required super.state});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends AbstractCommonState<RegisterPage> with CommonStateMixin<RegisterPage> {
  final _name = TextEditingController();
  final _room = TextEditingController();
  final _birthday = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  final _actionLock = Lock();
  Widget _notification = const SizedBox.square(dimension: 0);

  final _formKey = GlobalKey<FormState>();

  Future<void> _handle() async {
    await _actionLock.run(
      () async {
        final check = _formKey.currentState?.validate();
        if (check == null || !check) {
          return;
        }

        _notification = Text(AppLocale.Loading.getString(context), style: const TextStyle(color: Colors.blue));
        refresh();

        final name = _name.text;
        final room = int.parse(_room.text);
        final birthday = _birthday.text.isEmpty ? null : DateTime.tryParse(_birthday.text);
        final phone = _phone.text;
        final email = _email.text;
        final username = _username.text;
        final password = _password.text;

        try {
          final result = await RegisterRequest.create(
            state: state,
            info: PersonalInfo(
              name: name,
              room: room,
              birthday: birthday,
              phone: phone,
              email: email,
            ),
            authorization: Authorization(username: username, password: password),
          );

          if (result == 204) {
            _notification = Text(
              mounted ? AppLocale.SuccessfullyRegisteredWaitForAdmin.getString(context) : AppLocale.SuccessfullyRegisteredWaitForAdmin,
              style: const TextStyle(color: Colors.blue),
            );
          } else {
            _notification = Text(
              mounted ? AppLocale.CheckInputAgain.getString(context) : AppLocale.CheckInputAgain,
              style: const TextStyle(color: Colors.red),
            );
          }
        } catch (e) {
          if (e is SocketException || e is TimeoutException) {
            _notification = Text(
              mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError,
              style: const TextStyle(color: Colors.red),
            );
          } else {
            rethrow;
          }
        }

        refresh();
      },
    );
  }

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.orientation == Orientation.landscape ? 0.25 * mediaQuery.size.width : 20.0;

    RichText fieldLabel(String label, {bool required = false}) => RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black),
            children: required ? const [TextSpan(text: " *", style: TextStyle(color: Colors.red))] : [],
          ),
        );

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.how_to_reg_outlined),
        ),
        title: Text(AppLocale.Register.getString(context)),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding, right: padding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Fullname.getString(context), required: true),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocale.MissingName.getString(context);
                  }

                  if (value.length > 255) {
                    return AppLocale.InvalidNameLength.getString(context);
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _room,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Room.getString(context), required: true),
                ),
                validator: (value) {
                  final roomInt = value == null ? null : int.tryParse(value);
                  if (roomInt == null) {
                    return AppLocale.MissingRoomNumber.getString(context);
                  }

                  if (roomInt < 0 || roomInt > 32767) {
                    return AppLocale.InvalidRoomNumber.getString(context);
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _birthday,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.DateOfBirth.getString(context)),
                ),
                onTap: () async {
                  final birthday = await showDatePicker(
                    context: context,
                    firstDate: DateTime.utc(1900),
                    lastDate: DateTime.now(),
                  );

                  if (birthday != null) {
                    _birthday.text = birthday.toIso8601String();
                  } else {
                    _birthday.clear();
                  }
                },
                readOnly: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (DateTime.tryParse(value) == null) {
                      return AppLocale.InvalidDateOfBirth.getString(context);
                    }
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Phone.getString(context)),
                ),
                validator: (value) {
                  if (value != null) {
                    if (value.length > 15) {
                      return AppLocale.InvalidPhoneNumber.getString(context);
                    }
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Email.getString(context)),
                ),
                validator: (value) {
                  if (value != null) {
                    if (value.length > 255) {
                      return AppLocale.InvalidEmail.getString(context);
                    }
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Username.getString(context), required: true),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocale.MissingUsername.getString(context);
                  }

                  if (value.length > 255) {
                    return AppLocale.InvalidUsernameLength.getString(context);
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: fieldLabel(AppLocale.Password.getString(context), required: true),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocale.MissingPassword.getString(context);
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
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(AppLocale.Register.getString(context)),
                  onPressed: _actionLock.locked ? null : _handle,
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
