import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:meta/meta.dart";

import "state.dart";
import "../routes.dart";
import "../state.dart";
import "../translations.dart";

abstract class AbstractCommonState<T extends StateAwareWidget> extends State<T> {
  ApplicationState get state => widget.state;

  void refresh() {
    if (mounted) {
      setState(() {});
    }
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
  /// The [GlobalKey] for the [Scaffold] returned by the [build] method
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether this route can be popped when pressing the "Back" button
  bool get canPop => true;

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

  AppBar createAppBar(BuildContext context, {Icon icon = const Icon(Icons.menu_outlined), required String title}) {
    return AppBar(
      leading: IconButton(
        onPressed: openDrawer,
        icon: icon,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  /// Create a default [Drawer] for all pages within this application
  Drawer createDrawer(BuildContext context) {
    var currentRoute = ModalRoute.of(context)?.settings.name;

    final navigator = <Widget>[
      const DrawerHeader(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/vector-background-green.jpg"), fit: BoxFit.cover)),
        child: null,
      ),
    ];

    Widget routeTile({
      required Icon leading,
      required String title,
      required String route,
    }) =>
        ListTile(
          leading: leading,
          title: Text(
            title,
            style: currentRoute == route ? const TextStyle(color: Colors.blue) : null,
          ),
          onTap: () => currentRoute == route
              ? Navigator.pop(context)
              : Navigator.pushReplacementNamed(
                  context,
                  route,
                ),
        );

    if (!state.loggedIn) {
      navigator.add(
        routeTile(
          leading: const Icon(Icons.lock_outlined),
          title: AppLocale.Login.getString(context),
          route: ApplicationRoute.login,
        ),
      );
    } else {
      if (state.loggedInAsAdmin) {
        navigator.addAll(
          [
            routeTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: AppLocale.RegisterQueue.getString(context),
              route: ApplicationRoute.adminRegisterQueue,
            ),
            routeTile(
              leading: const Icon(Icons.people_outlined),
              title: AppLocale.ResidentsList.getString(context),
              route: ApplicationRoute.adminResidentsPage,
            ),
            routeTile(
              leading: const Icon(Icons.room_outlined),
              title: AppLocale.RoomsList.getString(context),
              route: ApplicationRoute.adminRoomsPage,
            ),
          ],
        );
      } else {
        navigator.addAll(
          [
            routeTile(
              leading: const Icon(Icons.home_outlined),
              title: AppLocale.Home.getString(context),
              route: ApplicationRoute.home,
            ),
            routeTile(
              leading: const Icon(Icons.person_outlined),
              title: AppLocale.PersonalInfo.getString(context),
              route: ApplicationRoute.personalInfo,
            ),
          ],
        );
      }

      navigator.add(
        ListTile(
          leading: const Icon(Icons.logout_outlined),
          title: Text(AppLocale.Logout.getString(context)),
          onTap: () async {
            await state.deauthorize();
            if (context.mounted) {
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
                  onPressed: () => state.localization.translate("en"),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox.square(dimension: 20),
                IconButton(
                  icon: Image.asset("assets/flags/vi.png", height: 20, width: 20),
                  iconSize: 20,
                  onPressed: () => state.localization.translate("vi"),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Scaffold buildScaffold(BuildContext context);

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    final scaffold = buildScaffold(context);
    assert(scaffold.key == scaffoldKey);
    assert(scaffold.drawer != null);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          openDrawer();
        }
      },
      child: scaffold,
    );
  }
}
