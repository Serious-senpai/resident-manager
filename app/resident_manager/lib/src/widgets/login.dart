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
    final padding = mediaQuery.size.width * 0.25;
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
        padding: EdgeInsets.only(left: padding, right: padding),
        child: Center(
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Username.getString(context)),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8.0),
                  label: Text(AppLocale.Password.getString(context)),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      drawer: createDrawer(context),
    );
  }
}
