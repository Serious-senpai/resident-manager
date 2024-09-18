import "package:flutter/material.dart";

import "drawer.dart";
import "../core/state.dart";

class LoginPage extends StatefulWidget {
  final ApplicationState state;

  const LoginPage({super.key, required this.state});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with PageStateWithDrawer<LoginPage> {
  @override
  Scaffold buildScaffold(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.lock_outlined),
        ),
        title: const Text("Login"),
      ),
      drawer: createDrawer(context: context, state: widget.state),
    );
  }
}
