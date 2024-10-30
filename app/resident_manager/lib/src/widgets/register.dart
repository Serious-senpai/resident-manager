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
        if (check ?? false) {
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
      body: DecoratedBox(
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
          padding: EdgeInsets.only(left: padding, right: padding),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Fullname.getString(context),
                      required: true,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => nameValidator(context, required: true, value: value),
                ),
                TextFormField(
                  controller: _room,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Room.getString(context),
                      required: true,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => roomValidator(context, required: true, value: value),
                ),
                TextFormField(
                  controller: _birthday,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    floatingLabelStyle: const TextStyle(color: Colors.white),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.DateOfBirth.getString(context),
                      style: const TextStyle(color: Colors.white),
                    ),
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
                  style: const TextStyle(color: Colors.white),
                ),
                TextFormField(
                  controller: _phone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Phone.getString(context),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => phoneValidator(context, value: value),
                ),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Email.getString(context),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => emailValidator(context, value: value),
                ),
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Username.getString(context),
                      required: true,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => usernameValidator(context, required: true, value: value),
                ),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.Password.getString(context),
                      required: true,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => passwordValidator(context, required: true, value: value),
                ),
                TextFormField(
                  controller: _passwordRetype,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8.0),
                    iconColor: Colors.white,
                    label: FieldLabel(
                      AppLocale.RetypePassword.getString(context),
                      required: true,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
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
                    icon: const Icon(Icons.how_to_reg_outlined, color: Colors.white),
                    label: Text(AppLocale.Register.getString(context), style: const TextStyle(color: Colors.white)),
                    onPressed: _actionLock.locked ? null : _handle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: createDrawer(context),
    );
  }
}
