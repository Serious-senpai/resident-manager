import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "src/core/state.dart";
import "src/core/translations.dart";
import "src/widgets/state.dart";
import "src/widgets/common.dart";
import "src/widgets/login.dart";

class MainApplication extends StateAwareWidget {
  @override
  final ApplicationState state;

  const MainApplication({super.key, required this.state});

  @override
  MainApplicationState createState() => MainApplicationState();
}

class MainApplicationState extends State<MainApplication> with SupportsTranslation<MainApplication> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocale.ResidentManager.getString(context),
      routes: {
        "/login": (context) => LoginPage(state: widget.state),
      },
      initialRoute: "/login",
      localizationsDelegates: widget.state.localization.localizationsDelegates,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
        overscroll: false,
      ),
      supportedLocales: widget.state.localization.supportedLocales,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = ApplicationState();
  await state.prepare();

  runApp(MainApplication(state: state));
}
