import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../translations.dart";
import "../utils.dart";

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
  final _formKey = GlobalKey<FormState>();

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

  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: createAppBar(context, title: AppLocale.PersonalInfo.getString(context)),
      body: Builder(
        builder: (context) {
          final generalItems = [
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _name,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Fullname.getString(context), required: true),
                ),
                validator: (value) => nameValidator(context, required: true, value: value),
              ),
            ),
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _room,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Room.getString(context), required: true),
                ),
                validator: (value) => roomValidator(context, required: true, value: value),
              ),
            ),
            _InfoCard(
              child: TextFormField(
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
            ),
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _phone,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Phone.getString(context)),
                ),
                validator: (value) => phoneValidator(context, value: value),
              ),
            ),
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _email,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Email.getString(context)),
                ),
                validator: (value) => emailValidator(context, value: value),
              ),
            ),
          ];

          final generalRows = mediaQuery.size.width < ScreenWidth.SMALL
              ? [
                  [0],
                  [1],
                  [2],
                  [3],
                  [4],
                ]
              : mediaQuery.size.width < ScreenWidth.MEDIUM
                  ? [
                      [0],
                      [1, 2],
                      [3, 4],
                    ]
                  : [
                      [0, 1, 2, 3, 4],
                    ];

          final authorizationItems = [
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _username,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.Username.getString(context), required: true),
                ),
                validator: (value) => usernameValidator(context, value: value),
              ),
            ),
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _newPassword,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.NewPassword.getString(context), required: true),
                ),
                obscureText: true,
                validator: (value) => passwordValidator(context, value: value),
              ),
            ),
            _InfoCard(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _newPasswordRetype,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: FieldLabel(AppLocale.RetypeNewPassword.getString(context), required: true),
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

          final children = [
            Text(
              AppLocale.GeneralInformation.getString(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List<Widget>.from(
              generalRows.map(
                (row) => Row(
                  children: List<Widget>.from(
                    row.map(
                      (i) => generalItems[i],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox.square(dimension: 10),
            Text(
              AppLocale.AuthorizationInformation.getString(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...List<Widget>.from(authorizationItems.map((item) => Row(children: [item])))
          ];

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: List<Widget>.from(
                  children.map(
                    (w) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: w,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      drawer: createDrawer(context),
    );
  }
}
