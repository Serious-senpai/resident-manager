import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "src/core/state.dart";
import "src/core/translations.dart";
import "src/widgets/state.dart";
import "src/widgets/common.dart";
import "src/widgets/home.dart";
import "src/widgets/login.dart";
import "src/widgets/admin/reg_queue.dart";

class MainApplication extends StateAwareWidget {
  const MainApplication({super.key, required super.state});

  @override
  MainApplicationState createState() => MainApplicationState();
}

class MainApplicationState extends AbstractCommonState<MainApplication> {
  @override
  Widget build(BuildContext context) {
    final authorization = state.authorization;
    String initialRoute = "/login";
    if (authorization != null) {
      initialRoute = authorization.isAdmin ? "/admin/register-queue" : "/home";
    }

    return MaterialApp(
      title: AppLocale.ResidentManager.getString(context),
      routes: {
        "/login": (context) => LoginPage(state: state),
        "/home": (context) => HomePage(state: state),
        "/admin/register-queue": (context) => RegisterQueuePage(state: state),
      },
      initialRoute: initialRoute,
      localizationsDelegates: state.localization.localizationsDelegates,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
        overscroll: false,
      ),
      supportedLocales: state.localization.supportedLocales,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = ApplicationState();
  await state.prepare();

  runApp(MainApplication(state: state));
}
