import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../core/state.dart";
import "../core/translations.dart";

class LoginPage extends StateAwareWidget {
  @override
  final ApplicationState state;

  const LoginPage({super.key, required this.state});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with CommonStateMixin<LoginPage> {
  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final username = TextEditingController();
    final password = TextEditingController();

    Future<void> residentLogin() async {
      print(username.text);
      print(password.text);
    }

    Future<void> residentRegister() async {
      print(username.text);
      print(password.text);
    }

    Future<void> adminLogin() async {
      print(username.text);
      print(password.text);
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.lock_outlined),
        ),
        title: Text(AppLocale.Login.getString(context)),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 0.25 * mediaQuery.size.width,
          right: 0.25 * mediaQuery.size.width,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                autofocus: true,
                controller: username,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Username.getString(context)),
                ),
              ),
              TextField(
                controller: password,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Password.getString(context)),
                ),
                obscureText: true,
                onSubmitted: (_) => residentLogin(),
              ),
              const SizedBox.square(dimension: 10),
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.login_outlined),
                  label: Text(AppLocale.LoginAsResident.getString(context)),
                  onPressed: residentLogin,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.how_to_reg_outlined),
                  label: Text(AppLocale.RegisterAsResident.getString(context)),
                  onPressed: residentRegister,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: Text(AppLocale.LoginAsAdministrator.getString(context)),
                  onPressed: adminLogin,
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
