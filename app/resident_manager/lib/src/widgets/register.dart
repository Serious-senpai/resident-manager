import "dart:async";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../translations.dart";
import "../utils.dart";
import "../models/auth.dart";
import "../models/info.dart";
import "../models/reg_request.dart";

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
  final _passwordRetype = TextEditingController();

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

        _notification = Builder(
          builder: (context) => Text(
            AppLocale.Loading.getString(context),
            style: const TextStyle(color: Colors.blue),
          ),
        );
        refresh();

        final name = _name.text;
        final room = int.parse(_room.text);
        final birthday = _birthday.text.isEmpty ? null : DateFormat.fromFormattedDate(_birthday.text);
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

          if (result.code == 0) {
            _notification = Builder(
              builder: (context) => Text(
                AppLocale.SuccessfullyRegisteredWaitForAdmin.getString(context),
                style: const TextStyle(color: Colors.blue),
              ),
            );
          } else {
            _notification = Builder(
              builder: (context) => Text(
                AppLocale.errorMessage(result.code).getString(context),
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

    return Scaffold(
      key: scaffoldKey,
      appBar: createAppBar(context, title: AppLocale.Register.getString(context)),
      body: Padding(
        padding: EdgeInsets.only(left: padding, right: padding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _name,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Fullname.getString(context), required: true),
                ),
                validator: (value) => nameValidator(context, required: true, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _room,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Room.getString(context), required: true),
                ),
                validator: (value) => roomValidator(context, required: true, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _birthday,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.DateOfBirth.getString(context)),
                ),
                onTap: () async {
                  final birthday = await showDatePicker(
                    context: context,
                    initialDate: DateFormat.fromFormattedDate(_birthday.text),
                    firstDate: DateTime.utc(1900),
                    lastDate: DateTime.now(),
                  );

                  if (birthday != null) {
                    _birthday.text = birthday.toLocal().formatDate();
                  } else {
                    _birthday.clear();
                  }
                },
                readOnly: true, // no need for validator
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _phone,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Phone.getString(context)),
                ),
                validator: (value) => phoneValidator(context, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _email,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Email.getString(context)),
                ),
                validator: (value) => emailValidator(context, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _username,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Username.getString(context), required: true),
                ),
                validator: (value) => usernameValidator(context, required: true, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _password,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Password.getString(context), required: true),
                ),
                obscureText: true,
                validator: (value) => passwordValidator(context, required: true, value: value),
              ),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _passwordRetype,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.RetypePassword.getString(context), required: true),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value != _password.text) {
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
