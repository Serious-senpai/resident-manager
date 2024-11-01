import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "state.dart";
import "../routes.dart";
import "../state.dart";
import "../translations.dart";

abstract class AbstractCommonState<T extends StateAwareWidget> extends State<T> {
  ApplicationState get state => widget.state;

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  @mustCallSuper
  void initState() {
    state.pushTranslationCallback((_) => refresh());
    super.initState();
  }

  @override
  @mustCallSuper
  void dispose() {
    state.popTranslationCallback();
    super.dispose();
  }
}

mixin CommonStateMixin<T extends StateAwareWidget> on AbstractCommonState<T> {
  @override
  CommonScaffold<T> build(BuildContext context);
}

class CommonScaffold<T extends StateAwareWidget> extends StatelessWidget {
  final CommonStateMixin<T> widgetState;
  final Widget title;
  final Widget body;

  /// The [GlobalKey] for the underlying [Scaffold]
  final scaffoldKey = GlobalKey<ScaffoldState>();

  CommonScaffold({
    super.key,
    required this.widgetState,
    required this.title,
    required this.body,
  });

  /// Open the [Scaffold.drawer]
  void openDrawer() {
    final state = scaffoldKey.currentState;
    if (state != null) state.openDrawer();
  }

  /// Close the [Scaffold.drawer]
  void closeDrawer() {
    final state = scaffoldKey.currentState;
    if (state != null) state.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        actions: [
          if (canPop)
            Padding(
              padding: const EdgeInsets.all(5),
              child: IconButton(
                onPressed: () => openDrawer(),
                icon: const Icon(Icons.menu_outlined),
              ),
            ),
        ],
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_outlined),
              )
            : IconButton(
                onPressed: () => openDrawer(),
                icon: const Icon(Icons.menu_outlined),
              ),
        title: title,
      ),
      body: body,
      drawer: Builder(
        builder: (context) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          final navigator = <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/vector-background-green.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: null,
            ),
          ];

          Widget routeTile({
            required Icon leading,
            required String title,
            required String route,
            required bool popAll,
          }) =>
              ListTile(
                leading: leading,
                title: Text(
                  title,
                  style: currentRoute == route ? const TextStyle(color: Colors.blue) : null,
                ),
                onTap: () {
                  closeDrawer();
                  if (currentRoute != route) {
                    if (popAll) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushReplacementNamed(context, route);
                    } else {
                      Navigator.pushNamed(context, route);
                    }
                  }
                },
              );

          if (!widgetState.state.loggedIn) {
            // Not yet logged in
            navigator.add(
              routeTile(
                leading: const Icon(Icons.lock_outlined),
                title: AppLocale.Login.getString(context),
                route: ApplicationRoute.login,
                popAll: true,
              ),
            );
          } else {
            // Logged in...
            if (widgetState.state.loggedInAsAdmin) {
              // ... as admin
              navigator.addAll(
                [
                  routeTile(
                    leading: const Icon(Icons.how_to_reg_outlined),
                    title: AppLocale.RegisterQueue.getString(context),
                    route: ApplicationRoute.adminRegisterQueue,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.people_outlined),
                    title: AppLocale.ResidentsList.getString(context),
                    route: ApplicationRoute.adminResidentsPage,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.room_outlined),
                    title: AppLocale.RoomsList.getString(context),
                    route: ApplicationRoute.adminRoomsPage,
                    popAll: false,
                  ),
                ],
              );
            } else {
              // ... as resident
              navigator.addAll(
                [
                  routeTile(
                    leading: const Icon(Icons.home_outlined),
                    title: AppLocale.Home.getString(context),
                    route: ApplicationRoute.home,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.person_outlined),
                    title: AppLocale.PersonalInfo.getString(context),
                    route: ApplicationRoute.personalInfo,
                    popAll: false,
                  ),
                ],
              );
            }

            navigator.add(
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: Text(AppLocale.Logout.getString(context)),
                onTap: () async {
                  await widgetState.state.deauthorize();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushReplacementNamed(context, ApplicationRoute.login);
                  }
                },
              ),
            );
          }

          return Drawer(
            child: Stack(
              children: [
                ListView(children: navigator),
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Image.asset("assets/flags/en.png", height: 20, width: 20),
                        iconSize: 20,
                        onPressed: () => widgetState.state.localization.translate("en"),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox.square(dimension: 20),
                      IconButton(
                        icon: Image.asset("assets/flags/vi.png", height: 20, width: 20),
                        iconSize: 20,
                        onPressed: () => widgetState.state.localization.translate("vi"),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
