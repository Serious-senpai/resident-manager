import "dart:async";
import "dart:io";

import "package:async_locks/async_locks.dart";
import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../translations.dart";
import "../utils.dart";
import "../models/info.dart";

class PersonalInfoPage extends StateAwareWidget {
  const PersonalInfoPage({super.key, required super.state});

  @override
  PersonalInfoPageState createState() => PersonalInfoPageState();
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class PersonalInfoPageState extends AbstractCommonState<PersonalInfoPage> with CommonStateMixin<PersonalInfoPage> {
  final _name = TextEditingController();
  final _room = TextEditingController();
  final _birthday = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _newPassword = TextEditingController();
  final _newPasswordRetype = TextEditingController();

  final _generalFormKey = GlobalKey<FormState>();
  final _authFormKey = GlobalKey<FormState>();

  Widget _generalNotification = const SizedBox.square(dimension: 0);
  Widget _authNotification = const SizedBox.square(dimension: 0);

  final _actionLock = Lock();

  @override
  void initState() {
    super.initState();
    _name.text = state.resident?.name ?? "";
    _room.text = state.resident?.room.toString() ?? "";
    _birthday.text = state.resident?.birthday?.toLocal().formatDate() ?? "";
    _phone.text = state.resident?.phone ?? "";
    _email.text = state.resident?.email ?? "";
    _username.text = state.resident?.username ?? "";
  }

  Widget generalInfoForm(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final items = [
      _InfoCard(
        child: TextFormField(
          controller: _name,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.Fullname.getString(context),
              required: true,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          validator: (value) => nameValidator(context, required: true, value: value),
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _room,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.Room.getString(context),
              required: true,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          validator: (value) => roomValidator(context, required: true, value: value),
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _birthday,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.DateOfBirth.getString(context),
              style: const TextStyle(color: Colors.black),
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
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _phone,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.Phone.getString(context),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          validator: (value) => phoneValidator(context, value: value),
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _email,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.Email.getString(context),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          validator: (value) => emailValidator(context, value: value),
        ),
      ),
    ];

    final rows = mediaQuery.size.width < ScreenWidth.SMALL
        ? [
            [0],
            [1],
            [2],
            [3],
            [4],
          ]
        : [
            [0],
            [1, 2],
            [3, 4],
          ];

    return Form(
      key: _generalFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Text(
            AppLocale.GeneralInformation.getString(context),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...List<Widget>.from(
            rows.map(
              (row) => Row(
                children: List<Widget>.from(row.map((i) => items[i])),
              ),
            ),
          ),
          _generalNotification,
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.yellow,
                  ),
                  label: Text(
                    AppLocale.SaveGeneralInformation.getString(context),
                    style: const TextStyle(color: Colors.yellow),
                  ),
                  onPressed: _actionLock.locked
                      ? null
                      : () async {
                          await _actionLock.run(
                            () async {
                              _generalNotification = Builder(
                                builder: (context) => Text(
                                  AppLocale.Loading.getString(context),
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              );
                              refresh();

                              try {
                                final result = await state.resident?.update(
                                  state: state,
                                  info: PersonalInfo(
                                    name: _name.text,
                                    room: int.parse(_room.text),
                                    birthday: DateFormat.fromFormattedDate(_birthday.text),
                                    phone: _phone.text,
                                    email: _email.text,
                                  ),
                                );

                                if (result == null || result.code != 0) {
                                  _generalNotification = Builder(
                                    builder: (context) => Text(
                                      AppLocale.errorMessage(result?.code ?? -1).getString(context),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                } else {
                                  state.resident = result.data;
                                  _generalNotification = const SizedBox.square(dimension: 0);
                                }
                              } catch (e) {
                                await showToastSafe(msg: context.mounted ? AppLocale.ConnectionError.getString(context) : AppLocale.ConnectionError);
                                _generalNotification = Builder(
                                  builder: (context) => Text(
                                    AppLocale.ConnectionError.getString(context),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                );

                                if (!(e is SocketException || e is TimeoutException)) {
                                  rethrow;
                                }
                              } finally {
                                refresh();
                              }
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget authorizationInfoForm(BuildContext context) {
    final items = [
      _InfoCard(
        child: TextFormField(
          controller: _username,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.Username.getString(context),
              required: true,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          validator: (value) => usernameValidator(context, required: true, value: value),
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _newPassword,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.NewPassword.getString(context),
              required: true,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          obscureText: true,
          validator: (value) => passwordValidator(context, required: false, value: value),
        ),
      ),
      _InfoCard(
        child: TextFormField(
          controller: _newPasswordRetype,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(8.0),
            label: FieldLabel(
              AppLocale.RetypeNewPassword.getString(context),
              required: true,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null || value != _newPassword.text) {
              return AppLocale.RetypePasswordDoesNotMatch.getString(context);
            }

            return null;
          },
        ),
      ),
    ];

    return Form(
      key: _authFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Text(
            AppLocale.GeneralInformation.getString(context),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...List<Widget>.from(items.map((item) => Row(children: [item]))),
          _authNotification,
        ],
      ),
    );
  }

  @override
  CommonScaffold<PersonalInfoPage> build(BuildContext context) {
    return CommonScaffold(
      widgetState: this,
      title: Text(AppLocale.PersonalInfo.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              generalInfoForm(context),
              const SizedBox.square(dimension: 10),
              authorizationInfoForm(context),
            ],
          ),
        ),
      ),
    );
  }
}
