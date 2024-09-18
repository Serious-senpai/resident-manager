import "package:flutter/material.dart";

import "src/core/state.dart";
import "src/widgets/login.dart";

class MainApplication extends StatelessWidget {
  final ApplicationState state;

  const MainApplication({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Resident manager",
      routes: {
        "/login": (context) => LoginPage(state: state),
      },
      initialRoute: "/login",
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
        overscroll: false,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = ApplicationState();
  await state.prepare();

  runApp(MainApplication(state: state));
}
